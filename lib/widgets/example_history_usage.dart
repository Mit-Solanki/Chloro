import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/sensor_card.dart';
import '../widgets/history_modal.dart';

/// Example: Using History Cards on the Home Page
/// 
/// Add this to your homepage to display sensors with history:

class ExampleHistoryUsage extends StatefulWidget {
  const ExampleHistoryUsage({super.key});

  @override
  State<ExampleHistoryUsage> createState() => _ExampleHistoryUsageState();
}

class _ExampleHistoryUsageState extends State<ExampleHistoryUsage> {
  // Mock sensor data
  late SensorData sensorData;

  // Mock history data
  late SensorHistory temperatureHistory;
  late SensorHistory humidityHistory;
  late SensorHistory moistureHistory;
  late SensorHistory lightHistory;

  @override
  void initState() {
    super.initState();
    sensorData = SensorData();
    _generateMockHistoryData();
  }

  void _generateMockHistoryData() {
    // Generate mock temperature history
    final tempDataPoints = <HistoryDataPoint>[];
    for (int i = 0; i < 24; i++) {
      tempDataPoints.add(
        HistoryDataPoint(
          timestamp: DateTime.now().subtract(Duration(hours: i)),
          value: 20.0 + (i % 5).toDouble(),
        ),
      );
    }
    temperatureHistory = SensorHistory(
      sensorName: 'Temperature',
      unit: '°C',
      color: Colors.red,
      dataPoints: tempDataPoints,
    );

    // Generate mock humidity history
    final humidityDataPoints = <HistoryDataPoint>[];
    for (int i = 0; i < 24; i++) {
      humidityDataPoints.add(
        HistoryDataPoint(
          timestamp: DateTime.now().subtract(Duration(hours: i)),
          value: 60.0 + (i % 20).toDouble(),
        ),
      );
    }
    humidityHistory = SensorHistory(
      sensorName: 'Humidity',
      unit: '%',
      color: Colors.blue,
      dataPoints: humidityDataPoints,
    );

    // Generate mock soil moisture history
    final moistureDataPoints = <HistoryDataPoint>[];
    for (int i = 0; i < 24; i++) {
      moistureDataPoints.add(
        HistoryDataPoint(
          timestamp: DateTime.now().subtract(Duration(hours: i)),
          value: 50.0 + (i % 30).toDouble(),
        ),
      );
    }
    moistureHistory = SensorHistory(
      sensorName: 'Soil Moisture',
      unit: '%',
      color: Colors.green,
      dataPoints: moistureDataPoints,
    );

    // Generate mock light intensity history
    final lightDataPoints = <HistoryDataPoint>[];
    for (int i = 0; i < 24; i++) {
      lightDataPoints.add(
        HistoryDataPoint(
          timestamp: DateTime.now().subtract(Duration(hours: i)),
          value: 5000.0 + (i * 200).toDouble(),
        ),
      );
    }
    lightHistory = SensorHistory(
      sensorName: 'Light Intensity',
      unit: 'lux',
      color: Colors.amber,
      dataPoints: lightDataPoints,
    );
  }

  void _showHistoryModal(SensorHistory history, double currentValue) {
    showDialog(
      context: context,
      builder: (context) => HistoryModal(
        history: history,
        currentValue: currentValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      padding: const EdgeInsets.all(16),
      children: [
        // Temperature Card
        SensorCardWithChart(
          sensorName: 'Temperature',
          unit: '°C',
          currentValue: sensorData.temperature,
          chartColor: Colors.red,
          history: temperatureHistory,
          onTap: () => _showHistoryModal(temperatureHistory, sensorData.temperature),
        ),
        
        // Humidity Card
        SensorCardWithChart(
          sensorName: 'Humidity',
          unit: '%',
          currentValue: sensorData.humidity,
          chartColor: Colors.blue,
          history: humidityHistory,
          onTap: () => _showHistoryModal(humidityHistory, sensorData.humidity),
        ),
        
        // Soil Moisture Card
        SensorCardWithChart(
          sensorName: 'Soil Moisture',
          unit: '%',
          currentValue: sensorData.soilMoisture,
          chartColor: Colors.green,
          history: moistureHistory,
          onTap: () => _showHistoryModal(moistureHistory, sensorData.soilMoisture),
        ),
        
        // Light Intensity Card
        SensorCardWithChart(
          sensorName: 'Light Intensity',
          unit: 'lux',
          currentValue: sensorData.lightIntensity,
          chartColor: Colors.amber,
          history: lightHistory,
          onTap: () => _showHistoryModal(lightHistory, sensorData.lightIntensity),
        ),
      ],
    );
  }
}
