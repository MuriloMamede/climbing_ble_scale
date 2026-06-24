import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:personal/models/scale_reading.dart';

class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.readings, required this.streamStartedAt, required this.overallMaxWeightKg});

  final List<ScaleReading> readings;
  final DateTime? streamStartedAt;
  final double overallMaxWeightKg;
  static const int att = 100;

  @override
  Widget build(BuildContext context) {
    final DateTime? startTime = streamStartedAt;
    final List<double> xValues = <double>[];
    final List<double> yValues = <double>[];

    for (final ScaleReading reading in readings) {
      final double seconds = startTime == null ? 0 : reading.timestamp.difference(startTime).inMilliseconds / att;
      xValues.add(seconds);
      yValues.add(reading.weightKg);
    }

    final List<FlSpot> spots = <FlSpot>[
      for (int index = 0; index < xValues.length; index++) FlSpot(xValues[index], yValues[index]),
    ];

    final double minX = xValues.isEmpty ? 0 : xValues.first;
    final double maxX = xValues.length < 2 ? minX + 1 : (xValues.last == minX ? minX + 1 : xValues.last);
    final double maxY = overallMaxWeightKg <= 0 ? 1 : overallMaxWeightKg * 1.1;

    if (spots.length < 2) {
      return const Center(child: Text('Waiting for more samples...'));
    }

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          verticalInterval: ((maxX - minX) / 4).clamp(1, double.infinity),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Time (s)'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: ((maxX - minX) / 4).clamp(1, double.infinity),
              getTitlesWidget: (double value, TitleMeta meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(value.toStringAsFixed(0)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Weight (kg)'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              interval: (maxY / 4).clamp(0.5, double.infinity),
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(value.toStringAsFixed(1));
              },
            ),
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}