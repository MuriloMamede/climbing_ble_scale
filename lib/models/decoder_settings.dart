import 'dart:typed_data';

class DecoderSettings {
  const DecoderSettings({
    required this.offset,
    required this.lengthBytes,
    required this.scale,
    required this.endian,
    required this.signed,
  });

  final int offset;
  final int lengthBytes;
  final double scale;
  final Endian endian;
  final bool signed;

  factory DecoderSettings.defaults() {
    return const DecoderSettings(
      offset: 10,
      lengthBytes: 2,
      scale: 0.01,
      endian: Endian.big,
      signed: false,
    );
  }

  DecoderSettings copyWith({
    int? offset,
    int? lengthBytes,
    double? scale,
    Endian? endian,
    bool? signed,
  }) {
    return DecoderSettings(
      offset: offset ?? this.offset,
      lengthBytes: lengthBytes ?? this.lengthBytes,
      scale: scale ?? this.scale,
      endian: endian ?? this.endian,
      signed: signed ?? this.signed,
    );
  }
}