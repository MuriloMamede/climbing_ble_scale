import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:personal/models/pull_test_record.dart';

class ProgressionChart extends StatelessWidget {
  const ProgressionChart({super.key, required this.records});

  final List<PullTestRecord> records;
  static const int att = 100;

  String _formatAxisDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final List<PullTestRecord> sorted = List<PullTestRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sorted.isEmpty) {
      return const Center(child: Text('Add tests to see progression'));
    }

    final int minMillis = sorted.first.timestamp.millisecondsSinceEpoch;
    final int maxMillis = sorted.last.timestamp.millisecondsSinceEpoch;

    final List<FlSpot> leftSpots = <FlSpot>[];
    final List<FlSpot> rightSpots = <FlSpot>[];

    for (final PullTestRecord record in sorted) {
      final double secondsFromStart = (record.timestamp.millisecondsSinceEpoch - minMillis) / att;
      final FlSpot spot = FlSpot(secondsFromStart, record.maxKg);
      if (record.side == PullSide.left) {
        leftSpots.add(spot);
      } else {
        rightSpots.add(spot);
      }
    }

    if (leftSpots.length + rightSpots.length < 2) {
      return const Center(child: Text('Add more tests to see progression'));
    }

    double maxKg = 1;
    for (final PullTestRecord record in sorted) {
      if (record.maxKg > maxKg) {
        maxKg = record.maxKg;
      }
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxMillis == minMillis ? 1 : (maxMillis - minMillis) / att,
        minY: 0,
        maxY: maxKg * 1.1,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(
          show: false,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Date'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: ((maxMillis - minMillis) / att / 2).clamp(1, double.infinity),
              getTitlesWidget: (double value, TitleMeta meta) {
                final DateTime time = DateTime.fromMillisecondsSinceEpoch(
                  minMillis + (value * att).round(),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatAxisDate(time),
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Max (kg)'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: (maxKg * 1.1 / 4).clamp(0.5, double.infinity),
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(value.toStringAsFixed(1));
              },
            ),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: leftSpots,
            color: Colors.blue,
            isCurved: false,
            barWidth: 2,
            dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            spots: rightSpots,
            color: Colors.teal,
            isCurved: false,
            barWidth: 2,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}