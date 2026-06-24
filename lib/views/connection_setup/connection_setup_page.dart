import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:personal/models/connected_device_view_data.dart';
import 'package:personal/models/decoder_settings.dart';
import 'package:personal/models/pull_test_record.dart';
import 'package:personal/models/scale_reading.dart';
import 'package:personal/providers/app_session.dart';
import 'package:personal/services/scale_payload_service.dart';
import 'connected_device_page.dart';
import 'widgets/reading_panel.dart';
import 'widgets/status_banner.dart';


class ConnectionSetupPage extends StatefulWidget {
  const ConnectionSetupPage({
    super.key,
    required this.session,
    this.startInTestMode = false,
  });

  final AppSession session;
  final bool startInTestMode;

  @override
  State<ConnectionSetupPage> createState() => _ConnectionSetupPageState();
}

class _ConnectionSetupPageState extends State<ConnectionSetupPage> {
  static const int att = 100;
  static const int _maxChartPoints = 50;

  final Map<DeviceIdentifier, ScanResult> _scanResults = <DeviceIdentifier, ScanResult>{};
  final List<ScaleReading> _readingHistory = <ScaleReading>[];
  late final ValueNotifier<ConnectedDeviceViewData> _connectedViewData;
  final DecoderSettings _decoderSettings = DecoderSettings.defaults();

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  DeviceIdentifier? _selectedDeviceId;
  ScaleReading? _currentReading;
  String? _decodeStatus;
  int _selectedPacketsSeen = 0;
  DateTime? _selectedLastSeenAt;
  List<String> _selectedPayloadSummaries = <String>[];

  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
  StreamSubscription<List<ScanResult>>? _scanResultsSub;
  StreamSubscription<bool>? _isScanningSub;

  bool _isScanning = false;
  bool _isBusy = false;
  DateTime? _streamStartedAt;
  double _overallMaxWeightKg = 1;
  Timer? _chartAggregationTimer;
  int? _activeSecondBucket;
  double _activeWeightSumKg = 0;
  double _activeForceSumNewton = 0;
  int _activePacketCount = 0;

  @override
  void initState() {
    super.initState();
    _connectedViewData = ValueNotifier<ConnectedDeviceViewData>(ConnectedDeviceViewData.empty());
    _initializeBle();
  }

  @override
  void dispose() {
    _chartAggregationTimer?.cancel();
    _connectedViewData.dispose();
    _adapterStateSub?.cancel();
    _scanResultsSub?.cancel();
    _isScanningSub?.cancel();
    super.dispose();
  }

