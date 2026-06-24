import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:personal/models/scale_reading.dart';

class ReadingPanel extends StatelessWidget {
  const ReadingPanel({
    super.key,
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
            Text(selectedResult == null ? 'No device selected' : 'Connected', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(selectedResult?.device.remoteId.toString() ?? '—'),
            const SizedBox(height: 8),
            if (reading != null) ...<Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
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
              Text(statusMessage!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}