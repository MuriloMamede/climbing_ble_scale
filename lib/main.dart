import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:personal/providers/app_session.dart';

import 'models/connected_device_view_data.dart';
import 'models/decoder_settings.dart';
import 'models/pull_test_record.dart';
import 'models/scale_reading.dart';
import 'services/scale_payload_service.dart';

const int att = 100;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BleScaleApp());
}

class BleScaleApp extends StatefulWidget {
  const BleScaleApp({super.key});

  @override
  State<BleScaleApp> createState() => _BleScaleAppState();
}

class _BleScaleAppState extends State<BleScaleApp> {
  final AppSession _session = AppSession();

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF2563EB),
      onPrimary: Colors.white,
      secondary: Color(0xFF14B8A6),
      onSecondary: Colors.white,
      tertiary: Color(0xFFF59E0B),
      onTertiary: Color(0xFF111827),
      error: Color(0xFFDC2626),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF0F172A),
      primaryContainer: Color(0xFFDBEAFE),
      onPrimaryContainer: Color(0xFF1E3A8A),
      secondaryContainer: Color(0xFFCCFBF1),
      onSecondaryContainer: Color(0xFF134E4A),
      tertiaryContainer: Color(0xFFFEF3C7),
      onTertiaryContainer: Color(0xFF78350F),
      outline: Color(0xFF94A3B8),
      outlineVariant: Color(0xFFCBD5E1),
      shadow: Color(0x1A0F172A),
      scrim: Color(0x660F172A),
      inverseSurface: Color(0xFF1E293B),
      onInverseSurface: Color(0xFFF8FAFC),
      inversePrimary: Color(0xFF93C5FD),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BLE Crane Scale',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: const Color(0xFFF1F5F9),
          foregroundColor: scheme.onSurface,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
          backgroundColor: scheme.primaryContainer,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: scheme.onPrimaryContainer,
          ),
          selectedColor: scheme.secondaryContainer,
        ),
      ),
      home: OverviewPage(session: _session),
    );
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.session});

  final AppSession session;

  String _formatTimestamp(DateTime? value) {
    if (value == null) {
      return '—';
    }
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year.toString().padLeft(4, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: session,
        builder: (BuildContext context, Widget? child) {
          final PullTestRecord? lastLeft = session.lastRecordFor(PullSide.left);
          final PullTestRecord? lastRight = session.lastRecordFor(
            PullSide.right,
          );

          return CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                title: const Text('Climbing BLE Scale'),
                floating: true,
                snap: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.bluetooth,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bluetooth: ${session.adapterState.name.toUpperCase()}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              session.connectedDeviceName == null
                                  ? 'Scale: not connected'
                                  : 'Scale: ${session.connectedDeviceName}',
                            ),
                            if (session.connectedDeviceId != null)
                              Text('ID: ${session.connectedDeviceId}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Recent Max Pull Test History',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                Chip(
                                  label: Text(
                                    'L ${lastLeft == null ? '—' : '${lastLeft.maxKg.toStringAsFixed(2)} kg'}',
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    'R ${lastRight == null ? '—' : '${lastRight.maxKg.toStringAsFixed(2)} kg'}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('L: ${_formatTimestamp(lastLeft?.timestamp)}'),
                            Text(
                              'R: ${_formatTimestamp(lastRight?.timestamp)}',
                            ),
                            const SizedBox(height: 12),
                            FilledButton.tonal(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) =>
                                        ConnectionSetupPage(
                                          session: session,
                                          startInTestMode: true,
                                        ),
                                  ),
                                );
                              },
                              child: const Text('Start New Test'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Progression',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: const <Widget>[
                                _LegendDot(label: 'Left', color: Colors.blue),
                                SizedBox(width: 16),
                                _LegendDot(label: 'Right', color: Colors.teal),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 220,
                              child: _ProgressionChart(
                                records: session.records,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Connection Setup',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            FilledButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) =>
                                        ConnectionSetupPage(session: session),
                                  ),
                                );
                              },
                              child: const Text('Open Scale Reader'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

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
  static const int _maxChartPoints = 50;

  final Map<DeviceIdentifier, ScanResult> _scanResults =
      <DeviceIdentifier, ScanResult>{};
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
    _connectedViewData = ValueNotifier<ConnectedDeviceViewData>(
      ConnectedDeviceViewData.empty(),
    );
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
      if (!mounted) {
        return;
      }
      setState(() {
        _adapterState = state;
      });
      widget.session.setAdapterState(state);
    });

    _isScanningSub = FlutterBluePlus.isScanning.listen((isScanning) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isScanning = isScanning;
      });
    });

    _scanResultsSub = FlutterBluePlus.scanResults.listen(
      _onScanResults,
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _decodeStatus = 'Scan error: $error';
        });
      },
    );
  }

  void _onScanResults(List<ScanResult> results) {
    if (!mounted) {
      return;
    }

    bool updatedSelection = false;

    setState(() {
      for (final ScanResult result in results) {
        _scanResults[result.device.remoteId] = result;
        if (result.device.remoteId == _selectedDeviceId) {
          _selectedPacketsSeen += 1;
          _selectedLastSeenAt = DateTime.now();
          _selectedPayloadSummaries = ScalePayloadDecoder.describePayloads(
            result,
          );

          final ScaleReading? reading = ScalePayloadDecoder.tryDecode(
            result,
            _decoderSettings,
          );
          if (reading != null) {
            _currentReading = reading;
            _recordReading(reading);
            _decodeStatus = null;
          } else if (_selectedPayloadSummaries.isEmpty) {
            _decodeStatus =
                'Packets received, but no manufacturer/service payload bytes found yet.';
          } else {
            _decodeStatus =
                'Connected, but no readable payload format found in latest packet.';
          }
          updatedSelection = true;
        }
      }
    });

    if (_selectedDeviceId != null && !updatedSelection) {
      setState(() {
        _decodeStatus = 'Listening for advertisements from selected device...';
      });
    }

    _publishConnectedViewData();
  }

  Future<void> _startScan() async {
    if (_isBusy) {
      return;
    }

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
      await FlutterBluePlus.startScan(
        androidUsesFineLocation: false,
        continuousUpdates: true,
      );
    } on Exception catch (error) {
      _decodeStatus = 'Could not start scan: $error';
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _stopScan() async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      await FlutterBluePlus.stopScan();
    } on Exception catch (error) {
      _decodeStatus = 'Could not stop scan: $error';
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
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
      _decodeStatus =
          'Connected to $selectedName. Listening for advertisement packets...';
    });
    widget.session.setConnectedDevice(
      name: selectedName,
      id: result.device.remoteId.toString(),
    );

    _chartAggregationTimer?.cancel();
    _chartAggregationTimer = Timer.periodic(
      const Duration(milliseconds: att),
      (_) => _flushCompletedBucket(),
    );

    if (!_isScanning) {
      await _startScan();
    }

    _publishConnectedViewData();
    if (!mounted) {
      return;
    }

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
    final int secondBucket =
        reading.timestamp.difference(startTime).inMilliseconds ~/ att;

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
    if (startTime == null || _activeSecondBucket == null) {
      return;
    }

    final int currentSecond =
        DateTime.now().difference(startTime).inMilliseconds ~/ att;
    if (currentSecond > _activeSecondBucket!) {
      _flushActiveBucket();
      _publishConnectedViewData();
    }
  }

  void _flushActiveBucket() {
    if (_activeSecondBucket == null || _activePacketCount == 0) {
      return;
    }

    final DateTime startTime = _streamStartedAt ?? DateTime.now();
    final ScaleReading averagedReading = ScaleReading(
      weightKg: _activeWeightSumKg / _activePacketCount,
      forceNewton: _activeForceSumNewton / _activePacketCount,
      source: '1s average',
      rawPayloadHex: 'avg($_activePacketCount packets)',
      timestamp: startTime.add(Duration(seconds: _activeSecondBucket!)),
    );

    _readingHistory.add(averagedReading);
    _overallMaxWeightKg = _overallMaxWeightKg > averagedReading.weightKg
        ? _overallMaxWeightKg
        : averagedReading.weightKg;

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
    final ScanResult? selectedResult = _selectedDeviceId == null
        ? null
        : _scanResults[_selectedDeviceId];

    _connectedViewData.value = ConnectedDeviceViewData(
      deviceName: selectedResult == null
          ? 'No connected device'
          : _displayName(selectedResult),
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
    if (advertisedName.isNotEmpty) {
      return advertisedName;
    }
    final String platformName = result.device.platformName.trim();
    if (platformName.isNotEmpty) {
      return platformName;
    }
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
            _StatusBanner(
              adapterState: _adapterState,
              isScanning: _isScanning,
              isBusy: _isBusy,
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _startScan,
                    child: const Text('Scan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_isBusy || !_isScanning) ? null : _stopScan,
                    child: const Text('Stop'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (BuildContext context, int index) {
                  final ScanResult result = devices[index];
                  final bool isSelected =
                      result.device.remoteId == _selectedDeviceId;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.monitor_weight_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
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
            _ReadingPanel(
              selectedResult: _selectedDeviceId == null
                  ? null
                  : _scanResults[_selectedDeviceId],
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.adapterState,
    required this.isScanning,
    required this.isBusy,
  });

  final BluetoothAdapterState adapterState;
  final bool isScanning;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Bluetooth ${adapterState.name.toUpperCase()}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Chip(
              avatar: Icon(
                isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                size: 16,
                color: scheme.onPrimaryContainer,
              ),
              label: Text(
                isBusy ? 'Working' : (isScanning ? 'Scanning' : 'Idle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingPanel extends StatelessWidget {
  const _ReadingPanel({
    required this.selectedResult,
    required this.reading,
    required this.statusMessage,
    required this.packetsSeen,
    required this.lastSeenAt,
    required this.payloadSummaries,
  });

  final ScanResult? selectedResult;
  final ScaleReading? reading;
  final String? statusMessage;
  final int packetsSeen;
  final DateTime? lastSeenAt;
  final List<String> payloadSummaries;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              selectedResult == null ? 'No device selected' : 'Connected',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(selectedResult?.device.remoteId.toString() ?? '—'),
            const SizedBox(height: 8),
            if (reading != null) ...<Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Weight: ${reading!.weightKg.toStringAsFixed(2)} kg',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ] else ...<Widget>[const Text('Waiting for decodable packets...')],
            if (statusMessage != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                statusMessage!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ConnectedDevicePage extends StatelessWidget {
  const ConnectedDevicePage({
    super.key,
    required this.sessionListenable,
    required this.onResetChartScale,
    required this.testMode,
    required this.onStoreTest,
  });

  final ValueNotifier<ConnectedDeviceViewData> sessionListenable;
  final VoidCallback onResetChartScale;
  final bool testMode;
  final void Function(PullSide side, double maxKg) onStoreTest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Scale Stream'),
        actions: <Widget>[
          TextButton(
            onPressed: onResetChartScale,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Reset'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _ConnectedDeviceBody(
        sessionListenable: sessionListenable,
        testMode: testMode,
        onStoreTest: onStoreTest,
      ),
    );
  }
}

class _ConnectedDeviceBody extends StatefulWidget {
  const _ConnectedDeviceBody({
    required this.sessionListenable,
    required this.testMode,
    required this.onStoreTest,
  });

  final ValueNotifier<ConnectedDeviceViewData> sessionListenable;
  final bool testMode;
  final void Function(PullSide side, double maxKg) onStoreTest;

  @override
  State<_ConnectedDeviceBody> createState() => _ConnectedDeviceBodyState();
}

class _ConnectedDeviceBodyState extends State<_ConnectedDeviceBody> {
  PullSide _selectedSide = PullSide.left;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<ConnectedDeviceViewData>(
      valueListenable: widget.sessionListenable,
      builder: (BuildContext context, ConnectedDeviceViewData data, Widget? child) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        data.deviceName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (data.deviceId != null) Text('ID: ${data.deviceId}'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              scheme.primaryContainer,
                              scheme.secondaryContainer,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          data.reading == null
                              ? 'Waiting for decodable packets...'
                              : 'Weight: ${data.reading!.weightKg.toStringAsFixed(2)} kg',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Max: ${data.overallMaxWeightKg.toStringAsFixed(2)} kg',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (widget.testMode) ...<Widget>[
                        const SizedBox(height: 12),
                        SegmentedButton<PullSide>(
                          segments: const <ButtonSegment<PullSide>>[
                            ButtonSegment<PullSide>(
                              value: PullSide.left,
                              label: Text('Left'),
                            ),
                            ButtonSegment<PullSide>(
                              value: PullSide.right,
                              label: Text('Right'),
                            ),
                          ],
                          selected: <PullSide>{_selectedSide},
                          onSelectionChanged: (Set<PullSide> selection) {
                            setState(() {
                              _selectedSide = selection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: data.overallMaxWeightKg <= 0
                              ? null
                              : () {
                                  widget.onStoreTest(
                                    _selectedSide,
                                    data.overallMaxWeightKg,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Stored ${_selectedSide.label} max: ${data.overallMaxWeightKg.toStringAsFixed(2)} kg',
                                      ),
                                    ),
                                  );
                                },
                          child: const Text('Store'),
                        ),
                      ],
                      if (data.statusMessage != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(data.statusMessage!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _WeightChart(
                  readings: data.history,
                  streamStartedAt: data.streamStartedAt,
                  overallMaxWeightKg: data.overallMaxWeightKg,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({
    required this.readings,
    required this.streamStartedAt,
    required this.overallMaxWeightKg,
  });

  final List<ScaleReading> readings;
  final DateTime? streamStartedAt;
  final double overallMaxWeightKg;

  @override
  Widget build(BuildContext context) {
    final DateTime? startTime = streamStartedAt;
    final List<double> xValues = <double>[];
    final List<double> yValues = <double>[];

    for (final ScaleReading reading in readings) {
      final double seconds = startTime == null
          ? 0
          : reading.timestamp.difference(startTime).inMilliseconds / att;
      xValues.add(seconds);
      yValues.add(reading.weightKg);
    }

    final List<FlSpot> spots = <FlSpot>[
      for (int index = 0; index < xValues.length; index++)
        FlSpot(xValues[index], yValues[index]),
    ];

    final double minX = xValues.isEmpty ? 0 : xValues.first;
    final double maxX = xValues.length < 2
        ? minX + 1
        : (xValues.last == minX ? minX + 1 : xValues.last);
    final double maxY = overallMaxWeightKg <= 0 ? 1 : overallMaxWeightKg * 1.1;

    if (spots.length < 2) {
      return const Center(child: Text('Waiting for more samples...'));
    }

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          verticalInterval: ((maxX - minX) / 4).clamp(1, double.infinity),
        ),
        borderData: FlBorderData(
          show: false,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Time (s)'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: ((maxX - minX) / 4).clamp(1, double.infinity),
              getTitlesWidget: (double value, TitleMeta meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(value.toStringAsFixed(0)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Weight (kg)'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              interval: (maxY / 4).clamp(0.5, double.infinity),
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(value.toStringAsFixed(1));
              },
            ),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _ProgressionChart extends StatelessWidget {
  const _ProgressionChart({required this.records});

  final List<PullTestRecord> records;

  String _formatAxisDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final List<PullTestRecord> sorted = List<PullTestRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sorted.isEmpty) {
      return const Center(child: Text('Add tests to see progression'));
    }

    final int minMillis = sorted.first.timestamp.millisecondsSinceEpoch;
    final int maxMillis = sorted.last.timestamp.millisecondsSinceEpoch;

    final List<FlSpot> leftSpots = <FlSpot>[];
    final List<FlSpot> rightSpots = <FlSpot>[];

    for (final PullTestRecord record in sorted) {
      final double secondsFromStart =
          (record.timestamp.millisecondsSinceEpoch - minMillis) / att;
      final FlSpot spot = FlSpot(secondsFromStart, record.maxKg);
      if (record.side == PullSide.left) {
        leftSpots.add(spot);
      } else {
        rightSpots.add(spot);
      }
    }

    if (leftSpots.length + rightSpots.length < 2) {
      return const Center(child: Text('Add more tests to see progression'));
    }

    double maxKg = 1;
    for (final PullTestRecord record in sorted) {
      if (record.maxKg > maxKg) {
        maxKg = record.maxKg;
      }
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxMillis == minMillis ? 1 : (maxMillis - minMillis) / att,
        minY: 0,
        maxY: maxKg * 1.1,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(
          show: false,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Date'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: ((maxMillis - minMillis) / att / 2).clamp(
                1,
                double.infinity,
              ),
              getTitlesWidget: (double value, TitleMeta meta) {
                final DateTime time = DateTime.fromMillisecondsSinceEpoch(
                  minMillis + (value * att).round(),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatAxisDate(time),
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Max (kg)'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: (maxKg * 1.1 / 4).clamp(0.5, double.infinity),
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(value.toStringAsFixed(1));
              },
            ),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: leftSpots,
            color: Colors.blue,
            isCurved: false,
            barWidth: 2,
            dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            spots: rightSpots,
            color: Colors.teal,
            isCurved: false,
            barWidth: 2,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}
