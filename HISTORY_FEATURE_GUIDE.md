# History Feature Implementation Guide

## 📊 Overview

The history feature displays real-time sensor values with a **translucent line chart** in the background. When clicked, it opens a **modal dialog** showing detailed history data with statistics and a full-size chart.

## 🎯 Components

### 1. **Models** (`lib/models.dart`)
- `HistoryDataPoint` - Single data point with timestamp and value
- `SensorHistory` - Collection of data points with statistics (min, max, average)

### 2. **Widgets** (`lib/widgets/`)
- `SensorCardWithChart` - Card displaying current value with translucent chart
- `HistoryModal` - Full-screen dialog showing detailed history

### 3. **Example** (`lib/widgets/example_history_usage.dart`)
- Complete example of implementing history on home page

## 🚀 Usage

### Step 1: Import Required Components

```dart
import 'package:chloro/models.dart';
import 'package:chloro/widgets/sensor_card.dart';
import 'package:chloro/widgets/history_modal.dart';
```

### Step 2: Create History Data

```dart
// Create a list of data points
final dataPoints = <HistoryDataPoint>[];
for (int i = 0; i < 24; i++) {
  dataPoints.add(
    HistoryDataPoint(
      timestamp: DateTime.now().subtract(Duration(hours: i)),
      value: 20.0 + (i % 5).toDouble(), // Your sensor value
    ),
  );
}

// Create SensorHistory object
final temperatureHistory = SensorHistory(
  sensorName: 'Temperature',
  unit: '°C',
  color: Colors.red,
  dataPoints: dataPoints,
);
```

### Step 3: Display Card with Chart

```dart
SensorCardWithChart(
  sensorName: 'Temperature',
  unit: '°C',
  currentValue: 25.5,
  chartColor: Colors.red,
  history: temperatureHistory,
  onTap: () {
    showDialog(
      context: context,
      builder: (context) => HistoryModal(
        history: temperatureHistory,
        currentValue: 25.5,
      ),
    );
  },
)
```

## 📱 Full Example

Here's how to integrate it into your HomePage:

```dart
import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/sensor_card.dart';
import '../widgets/history_modal.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late SensorData sensorData;
  late SensorHistory temperatureHistory;

  @override
  void initState() {
    super.initState();
    sensorData = SensorData();
    _loadHistoryData();
  }

  void _loadHistoryData() {
    // Fetch from Firebase or local storage
    final dataPoints = <HistoryDataPoint>[];
    // ... populate dataPoints from database ...
    
    temperatureHistory = SensorHistory(
      sensorName: 'Temperature',
      unit: '°C',
      color: Colors.red,
      dataPoints: dataPoints,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      children: [
        SensorCardWithChart(
          sensorName: 'Temperature',
          unit: '°C',
          currentValue: sensorData.temperature,
          chartColor: Colors.red,
          history: temperatureHistory,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => HistoryModal(
                history: temperatureHistory,
                currentValue: sensorData.temperature,
              ),
            );
          },
        ),
      ],
    );
  }
}
```

## 🗄️ Firebase Integration

### Fetching History from Firebase

```dart
Future<List<HistoryDataPoint>> fetchTemperatureHistory() async {
  try {
    final snapshot = await FirebaseService.instance
      .readData('history/temperature');
    
    if (snapshot == null) return [];
    
    final historyList = snapshot['data'] as List;
    return historyList
      .map((item) => HistoryDataPoint.fromJson(item as Map<String, dynamic>))
      .toList();
  } catch (e) {
    print('Error fetching history: $e');
    return [];
  }
}
```

### Storing Data in Firebase

```dart
Future<void> saveTemperatureReading(double temperature) async {
  try {
    final dataPoint = HistoryDataPoint(
      timestamp: DateTime.now(),
      value: temperature,
    );
    
    await FirebaseService.instance.writeData(
      'history/temperature/${DateTime.now().millisecondsSinceEpoch}',
      dataPoint.toJson(),
    );
  } catch (e) {
    print('Error saving reading: $e');
  }
}
```

## 🎨 Customization

### Change Chart Colors

```dart
SensorCardWithChart(
  chartColor: Colors.blue,  // Change color here
  // ... other properties
)
```

### Adjust Card Size

Wrap card in a `SizedBox`:

```dart
SizedBox(
  height: 180,
  width: 160,
  child: SensorCardWithChart(
    // ... properties
  ),
)
```

### Modify Chart Sensitivity

In `SensorCardWithChart._getChartData()`:

```dart
final minY = (history?.minValue ?? currentValue) - 10; // Change padding
final maxY = (history?.maxValue ?? currentValue) + 10;
```

## 📊 SensorHistory Methods

```dart
// Get statistics
double minValue = history.minValue;
double maxValue = history.maxValue;
double averageValue = history.averageValue;
double? latestValue = history.latestValue;

// Add new data point
history.dataPoints.add(HistoryDataPoint(
  timestamp: DateTime.now(),
  value: 25.5,
));
```

## 🔄 Real-time Updates

To update history in real-time from Firebase:

```dart
@override
void initState() {
  super.initState();
  
  // Listen for real-time updates
  FirebaseService.instance
    .streamData('current/temperature')
    .listen((event) {
      setState(() {
        sensorData.temperature = event.snapshot.value as double;
        // Also save to history
        _addToHistory(sensorData.temperature);
      });
    });
}

void _addToHistory(double value) {
  final newPoint = HistoryDataPoint(
    timestamp: DateTime.now(),
    value: value,
  );
  temperatureHistory.dataPoints.add(newPoint);
  
  // Keep only last 24 hours
  if (temperatureHistory.dataPoints.length > 1440) {
    temperatureHistory.dataPoints.removeAt(0);
  }
}
```

## ⚡ Performance Tips

1. **Limit data points** - Keep last 24-48 hours (1440-2880 points)
2. **Batch updates** - Save to Firebase every 5 minutes instead of every reading
3. **Cache locally** - Use shared_preferences for recent data
4. **Pagination** - Load older data only when needed

## 🎯 Next Steps

1. Run `flutter pub get` to install `fl_chart` and `intl`
2. Check `example_history_usage.dart` for a complete working example
3. Integrate with Firebase in `initState()`
4. Test with real sensor data

---

💡 **Need Help?** Check the example file: `lib/widgets/example_history_usage.dart`
