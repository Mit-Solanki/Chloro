# Quick Integration Guide - Add History to Your HomePage

## 📋 Step-by-Step Integration

### Step 1: Update `lib/screens/home.dart`

Add these imports at the top:

```dart
import 'package:chloro/widgets/sensor_card.dart';
import 'package:chloro/widgets/history_modal.dart';
```

### Step 2: Add History Data to Your State Class

In `_HomePageState`, add:

```dart
// History data storage
Map<String, SensorHistory> sensorHistories = {};

@override
void initState() {
  super.initState();
  _tabController = TabController(length: 4, vsync: this);
  _initializeHistoryData(); // Add this line
}

void _initializeHistoryData() {
  // Generate mock history (replace with Firebase data later)
  _createMockHistory();
}

void _createMockHistory() {
  // Temperature History
  final tempDataPoints = <HistoryDataPoint>[];
  for (int i = 0; i < 24; i++) {
    tempDataPoints.add(
      HistoryDataPoint(
        timestamp: DateTime.now().subtract(Duration(hours: i)),
        value: sensorData.temperature + (Random().nextInt(5) - 2),
      ),
    );
  }
  sensorHistories['temperature'] = SensorHistory(
    sensorName: 'Temperature',
    unit: '°C',
    color: Colors.red,
    dataPoints: tempDataPoints,
  );

  // Humidity History
  final humidityDataPoints = <HistoryDataPoint>[];
  for (int i = 0; i < 24; i++) {
    humidityDataPoints.add(
      HistoryDataPoint(
        timestamp: DateTime.now().subtract(Duration(hours: i)),
        value: sensorData.humidity + (Random().nextInt(10) - 5),
      ),
    );
  }
  sensorHistories['humidity'] = SensorHistory(
    sensorName: 'Humidity',
    unit: '%',
    color: Colors.blue,
    dataPoints: humidityDataPoints,
  );

  // Soil Moisture History
  final moistureDataPoints = <HistoryDataPoint>[];
  for (int i = 0; i < 24; i++) {
    moistureDataPoints.add(
      HistoryDataPoint(
        timestamp: DateTime.now().subtract(Duration(hours: i)),
        value: sensorData.soilMoisture + (Random().nextInt(15) - 8),
      ),
    );
  }
  sensorHistories['moisture'] = SensorHistory(
    sensorName: 'Soil Moisture',
    unit: '%',
    color: Colors.green,
    dataPoints: moistureDataPoints,
  );

  // Light History
  final lightDataPoints = <HistoryDataPoint>[];
  for (int i = 0; i < 24; i++) {
    lightDataPoints.add(
      HistoryDataPoint(
        timestamp: DateTime.now().subtract(Duration(hours: i)),
        value: sensorData.lightIntensity + (Random().nextInt(1000) - 500),
      ),
    );
  }
  sensorHistories['light'] = SensorHistory(
    sensorName: 'Light Intensity',
    unit: 'lux',
    color: Colors.amber,
    dataPoints: lightDataPoints,
  );
}

void _showSensorHistory(String sensorKey) {
  if (sensorHistories.containsKey(sensorKey)) {
    late double currentValue;
    switch (sensorKey) {
      case 'temperature':
        currentValue = sensorData.temperature;
        break;
      case 'humidity':
        currentValue = sensorData.humidity;
        break;
      case 'moisture':
        currentValue = sensorData.soilMoisture;
        break;
      case 'light':
        currentValue = sensorData.lightIntensity;
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
```

### Step 3: Create a Sensor Grid Widget

Add this method to display sensor cards with history:

```dart
Widget _buildSensorGrid() {
  return GridView.count(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    padding: const EdgeInsets.all(16),
    children: [
      // Temperature Card
      SensorCardWithChart(
        sensorName: 'Temperature',
        unit: '°C',
        currentValue: sensorData.temperature,
        chartColor: Colors.red,
        history: sensorHistories['temperature'],
        onTap: () => _showSensorHistory('temperature'),
      ),

      // Humidity Card
      SensorCardWithChart(
        sensorName: 'Humidity',
        unit: '%',
        currentValue: sensorData.humidity,
        chartColor: Colors.blue,
        history: sensorHistories['humidity'],
        onTap: () => _showSensorHistory('humidity'),
      ),

      // Soil Moisture Card
      SensorCardWithChart(
        sensorName: 'Soil Moisture',
        unit: '%',
        currentValue: sensorData.soilMoisture,
        chartColor: Colors.green,
        history: sensorHistories['moisture'],
        onTap: () => _showSensorHistory('moisture'),
      ),

      // Light Intensity Card
      SensorCardWithChart(
        sensorName: 'Light Intensity',
        unit: 'lux',
        currentValue: sensorData.lightIntensity,
        chartColor: Colors.amber,
        history: sensorHistories['light'],
        onTap: () => _showSensorHistory('light'),
      ),
    ],
  );
}
```

### Step 4: Update Your Build Method

Replace your current sensor display with:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    // ... your app bar and other widgets ...
    body: TabBarView(
      controller: _tabController,
      children: [
        // Dashboard Tab - Now with history
        _buildSensorGrid(),
        
        // Your other tabs...
        DashboardPage(
          // ... properties
        ),
        // ... other pages
      ],
    ),
  );
}
```

### Step 5: Import Required Packages

Add to imports:

```dart
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import '../models.dart';
```

## 🔄 Connect to Firebase (Optional)

To fetch real data from Firebase instead of mock data:

```dart
Future<void> _loadHistoryFromFirebase() async {
  try {
    // Fetch temperature history
    final tempData = await FirebaseService.instance
      .readData('history/temperature');
    
    if (tempData != null && tempData['data'] is List) {
      final dataPoints = (tempData['data'] as List)
        .map((item) => HistoryDataPoint.fromJson(item as Map<String, dynamic>))
        .toList();
      
      sensorHistories['temperature'] = SensorHistory(
        sensorName: 'Temperature',
        unit: '°C',
        color: Colors.red,
        dataPoints: dataPoints,
      );
    }
    
    // Repeat for other sensors...
    
    setState(() {}); // Update UI
  } catch (e) {
    print('Error loading history: $e');
  }
}
```

Then call `_loadHistoryFromFirebase()` in `initState()` instead of `_createMockHistory()`.

## ✅ Testing

1. Run the app:
   ```bash
   flutter pub get
   flutter run
   ```

2. Navigate to your home page

3. You should see 4 cards:
   - Each card displays current value with translucent chart
   - Click any card to see detailed history

4. The modal shows:
   - Full-size chart
   - Statistics (Current, Average, Min, Max)
   - Recent data points

## 🎯 Next Steps

1. **Fetch real data** - Replace mock data with Firebase queries
2. **Update history** - Add new readings to history when sensor updates
3. **Optimize** - Implement pagination for large datasets
4. **Customize** - Adjust colors, time ranges, and chart styling

---

**Done!** You now have a complete history feature! 🎉
