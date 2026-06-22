class ScaleReading {
  const ScaleReading({
    required this.weightKg,
    required this.forceNewton,
    required this.source,
    required this.rawPayloadHex,
    required this.timestamp,
  });

  final double weightKg;
  final double forceNewton;
  final String source;
  final String rawPayloadHex;
  final DateTime timestamp;
}