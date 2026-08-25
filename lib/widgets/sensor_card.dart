import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models.dart';

class SensorCardWithChart extends StatelessWidget {
  final String sensorName;
  final String unit;
  final double currentValue;
  final Color chartColor;
  final SensorHistory? history;
  final VoidCallback onTap;
  final VoidCallback? onExplain;

  const SensorCardWithChart({
    super.key,
    required this.sensorName,
    required this.unit,
    required this.currentValue,
    required this.chartColor,
    required this.onTap,
    this.history,
    this.onExplain,
  });

  List<FlSpot> _getChartData() {
    if (history == null || history!.dataPoints.isEmpty) {
      return [FlSpot(0, currentValue), FlSpot(1, currentValue)];
    }

    return history!.dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _getChartData();
    final minY = (history?.minValue ?? currentValue) - 5;
    final maxY = (history?.maxValue ?? currentValue) + 5;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Translucent Chart Background
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData,
                        isCurved: true,
                        color: chartColor.withOpacity(0.2),
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: chartColor.withOpacity(0.1),
                        ),
                      ),
                    ],
                    minY: minY,
                    maxY: maxY,
                  ),
                ),
              ),
            ),
            if (onExplain != null)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  tooltip: 'Explain with AI',
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  onPressed: onExplain,
                ),
              ),
            // Value Display
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sensorName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currentValue.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: chartColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (history != null && history!.dataPoints.isNotEmpty)
                    Text(
                      'Avg: ${history!.averageValue.toStringAsFixed(1)} $unit',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
