import 'package:flutter/material.dart';
import 'package:chloro/services/firebase_service.dart';
import '../models.dart';
import '../widgets/sensor_card.dart';
import '../widgets/history_modal.dart';
import '../widgets/metric_explanation.dart';

class DashboardTabWithHistory extends StatefulWidget {
  final SensorData sensorData;
  final String plantStatus;
  final Color statusColor;

  const DashboardTabWithHistory({
    super.key,
    required this.sensorData,
    required this.plantStatus,
    required this.statusColor,
  });

  @override
  State<DashboardTabWithHistory> createState() =>
      _DashboardTabWithHistoryState();
}

class _DashboardTabWithHistoryState extends State<DashboardTabWithHistory> {
  // History data
  Map<String, SensorHistory> sensorHistories = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Fetch history data from Firebase
      await Future.wait([
        _fetchTemperatureHistory(),
        _fetchHumidityHistory(),
        _fetchMoistureHistory(),
        _fetchLightHistory(),
      ]);

      // Set up real-time listeners
      _setupRealtimeListeners();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error initializing data: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // ============================================================
  // REPLACE the 4 fetch methods + _setupRealtimeListeners()
  // in dashboard_with_history.dart with these:
  //
  // YOUR FIRESTORE FIELD NAMES:
  //   temperature   → temperature
  //   humidity      → humidity
  //   soil_percent  → soilMoisture (0–100%)
  //   ldr           → lightIntensity
  //   timestamp     → number (Unix epoch), NOT an ISO string
  // ============================================================

