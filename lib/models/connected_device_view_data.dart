import 'package:personal/models/scale_reading.dart';

class ConnectedDeviceViewData {
  const ConnectedDeviceViewData({
    required this.deviceName,
    required this.deviceId,
    required this.reading,
    required this.history,
    required this.statusMessage,
    required this.packetsSeen,
    required this.lastSeenAt,
    required this.payloadSummaries,
    required this.streamStartedAt,
    required this.overallMaxWeightKg,
  });

  final String deviceName;
  final String? deviceId;
  final ScaleReading? reading;
  final List<ScaleReading> history;
  final String? statusMessage;
  final int packetsSeen;
  final DateTime? lastSeenAt;
  final List<String> payloadSummaries;
  final DateTime? streamStartedAt;
  final double overallMaxWeightKg;

  factory ConnectedDeviceViewData.empty() {
    return const ConnectedDeviceViewData(
      deviceName: 'No connected device',
      deviceId: null,
      reading: null,
      history: <ScaleReading>[],
      statusMessage: null,
      packetsSeen: 0,
      lastSeenAt: null,
      payloadSummaries: <String>[],
      streamStartedAt: null,
      overallMaxWeightKg: 0,
    );
  }
}
