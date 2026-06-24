import 'package:flutter/material.dart';
import 'package:personal/models/connected_device_view_data.dart';
import 'package:personal/models/pull_test_record.dart';
import 'widgets/weight_chart.dart';

class ConnectedDevicePage extends StatelessWidget {
  const ConnectedDevicePage({
    super.key,
    required this.sessionListenable,
    required this.onResetChartScale,
    required this.testMode,
    required this.onStoreTest,
  });

  final ValueNotifier<ConnectedDeviceViewData> sessionListenable;
  final VoidCallback onResetChartScale;
  final bool testMode;
  final void Function(PullSide side, double maxKg) onStoreTest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Scale Stream'),
        actions: <Widget>[
          TextButton(
            onPressed: onResetChartScale,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('Reset'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _ConnectedDeviceBody(
        sessionListenable: sessionListenable,
        testMode: testMode,
        onStoreTest: onStoreTest,
      ),
    );
  }
}

class _ConnectedDeviceBody extends StatefulWidget {
  const _ConnectedDeviceBody({required this.sessionListenable, required this.testMode, required this.onStoreTest});

  final ValueNotifier<ConnectedDeviceViewData> sessionListenable;
  final bool testMode;
  final void Function(PullSide side, double maxKg) onStoreTest;

  @override
  State<_ConnectedDeviceBody> createState() => _ConnectedDeviceBodyState();
}

class _ConnectedDeviceBodyState extends State<_ConnectedDeviceBody> {
  PullSide _selectedSide = PullSide.left;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<ConnectedDeviceViewData>(
      valueListenable: widget.sessionListenable,
      builder: (BuildContext context, ConnectedDeviceViewData data, Widget? child) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(data.deviceName, style: Theme.of(context).textTheme.titleLarge),
                      if (data.deviceId != null) Text('ID: ${data.deviceId}'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: <Color>[scheme.primaryContainer, scheme.secondaryContainer]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          data.reading == null
                              ? 'Waiting for decodable packets...'
                              : 'Weight: ${data.reading!.weightKg.toStringAsFixed(2)} kg',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Max: ${data.overallMaxWeightKg.toStringAsFixed(2)} kg', style: Theme.of(context).textTheme.titleMedium),
                      if (widget.testMode) ...<Widget>[
                        const SizedBox(height: 12),
                        SegmentedButton<PullSide>(
                          segments: const <ButtonSegment<PullSide>>[
                            ButtonSegment<PullSide>(value: PullSide.left, label: Text('Left')),
                            ButtonSegment<PullSide>(value: PullSide.right, label: Text('Right')),
                          ],
                          selected: <PullSide>{_selectedSide},
                          onSelectionChanged: (Set<PullSide> selection) {
                            setState(() { _selectedSide = selection.first; });
                          },
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: data.overallMaxWeightKg <= 0
                              ? null
                              : () {
                                  widget.onStoreTest(_selectedSide, data.overallMaxWeightKg);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Stored ${_selectedSide.label} max: ${data.overallMaxWeightKg.toStringAsFixed(2)} kg')),
                                  );
                                },
                          child: const Text('Store'),
                        ),
                      ],
                      if (data.statusMessage != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(data.statusMessage!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: WeightChart(
                  readings: data.history,
                  streamStartedAt: data.streamStartedAt,
                  overallMaxWeightKg: data.overallMaxWeightKg,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}