  Future<void> _fetchTemperatureHistory() async {
    try {
      final readings = await FirebaseService.instance.getHistoryReadings(
        'temperature',
      );
      final dataPoints = readings
          .where(
            (r) => r.containsKey('temperature') && r.containsKey('timestamp'),
          )
          .map(
            (r) => HistoryDataPoint(
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                (r['timestamp'] as num).toInt() * 1000,
              ),
              value: (r['temperature'] as num).toDouble(),
            ),
          )
          .toList();

      sensorHistories['temperature'] = SensorHistory(
        sensorName: 'Temperature',
        unit: '°C',
        color: Colors.orange,
        dataPoints: dataPoints.isNotEmpty
            ? dataPoints
            : [
                HistoryDataPoint(
                  timestamp: DateTime.now(),
                  value: widget.sensorData.temperature,
                ),
              ],
      );
    } catch (e) {
      print('Error fetching temperature history: $e');
      sensorHistories['temperature'] = SensorHistory(
        sensorName: 'Temperature',
        unit: '°C',
        color: Colors.orange,
        dataPoints: [
          HistoryDataPoint(
            timestamp: DateTime.now(),
            value: widget.sensorData.temperature,
          ),
        ],
      );
    }
  }

  Future<void> _fetchHumidityHistory() async {
    try {
      final readings = await FirebaseService.instance.getHistoryReadings(
        'humidity',
      );
      final dataPoints = readings
          .where((r) => r.containsKey('humidity') && r.containsKey('timestamp'))
          .map(
            (r) => HistoryDataPoint(
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                (r['timestamp'] as num).toInt() * 1000,
              ),
              value: (r['humidity'] as num).toDouble(),
            ),
          )
          .toList();

      sensorHistories['humidity'] = SensorHistory(
        sensorName: 'Humidity',
        unit: '%',
        color: Colors.cyan,
        dataPoints: dataPoints.isNotEmpty
            ? dataPoints
            : [
                HistoryDataPoint(
                  timestamp: DateTime.now(),
                  value: widget.sensorData.humidity,
                ),
              ],
      );
    } catch (e) {
      print('Error fetching humidity history: $e');
      sensorHistories['humidity'] = SensorHistory(
        sensorName: 'Humidity',
        unit: '%',
        color: Colors.cyan,
        dataPoints: [
          HistoryDataPoint(
            timestamp: DateTime.now(),
            value: widget.sensorData.humidity,
          ),
        ],
      );
    }
  }

  Future<void> _fetchMoistureHistory() async {
    try {
      final readings = await FirebaseService.instance.getHistoryReadings(
        'soil_percent',
      );
      final dataPoints = readings
          .where(
            (r) => r.containsKey('soil_percent') && r.containsKey('timestamp'),
          )
          .map(
            (r) => HistoryDataPoint(
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                (r['timestamp'] as num).toInt() * 1000,
              ),
              value: (r['soil_percent'] as num).toDouble(),
            ),
          )
          .toList();

      sensorHistories['moisture'] = SensorHistory(
        sensorName: 'Soil Moisture',
        unit: '%',
        color: Colors.blue,
        dataPoints: dataPoints.isNotEmpty
            ? dataPoints
            : [
                HistoryDataPoint(
                  timestamp: DateTime.now(),
                  value: widget.sensorData.soilMoisture,
                ),
              ],
      );
    } catch (e) {
      print('Error fetching moisture history: $e');
      sensorHistories['moisture'] = SensorHistory(
        sensorName: 'Soil Moisture',
        unit: '%',
        color: Colors.blue,
        dataPoints: [
          HistoryDataPoint(
            timestamp: DateTime.now(),
            value: widget.sensorData.soilMoisture,
          ),
        ],
      );
    }
  }

  Future<void> _fetchLightHistory() async {
    try {
      final readings = await FirebaseService.instance.getHistoryReadings('ldr');
      final dataPoints = readings
          .where((r) => r.containsKey('ldr') && r.containsKey('timestamp'))
          .map(
            (r) => HistoryDataPoint(
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                (r['timestamp'] as num).toInt() * 1000,
              ),
              value: (r['ldr'] as num).toDouble(),
            ),
          )
          .toList();

      sensorHistories['light'] = SensorHistory(
        sensorName: 'Light Intensity',
        unit: 'lux',
        color: Colors.amber,
        dataPoints: dataPoints.isNotEmpty
            ? dataPoints
            : [
                HistoryDataPoint(
                  timestamp: DateTime.now(),
                  value: widget.sensorData.lightIntensity,
                ),
              ],
      );
    } catch (e) {
      print('Error fetching light history: $e');
      sensorHistories['light'] = SensorHistory(
        sensorName: 'Light Intensity',
        unit: 'lux',
        color: Colors.amber,
        dataPoints: [
          HistoryDataPoint(
            timestamp: DateTime.now(),
            value: widget.sensorData.lightIntensity,
          ),
        ],
      );
    }
  }

  void _setupRealtimeListeners() {
    FirebaseService.instance.getSensorReadings().listen((data) {
      if (mounted && data != null) {
        setState(() {
          if (data.containsKey('temperature')) {
            final v = (data['temperature'] as num).toDouble();
            widget.sensorData.temperature = v;
            sensorHistories['temperature']?.dataPoints.add(
              HistoryDataPoint(timestamp: DateTime.now(), value: v),
            );
            if ((sensorHistories['temperature']?.dataPoints.length ?? 0) >
                1440) {
              sensorHistories['temperature']!.dataPoints.removeAt(0);
            }
          }

          if (data.containsKey('humidity')) {
            final v = (data['humidity'] as num).toDouble();
            widget.sensorData.humidity = v;
            sensorHistories['humidity']?.dataPoints.add(
              HistoryDataPoint(timestamp: DateTime.now(), value: v),
            );
            if ((sensorHistories['humidity']?.dataPoints.length ?? 0) > 1440) {
              sensorHistories['humidity']!.dataPoints.removeAt(0);
            }
          }

          if (data.containsKey('soil_percent')) {
            final v = (data['soil_percent'] as num).toDouble();
            widget.sensorData.soilMoisture = v;
            sensorHistories['moisture']?.dataPoints.add(
              HistoryDataPoint(timestamp: DateTime.now(), value: v),
            );
            if ((sensorHistories['moisture']?.dataPoints.length ?? 0) > 1440) {
              sensorHistories['moisture']!.dataPoints.removeAt(0);
            }
          }

          if (data.containsKey('ldr')) {
            final v = (data['ldr'] as num).toDouble();
            widget.sensorData.lightIntensity = v;
            sensorHistories['light']?.dataPoints.add(
              HistoryDataPoint(timestamp: DateTime.now(), value: v),
            );
            if ((sensorHistories['light']?.dataPoints.length ?? 0) > 1440) {
              sensorHistories['light']!.dataPoints.removeAt(0);
            }
          }
        });
      }
    }, onError: (e) => print('❌ Sensor stream error: $e'));
  }

  void _showSensorHistory(String sensorKey) {
    if (sensorHistories.containsKey(sensorKey)) {
      late double currentValue;
      switch (sensorKey) {
        case 'temperature':
          currentValue = widget.sensorData.temperature;
          break;
        case 'humidity':
          currentValue = widget.sensorData.humidity;
          break;
        case 'moisture':
          currentValue = widget.sensorData.soilMoisture;
          break;
        case 'light':
          currentValue = widget.sensorData.lightIntensity;
          break;
      }

      showDialog(
        context: context,
        builder: (context) => HistoryModal(
          history: sensorHistories[sensorKey]!,
          currentValue: currentValue,
        ),
      );
    }
  }

  void _explainMetric(String name, double value, String unit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) =>
          MetricExplanation(name: name, value: value, unit: unit),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error loading data: $errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plant Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.statusColor, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'Plant Status',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: widget.statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.plantStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sensor Cards with History
          Text(
            'Live Sensor Data (Click for History)',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              // Temperature Card
              SensorCardWithChart(
                sensorName: 'Temperature',
                unit: '°C',
                currentValue: widget.sensorData.temperature,
                chartColor: Colors.orange,
                history: sensorHistories['temperature'],
                onTap: () => _showSensorHistory('temperature'),
                onExplain: () => _explainMetric(
                  'Temperature',
                  widget.sensorData.temperature,
                  '°C',
                ),
              ),

              // Humidity Card
              SensorCardWithChart(
                sensorName: 'Humidity',
                unit: '%',
                currentValue: widget.sensorData.humidity,
                chartColor: Colors.cyan,
                history: sensorHistories['humidity'],
                onTap: () => _showSensorHistory('humidity'),
                onExplain: () =>
                    _explainMetric('Humidity', widget.sensorData.humidity, '%'),
              ),

              // Soil Moisture Card
              SensorCardWithChart(
                sensorName: 'Soil Moisture',
                unit: '%',
                currentValue: widget.sensorData.soilMoisture,
                chartColor: Colors.blue,
                history: sensorHistories['moisture'],
                onTap: () => _showSensorHistory('moisture'),
                onExplain: () => _explainMetric(
                  'Soil moisture',
                  widget.sensorData.soilMoisture,
                  '%',
                ),
              ),

              // Light Intensity Card
              SensorCardWithChart(
                sensorName: 'Light Intensity',
                unit: 'lux',
                currentValue: widget.sensorData.lightIntensity,
                chartColor: Colors.amber,
                history: sensorHistories['light'],
                onTap: () => _showSensorHistory('light'),
                onExplain: () => _explainMetric(
                  'Light intensity',
                  widget.sensorData.lightIntensity,
                  ' lux',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
