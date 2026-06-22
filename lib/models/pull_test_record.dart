enum PullSide { left, right }

extension PullSideLabel on PullSide {
  String get label => this == PullSide.left ? 'Left' : 'Right';
}

class PullTestRecord {
  const PullTestRecord({
    required this.side,
    required this.maxKg,
    required this.timestamp,
  });

  final PullSide side;
  final double maxKg;
  final DateTime timestamp;

  Map<String, Object> toJson() {
    return <String, Object>{
      'side': side.name,
      'maxKg': maxKg,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PullTestRecord.fromJson(Map<String, dynamic> json) {
    final String sideRaw = (json['side'] ?? '').toString();
    final PullSide side = sideRaw == PullSide.right.name
        ? PullSide.right
        : PullSide.left;
    final double maxKg = (json['maxKg'] is num)
        ? (json['maxKg'] as num).toDouble()
        : 0;
    final DateTime timestamp =
        DateTime.tryParse((json['timestamp'] ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return PullTestRecord(side: side, maxKg: maxKg, timestamp: timestamp);
  }
}