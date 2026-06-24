import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/scale_reading.dart';
import 'scale_payload_service.dart';
import '../models/decoder_settings.dart';

class BleService {
  // Aumentamos a frequência para 20ms (50Hz) para máxima fluidez
  static const int updateIntervalMs = 20;

  Timer? _chartAggregationTimer;

  // Variáveis de acumulação (antes estavam na UI)
  double _activeWeightSumKg = 0;
  double _activeForceSumNewton = 0;
  int _activePacketCount = 0;
  DateTime? _streamStartedAt;
  int? _activeBucket;

  // Callback para avisar a UI que tem dado novo
  Function(ScaleReading)? onReadingProcessed;

  Future<void> connectAndConfigure(BluetoothDevice device) async {
    // 1. Conecta ao dispositivo
    await device.connect();

    // 2. Tenta aumentar a prioridade de conexão (Obrigatório para performance no Android)
    await device.requestConnectionPriority(
      connectionPriorityRequest: ConnectionPriority.high,
    );

    _streamStartedAt = DateTime.now();
  }

  void startProcessing(Function(ScaleReading) onProcessed) {
    onReadingProcessed = onProcessed;
    _chartAggregationTimer?.cancel();
    _chartAggregationTimer = Timer.periodic(
      const Duration(milliseconds: updateIntervalMs),
      (_) => _flushActiveBucket(),
    );
  }

  void handleIncomingPacket(ScanResult result, DecoderSettings settings) {
    final ScaleReading? reading = ScalePayloadDecoder.tryDecode(
      result,
      settings,
    );
    if (reading != null) {
      _recordReading(reading);
    }
  }

  void _recordReading(ScaleReading reading) {
    final DateTime startTime = _streamStartedAt ?? reading.timestamp;
    final int bucket =
        reading.timestamp.difference(startTime).inMilliseconds ~/
        updateIntervalMs;

    if (_activeBucket == null) {
      _activeBucket = bucket;
      _activeWeightSumKg = reading.weightKg;
      _activeForceSumNewton = reading.forceNewton;
      _activePacketCount = 1;
    } else if (bucket == _activeBucket) {
      _activeWeightSumKg += reading.weightKg;
      _activeForceSumNewton += reading.forceNewton;
      _activePacketCount += 1;
    } else {
      _flushActiveBucket(); // Finaliza o balde anterior
      _activeBucket = bucket;
      _activeWeightSumKg = reading.weightKg;
      _activeForceSumNewton = reading.forceNewton;
      _activePacketCount = 1;
    }
  }

  void _flushActiveBucket() {
    if (_activeBucket == null ||
        _activePacketCount == 0 ||
        onReadingProcessed == null) {
      return;
    }

    final ScaleReading averagedReading = ScaleReading(
      weightKg: _activeWeightSumKg / _activePacketCount,
      forceNewton: _activeForceSumNewton / _activePacketCount,
      source: 'avg',
      rawPayloadHex: '',
      timestamp: _streamStartedAt!.add(
        Duration(milliseconds: _activeBucket! * updateIntervalMs),
      ),
    );

    onReadingProcessed!(averagedReading);

    // Reseta
    _activeBucket = null;
    _activeWeightSumKg = 0;
    _activeForceSumNewton = 0;
    _activePacketCount = 0;
  }

  void dispose() {
    _chartAggregationTimer?.cancel();
  }
}
