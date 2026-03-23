import 'package:flutter/material.dart';
import '../models.dart';
import 'dashboard.dart';
import 'led_control.dart';
import 'speaker_control.dart';
import 'settings.dart';
import 'notification_history.dart';
import 'alarm.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isConnected = true;
  bool showAlert = true;

  // Data models
  final SensorData sensorData = SensorData();
  final LEDSettings ledSettings = LEDSettings();
  final SpeakerSettings speakerSettings = SpeakerSettings();
  final AppSettings appSettings = AppSettings();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String getPlantStatus() {
    if (sensorData.soilMoisture < appSettings.moistureThreshold) {
      return 'Needs Water';
    } else if (sensorData.lightIntensity < appSettings.lightThreshold) {
      return 'Low Light';
    }
    return 'Healthy';
  }

  Color getStatusColor() {
    String status = getPlantStatus();
    if (status == 'Healthy') return Colors.green;
    if (status == 'Needs Water') return Colors.blue;
    return Colors.orange;
  }

  Color getBackgroundColor() {
    if (!showAlert || getPlantStatus() == 'Healthy') {
      return Colors.white;
    }
    return getStatusColor().withOpacity(0.08);
  }

  void _updateDeviceName(String name) {
    setState(() {
      appSettings.deviceName = name;
    });
  }

  void _updateMoistureThreshold(double value) {
    setState(() {
      appSettings.moistureThreshold = value;
    });
  }

  void _updateLightThreshold(double value) {
    setState(() {
      appSettings.lightThreshold = value;
    });
  }

  void _toggleLED(bool state) {
    setState(() {
      ledSettings.isOn = state;
    });
  }

  void _updateBrightness(double value) {
    setState(() {
      ledSettings.brightness = value;
    });
  }

  void _updateColor(Color color) {
    setState(() {
      ledSettings.color = color;
    });
  }

  void _togglePlayPause(bool state) {
    setState(() {
      speakerSettings.isPlaying = state;
    });
  }

  void _updateTrack(String track) {
    setState(() {
      speakerSettings.selectedTrack = track;
    });
  }

  void _updateVolume(double value) {
    setState(() {
      speakerSettings.volume = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chloro',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isConnected ? Icons.cloud_done : Icons.cloud_off,
            color: isConnected ? Colors.white : Colors.red,
          ),
          onPressed: () {
            setState(() {
              isConnected = !isConnected;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: getBackgroundColor(),
        child: Column(
          children: [
            // Alert Banner
            if (showAlert && getPlantStatus() != 'Healthy')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: getStatusColor().withOpacity(0.3),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: getStatusColor()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Alert: ${getPlantStatus()}',
                        style: TextStyle(
                          color: getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          showAlert = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            // Tab Bar
            Container(
              color: Colors.green,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
                  Tab(text: 'LED Control', icon: Icon(Icons.lightbulb)),
                  Tab(text: 'Speaker', icon: Icon(Icons.speaker)),
                  Tab(text: 'Settings', icon: Icon(Icons.settings)),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  DashboardTab(
                    sensorData: sensorData,
                    plantStatus: getPlantStatus(),
                    statusColor: getStatusColor(),
                  ),
                  LEDControlTab(
                    ledSettings: ledSettings,
                    onLEDToggle: _toggleLED,
                    onBrightnessChange: _updateBrightness,
                    onColorChange: _updateColor,
                  ),
                  SpeakerControlTab(
                    speakerSettings: speakerSettings,
                    onPlayPauseToggle: _togglePlayPause,
                    onTrackChange: _updateTrack,
                    onVolumeChange: _updateVolume,
                  ),
                  SettingsTab(
                    appSettings: appSettings,
                    onDeviceNameChange: _updateDeviceName,
                    onMoistureThresholdChange: _updateMoistureThreshold,
                    onLightThresholdChange: _updateLightThreshold,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            // Dashboard: Open Alarm Screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AlarmScreen()),
            );
          } else if (_tabController.index == 1) {
            // LED Control: Add new LED
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add new LED controller')),
            );
          } else if (_tabController.index == 2) {
            // Speaker: Show device music
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Loading music from device...')),
            );
          } else {
            // Settings: Default action
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Settings option')));
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}
