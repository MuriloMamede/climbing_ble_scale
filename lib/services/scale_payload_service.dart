import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/decoder_settings.dart';
import '../models/scale_reading.dart';

class _PayloadSource {
  const _PayloadSource(this.source, this.bytes);

  final String source;
  final List<int> bytes;
}

class ScalePayloadDecoder {
  static const int _whc06ManufacturerId = 0x0100;
  static const int _whc06WeightOffset = 10;

  static ScaleReading? tryDecode(ScanResult result, DecoderSettings settings) {
    final List<int>? whc06Payload =
        result.advertisementData.manufacturerData[_whc06ManufacturerId];
    final double? whc06Kg = _decodeWhc06WeightKg(whc06Payload);
    if (whc06Kg != null) {
      return ScaleReading(
        weightKg: whc06Kg,
        forceNewton: whc06Kg * 9.80665,
        source: 'manufacturer 0x0100 (WH-C06)',
        rawPayloadHex: _toHex(whc06Payload!),
        timestamp: DateTime.now(),
      );
    }

    final List<_PayloadSource> payloads = _collectPayloads(result);

    for (final _PayloadSource payload in payloads) {
      final double? kg = _decodeWeightKg(payload.bytes, settings);
      if (kg == null) {
        continue;
      }
      return ScaleReading(
        weightKg: kg,
        forceNewton: kg * 9.80665,
        source: payload.source,
        rawPayloadHex: _toHex(payload.bytes),
        timestamp: DateTime.now(),
      );
    }

    for (final _PayloadSource payload in payloads) {
      final double? kg = _decodeAsciiWeightKg(payload.bytes);
      if (kg == null) {
        continue;
      }
      return ScaleReading(
        weightKg: kg,
        forceNewton: kg * 9.80665,
        source: '${payload.source} (ascii)',
        rawPayloadHex: _toHex(payload.bytes),
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  static List<String> describePayloads(ScanResult result) {
    final List<_PayloadSource> payloads = _collectPayloads(result);
    final List<int>? whc06Payload =
        result.advertisementData.manufacturerData[_whc06ManufacturerId];

    final List<String> rows = <String>[];
    if (whc06Payload != null) {
      rows.add(
        'WH-C06 payload (0x0100): ${whc06Payload.length} bytes → ${_toHex(whc06Payload)}',
      );
    }

    rows.addAll(
      payloads.map(
        (payload) =>
            '${payload.source}: ${payload.bytes.length} bytes → ${_toHex(payload.bytes)}',
      ),
    );

    return rows.toList(growable: false);
  }

  static List<_PayloadSource> _collectPayloads(ScanResult result) {
    final List<_PayloadSource> payloads = <_PayloadSource>[];

    result.advertisementData.manufacturerData.forEach((
      int id,
      List<int> bytes,
    ) {
      if (bytes.isNotEmpty) {
        payloads.add(
          _PayloadSource('manufacturer 0x${id.toRadixString(16)}', bytes),
        );
      }
    });

    result.advertisementData.serviceData.forEach((Guid uuid, List<int> bytes) {
      if (bytes.isNotEmpty) {
        payloads.add(_PayloadSource('service $uuid', bytes));
      }
    });

    return payloads;
  }

  static double? _decodeWeightKg(List<int> bytes, DecoderSettings settings) {
    if (bytes.length < (settings.offset + settings.lengthBytes)) {
      return null;
    }

    final List<int> rawSlice = bytes.sublist(
      settings.offset,
      settings.offset + settings.lengthBytes,
    );

    int rawValue = 0;
    if (settings.endian == Endian.little) {
      for (int index = 0; index < rawSlice.length; index++) {
        rawValue |= rawSlice[index] << (8 * index);
      }
    } else {
      for (final int byte in rawSlice) {
        rawValue = (rawValue << 8) | byte;
      }
    }

    if (settings.signed) {
      final int bitWidth = settings.lengthBytes * 8;
      final int signMask = 1 << (bitWidth - 1);
      if ((rawValue & signMask) != 0) {
        rawValue -= 1 << bitWidth;
      }
    }

    final double kg = rawValue * settings.scale;

    if (kg.abs() > 100000) {
      return null;
    }

    return kg;
  }

  static double? _decodeWhc06WeightKg(List<int>? bytes) {
    if (bytes == null || bytes.length <= (_whc06WeightOffset + 1)) {
      return null;
    }

    final int rawWeight =
        (bytes[_whc06WeightOffset] << 8) | bytes[_whc06WeightOffset + 1];
    final double kg = rawWeight / 100.0;

    if (kg.abs() > 100000) {
      return null;
    }

    return kg;
  }

  static double? _decodeAsciiWeightKg(List<int> bytes) {
    final String ascii = String.fromCharCodes(
      bytes.where((int byte) => byte >= 32 && byte <= 126),
    );
    if (ascii.isEmpty) {
      return null;
    }

    final RegExpMatch? match = RegExp(r'[-+]?\d+(?:\.\d+)?').firstMatch(ascii);
    if (match == null) {
      return null;
    }

    final double? parsed = double.tryParse(match.group(0)!);
    if (parsed == null) {
      return null;
    }

    final String normalized = ascii.toLowerCase();
    if (normalized.contains('lb')) {
      return parsed * 0.45359237;
    }
    if (normalized.contains('kg')) {
      return parsed;
    }

    return parsed;
  }

  static String _toHex(List<int> bytes) {
    return bytes
        .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(' ')
        .toUpperCase();
  }
}
