import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pull_test_record.dart';

class AppSession extends ChangeNotifier {
  static const String _recordsStorageKey = 'pull_test_records_v1';

  BluetoothAdapterState adapterState = BluetoothAdapterState.unknown;
  String? connectedDeviceName;
  String? connectedDeviceId;
  final List<PullTestRecord> _records = <PullTestRecord>[];

  AppSession() {
    _loadRecords();
  }

  List<PullTestRecord> get records =>
      List<PullTestRecord>.unmodifiable(_records);

  void setAdapterState(BluetoothAdapterState value) {
    if (adapterState == value) {
      return;
    }
    adapterState = value;
    notifyListeners();
  }

  void setConnectedDevice({required String name, required String id}) {
    connectedDeviceName = name;
    connectedDeviceId = id;
    notifyListeners();
  }

  void storeTest({required PullSide side, required double maxKg}) {
    _records.insert(
      0,
      PullTestRecord(side: side, maxKg: maxKg, timestamp: DateTime.now()),
    );
    if (_records.length > 20) {
      _records.removeRange(20, _records.length);
    }
    _saveRecords();
    notifyListeners();
  }

  PullTestRecord? lastRecordFor(PullSide side) {
    for (final PullTestRecord record in _records) {
      if (record.side == side) {
        return record;
      }
    }
    return null;
  }

  Future<void> _loadRecords() async {
    String? payload;
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      payload = preferences.getString(_recordsStorageKey);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }

    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(payload) as List<dynamic>;
      final List<PullTestRecord> loaded = decoded
          .whereType<Map<String, dynamic>>()
          .map(PullTestRecord.fromJson)
          .toList();
      loaded.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _records
        ..clear()
        ..addAll(loaded);
      notifyListeners();
    } on FormatException {
      _records.clear();
    }
  }

  Future<void> _saveRecords() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final String payload = jsonEncode(
        _records.map((PullTestRecord record) => record.toJson()).toList(),
      );
      await preferences.setString(_recordsStorageKey, payload);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}