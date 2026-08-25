import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SensorData {
  double soilMoisture;
  double temperature;
  double humidity;
  double lightIntensity;

  SensorData({
    this.soilMoisture = 65.0,
    this.temperature = 25.5,
    this.humidity = 72.0,
    this.lightIntensity = 8500.0,
  });
}

class LEDSettings {
  bool isOn;
  double brightness;
  Color color;

  LEDSettings({
    this.isOn = true,
    this.brightness = 75.0,
    this.color = Colors.white,
  });
}

class SpeakerSettings {
  bool isPlaying;
  double volume;
  String selectedTrack;

  SpeakerSettings({
    this.isPlaying = false,
    this.volume = 70.0,
    this.selectedTrack = 'Forest Ambience',
  });
}

class AppSettings {
  String deviceName;
  double moistureThreshold;
  double lightThreshold;
  bool alertsEnabled;
  bool pushNotificationsEnabled;

  AppSettings({
    this.deviceName = 'My Plant Pot',
    this.moistureThreshold = 30.0,
    this.lightThreshold = 3000.0,
    this.alertsEnabled = true,
    this.pushNotificationsEnabled = true,
  });
}

class AiAdvice {
  final String status;
  final String headline;
  final String advice;
  final String confidence;

  AiAdvice({
    required this.status,
    required this.headline,
    required this.advice,
    this.confidence = '',
  });
}

// ============== Persistent Settings ==============
// Call SettingsStorage.load() once on startup.
// Call SettingsStorage.save(settings) on every change.

class SettingsStorage {
  static const _key = 'app_settings_v1';

  static Future<AppSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return AppSettings();
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettings(
        deviceName: j['deviceName'] as String? ?? 'My Plant Pot',
        moistureThreshold: (j['moistureThreshold'] as num?)?.toDouble() ?? 30.0,
        lightThreshold: (j['lightThreshold'] as num?)?.toDouble() ?? 3000.0,
        alertsEnabled: j['alertsEnabled'] as bool? ?? true,
        pushNotificationsEnabled:
            j['pushNotificationsEnabled'] as bool? ?? true,
      );
    } catch (_) {
      return AppSettings();
    }
  }

  static Future<void> save(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'deviceName': s.deviceName,
        'moistureThreshold': s.moistureThreshold,
        'lightThreshold': s.lightThreshold,
        'alertsEnabled': s.alertsEnabled,
        'pushNotificationsEnabled': s.pushNotificationsEnabled,
      }),
    );
  }
}

const List<String> predefinedTracks = [
  'Forest Ambience',
  'Rain Sounds',
  'Bird Songs',
  'Nature Sounds',
];

const List<Color> ledColors = [
  Colors.white,
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.yellow,
  Colors.purple,
];

const List<String> colorNames = [
  'White',
  'Red',
  'Green',
  'Blue',
  'Yellow',
  'Purple',
];

// ============== History Data Models ==============

class HistoryDataPoint {
  final DateTime timestamp;
  final double value;

  HistoryDataPoint({required this.timestamp, required this.value});

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'value': value,
  };

  factory HistoryDataPoint.fromJson(Map<String, dynamic> json) {
    return HistoryDataPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: (json['value'] as num).toDouble(),
    );
  }
}

class SensorHistory {
  final String sensorName;
  final String unit;
  final Color color;
  final List<HistoryDataPoint> dataPoints;

  SensorHistory({
    required this.sensorName,
    required this.unit,
    required this.color,
    this.dataPoints = const [],
  });

  // Get min value from history
  double get minValue {
    if (dataPoints.isEmpty) return 0;
    return dataPoints.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  }

  // Get max value from history
  double get maxValue {
    if (dataPoints.isEmpty) return 100;
    return dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  }

  // Get average value
  double get averageValue {
    if (dataPoints.isEmpty) return 0;
    return dataPoints.map((p) => p.value).reduce((a, b) => a + b) /
        dataPoints.length;
  }

  // Get latest value
  double? get latestValue {
    if (dataPoints.isEmpty) return null;
    return dataPoints.last.value;
  }
}