  Future<void> _initializeBle() async {
    _adapterStateSub = FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) return;
      setState(() { _adapterState = state; });
      widget.session.setAdapterState(state);
    });

    _isScanningSub = FlutterBluePlus.isScanning.listen((isScanning) {
      if (!mounted) return;
      setState(() { _isScanning = isScanning; });
    });

    _scanResultsSub = FlutterBluePlus.scanResults.listen(
      _onScanResults,
      onError: (Object error) {
        if (!mounted) return;
        setState(() { _decodeStatus = 'Scan error: $error'; });
      },
    );
  }

  void _onScanResults(List<ScanResult> results) {
    if (!mounted) return;
    bool updatedSelection = false;

    setState(() {
      for (final ScanResult result in results) {
        _scanResults[result.device.remoteId] = result;
        if (result.device.remoteId == _selectedDeviceId) {
          _selectedPacketsSeen += 1;
          _selectedLastSeenAt = DateTime.now();
          _selectedPayloadSummaries = ScalePayloadDecoder.describePayloads(result);

          final ScaleReading? reading = ScalePayloadDecoder.tryDecode(result, _decoderSettings);
          if (reading != null) {
            _currentReading = reading;
            _recordReading(reading);
            _decodeStatus = null;
          } else if (_selectedPayloadSummaries.isEmpty) {
            _decodeStatus = 'Packets received, but no manufacturer/service payload bytes found yet.';
          } else {
            _decodeStatus = 'Connected, but no readable payload format found in latest packet.';
          }
          updatedSelection = true;
        }
      }
    });

    if (_selectedDeviceId != null && !updatedSelection) {
      setState(() { _decodeStatus = 'Listening for advertisements from selected device...'; });
    }

    _publishConnectedViewData();
  }

  Future<void> _startScan() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _decodeStatus = null;
    });

    try {
      if (_adapterState != BluetoothAdapterState.on) {
        _decodeStatus = 'Bluetooth is not ON. Enable it and scan again.';
        return;
      }
      _scanResults.clear();
      await FlutterBluePlus.startScan(androidUsesFineLocation: false, continuousUpdates: true);
    } on Exception catch (error) {
      _decodeStatus = 'Could not start scan: $error';
    } finally {
      if (mounted) setState(() { _isBusy = false; });
    }
  }

  Future<void> _stopScan() async {
    if (_isBusy) return;
    setState(() { _isBusy = true; });
    try {
      await FlutterBluePlus.stopScan();
    } on Exception catch (error) {
      _decodeStatus = 'Could not stop scan: $error';
    } finally {
      if (mounted) setState(() { _isBusy = false; });
    }
  }

  Future<void> _selectDevice(ScanResult result) async {
    final String selectedName = _displayName(result);
    setState(() {
      _selectedDeviceId = result.device.remoteId;
      _currentReading = null;
      _readingHistory.clear();
      _streamStartedAt = DateTime.now();
      _overallMaxWeightKg = 1;
      _activeSecondBucket = null;
      _activeWeightSumKg = 0;
      _activeForceSumNewton = 0;
      _activePacketCount = 0;
      _selectedPacketsSeen = 0;
      _selectedLastSeenAt = null;
      _selectedPayloadSummaries = <String>[];
      _decodeStatus = 'Connected to $selectedName. Listening for advertisement packets...';
    });
    widget.session.setConnectedDevice(name: selectedName, id: result.device.remoteId.toString());

    _chartAggregationTimer?.cancel();
    _chartAggregationTimer = Timer.periodic(const Duration(milliseconds: att), (_) => _flushCompletedBucket());

    if (!_isScanning) await _startScan();

    _publishConnectedViewData();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ConnectedDevicePage(
          sessionListenable: _connectedViewData,
          onResetChartScale: _resetChartScale,
          testMode: widget.startInTestMode,
          onStoreTest: (PullSide side, double maxKg) {
            widget.session.storeTest(side: side, maxKg: maxKg);
          },
        ),
      ),
    );
  }

  void _recordReading(ScaleReading reading) {
    final DateTime startTime = _streamStartedAt ?? reading.timestamp;
    _streamStartedAt ??= startTime;
    final int secondBucket = reading.timestamp.difference(startTime).inMilliseconds ~/ att;

    if (_activeSecondBucket == null) {
      _activeSecondBucket = secondBucket;
      _activeWeightSumKg = reading.weightKg;
      _activeForceSumNewton = reading.forceNewton;
      _activePacketCount = 1;
      return;
    }

    if (secondBucket == _activeSecondBucket) {
      _activeWeightSumKg += reading.weightKg;
      _activeForceSumNewton += reading.forceNewton;
      _activePacketCount += 1;
      return;
    }

    if (secondBucket > _activeSecondBucket!) {
      _flushActiveBucket();
      _activeSecondBucket = secondBucket;
      _activeWeightSumKg = reading.weightKg;
      _activeForceSumNewton = reading.forceNewton;
      _activePacketCount = 1;
    }
  }

  void _flushCompletedBucket() {
    final DateTime? startTime = _streamStartedAt;
    if (startTime == null || _activeSecondBucket == null) return;

    final int currentSecond = DateTime.now().difference(startTime).inMilliseconds ~/ att;
    if (currentSecond > _activeSecondBucket!) {
      _flushActiveBucket();
      _publishConnectedViewData();
    }
  }

  void _flushActiveBucket() {
    if (_activeSecondBucket == null || _activePacketCount == 0) return;

    final DateTime startTime = _streamStartedAt ?? DateTime.now();
    final ScaleReading averagedReading = ScaleReading(
      weightKg: _activeWeightSumKg / _activePacketCount,
      forceNewton: _activeForceSumNewton / _activePacketCount,
      source: '1s average',
      rawPayloadHex: 'avg($_activePacketCount packets)',
      timestamp: startTime.add(Duration(seconds: _activeSecondBucket!)),
    );

    _readingHistory.add(averagedReading);
    _overallMaxWeightKg = _overallMaxWeightKg > averagedReading.weightKg ? _overallMaxWeightKg : averagedReading.weightKg;

    if (_readingHistory.length > _maxChartPoints) {
      _readingHistory.removeRange(0, _readingHistory.length - _maxChartPoints);
    }

    _activeSecondBucket = null;
    _activeWeightSumKg = 0;
    _activeForceSumNewton = 0;
    _activePacketCount = 0;
  }

  void _resetChartScale() {
    setState(() {
      _overallMaxWeightKg = 1;
      _readingHistory.clear();
      _activeSecondBucket = null;
      _activeWeightSumKg = 0;
      _activeForceSumNewton = 0;
      _activePacketCount = 0;
      _streamStartedAt = DateTime.now();
    });
    _publishConnectedViewData();
  }

  void _publishConnectedViewData() {
    final ScanResult? selectedResult = _selectedDeviceId == null ? null : _scanResults[_selectedDeviceId];
    _connectedViewData.value = ConnectedDeviceViewData(
      deviceName: selectedResult == null ? 'No connected device' : _displayName(selectedResult),
      deviceId: selectedResult?.device.remoteId.toString(),
      reading: _currentReading,
      history: List<ScaleReading>.unmodifiable(_readingHistory),
      statusMessage: _decodeStatus,
      packetsSeen: _selectedPacketsSeen,
      lastSeenAt: _selectedLastSeenAt,
      payloadSummaries: List<String>.unmodifiable(_selectedPayloadSummaries),
      streamStartedAt: _streamStartedAt,
      overallMaxWeightKg: _overallMaxWeightKg,
    );
  }

  List<ScanResult> _sortedResults() {
    final List<ScanResult> list = _scanResults.values.toList();
    list.sort((a, b) => b.rssi.compareTo(a.rssi));
    return list;
  }

  String _displayName(ScanResult result) {
    final String advertisedName = result.advertisementData.advName.trim();
    if (advertisedName.isNotEmpty) return advertisedName;
    final String platformName = result.device.platformName.trim();
    if (platformName.isNotEmpty) return platformName;
    return 'Unknown Device';
  }

  @override
  Widget build(BuildContext context) {
    final List<ScanResult> devices = _sortedResults();

    return Scaffold(
      appBar: AppBar(title: const Text('Connection Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StatusBanner(adapterState: _adapterState, isScanning: _isScanning, isBusy: _isBusy),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(child: ElevatedButton(onPressed: _isBusy ? null : _startScan, child: const Text('Scan'))),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton(onPressed: (_isBusy || !_isScanning) ? null : _stopScan, child: const Text('Stop'))),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (BuildContext context, int index) {
                  final ScanResult result = devices[index];
                  final bool isSelected = result.device.remoteId == _selectedDeviceId;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                        child: Icon(Icons.monitor_weight_outlined, color: Theme.of(context).colorScheme.onSecondaryContainer),
                      ),
                      title: Text(_displayName(result)),
                      subtitle: Text('RSSI ${result.rssi} dBm'),
                      trailing: SizedBox(
                        width: 92,
                        height: 36,
                        child: FilledButton.tonal(
                          onPressed: () => _selectDevice(result),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(isSelected ? 'Open' : 'Connect'),
                        ),
                      ),
                      selected: isSelected,
                      onTap: () => _selectDevice(result),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ReadingPanel(
              selectedResult: _selectedDeviceId == null ? null : _scanResults[_selectedDeviceId],
              reading: _currentReading,
              statusMessage: _decodeStatus,
              packetsSeen: _selectedPacketsSeen,
              lastSeenAt: _selectedLastSeenAt,
              payloadSummaries: _selectedPayloadSummaries,
            ),
          ],
        ),
      ),
    );
  }
}