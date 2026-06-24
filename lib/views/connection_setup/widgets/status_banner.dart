import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.adapterState, required this.isScanning, required this.isBusy});

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
            Text('Bluetooth ${adapterState.name.toUpperCase()}', style: Theme.of(context).textTheme.labelLarge),
            Chip(
              avatar: Icon(isScanning ? Icons.bluetooth_searching : Icons.bluetooth, size: 16, color: scheme.onPrimaryContainer),
              label: Text(isBusy ? 'Working' : (isScanning ? 'Scanning' : 'Idle')),
            ),
          ],
        ),
      ),
    );
  }
}