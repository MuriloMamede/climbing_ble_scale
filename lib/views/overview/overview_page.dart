import 'package:flutter/material.dart';
import 'package:personal/models/pull_test_record.dart';
import 'package:personal/providers/app_session.dart';
import '../connection_setup/connection_setup_page.dart';
import 'widgets/legend_dot.dart';
import 'widgets/progression_chart.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.session});

  final AppSession session;

  String _formatTimestamp(DateTime? value) {
    if (value == null) return '—';
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year.toString().padLeft(4, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: session,
        builder: (BuildContext context, Widget? child) {
          final PullTestRecord? lastLeft = session.lastRecordFor(PullSide.left);
          final PullTestRecord? lastRight = session.lastRecordFor(PullSide.right);

          return CustomScrollView(
            slivers: <Widget>[
              const SliverAppBar(
                title: Text('Climbing BLE Scale'),
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
                                  style: Theme.of(context).textTheme.titleMedium,
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
                            Text('R: ${_formatTimestamp(lastRight?.timestamp)}'),
                            const SizedBox(height: 12),
                            FilledButton.tonal(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) => ConnectionSetupPage(
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
                            const Row(
                              children: <Widget>[
                                LegendDot(label: 'Left', color: Colors.blue),
                                SizedBox(width: 16),
                                LegendDot(label: 'Right', color: Colors.teal),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 220,
                              child: ProgressionChart(records: session.records),
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
                                    builder: (BuildContext context) => ConnectionSetupPage(session: session),
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