import 'package:flutter/material.dart';

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
