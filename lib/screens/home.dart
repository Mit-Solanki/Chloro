// lib/screens/home.dart
//
// Main home screen.
// Changes vs original:
//  • Cloud icon in top-left pings ESP32 every 10s — real connected/disconnected
//  • isConnected is no longer a manual toggle — it reflects actual ESP32 state

import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/firebase_service.dart';
import '../services/esp32_music_service.dart';
import 'dashboard_with_history.dart';
import 'led_control.dart';
import 'speaker_control.dart';
import 'settings.dart';
import 'notification_history.dart';
import 'alarm.dart';
import 'music_player.dart'; // for esp32Ip
import 'ai_assistant.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ESP32 connection state — updated by periodic ping
  bool _esp32Connected = false;
  Timer? _pingTimer;
  Timer? _notifTimer;

  bool showAlert = true;

  // Data models
  final SensorData sensorData = SensorData();
  final LEDSettings ledSettings = LEDSettings();
  final SpeakerSettings speakerSettings = SpeakerSettings();
  AppSettings appSettings = AppSettings(); // loaded from storage

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSettings();
    _setupRealtimeListeners();
    _startEsp32Ping();
  }

  // ── Load persisted settings ───────────────────────────────────────────────
  Future<void> _loadSettings() async {
    final saved = await SettingsStorage.load();
    if (mounted) setState(() => appSettings = saved);
  }

  // ── Save settings whenever they change ───────────────────────────────────
  Future<void> _saveSettings() => SettingsStorage.save(appSettings);

  // ── Ping ESP32 every 10 seconds to update the cloud icon ─────────────────
  void _startEsp32Ping() {
    _pingEsp32(); // immediate first check
    _pingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _pingEsp32(),
    );
  }

  Future<void> _pingEsp32() async {
    final svc = Esp32MusicService(ip: esp32Ip);
    final reachable = await svc.isReachable();
    if (mounted) {
      setState(() => _esp32Connected = reachable);
    }
  }

  void _setupRealtimeListeners() {
    FirebaseService.instance.getSensorReadings().listen((data) {
      if (mounted && data != null) {
        setState(() {
          if (data.containsKey('temperature'))
            sensorData.temperature = (data['temperature'] as num).toDouble();
          if (data.containsKey('humidity'))
            sensorData.humidity = (data['humidity'] as num).toDouble();
          // Firestore field is 'soil_percent' (not 'soil_moisture')
          if (data.containsKey('soil_percent'))
            sensorData.soilMoisture = (data['soil_percent'] as num).toDouble();
          // Firestore field is 'ldr' (not 'light_intensity')
          if (data.containsKey('ldr'))
            sensorData.lightIntensity = (data['ldr'] as num).toDouble();
        });
        // Check thresholds and log a notification if needed
        if (appSettings.alertsEnabled) {
          NotificationService.checkAndLog(
            sensorData: sensorData,
            settings: appSettings,
          );
        }
      }
    }, onError: (e) => print('❌ Sensor stream error: $e'));
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _notifTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String getPlantStatus() {
    if (sensorData.soilMoisture < appSettings.moistureThreshold)
      return 'Needs Water';
    if (sensorData.lightIntensity < appSettings.lightThreshold)
      return 'Low Light';
    return 'Healthy';
  }

  Color getStatusColor() {
    final s = getPlantStatus();
    if (s == 'Healthy') return Colors.green;
    if (s == 'Needs Water') return Colors.blue;
    return Colors.orange;
  }

  Color getBackgroundColor() {
    if (!showAlert || getPlantStatus() == 'Healthy') return Colors.white;
    return getStatusColor().withOpacity(0.08);
  }

  void _updateDeviceName(String name) {
    setState(() => appSettings.deviceName = name);
    _saveSettings();
  }

  void _updateMoistureThreshold(double value) {
    setState(() => appSettings.moistureThreshold = value);
    _saveSettings();
  }

  void _updateLightThreshold(double value) {
    setState(() => appSettings.lightThreshold = value);
    _saveSettings();
  }

  void _toggleLED(bool state) => setState(() => ledSettings.isOn = state);
  void _updateBrightness(double value) =>
      setState(() => ledSettings.brightness = value);
  void _updateColor(Color color) => setState(() => ledSettings.color = color);
  void _togglePlayPause(bool state) =>
      setState(() => speakerSettings.isPlaying = state);
  void _updateTrack(String track) =>
      setState(() => speakerSettings.selectedTrack = track);
  void _updateVolume(double value) =>
      setState(() => speakerSettings.volume = value);

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
        // ── Cloud icon: real ESP32 connection status ───────────────────────
        leading: Tooltip(
          message: _esp32Connected ? 'ESP32 Connected' : 'ESP32 Offline',
          child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _esp32Connected ? Icons.cloud_done : Icons.cloud_off,
                key: ValueKey(_esp32Connected),
                color: _esp32Connected ? Colors.white : Colors.red[300],
              ),
            ),
            onPressed: _pingEsp32, // tap to manually recheck
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationHistoryScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: getBackgroundColor(),
        child: Column(
          children: [
            // Alert banner
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
                      onPressed: () => setState(() => showAlert = false),
                    ),
                  ],
                ),
              ),
            // Tab bar
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
                  Tab(text: 'AI Assistant', icon: Icon(Icons.auto_awesome)),
                ],
              ),
            ),
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  DashboardTabWithHistory(
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
                    onAlertsEnabledChange: (v) {
                      setState(() => appSettings.alertsEnabled = v);
                      _saveSettings();
                    },
                    onPushNotificationsChange: (v) {
                      setState(() => appSettings.pushNotificationsEnabled = v);
                      _saveSettings();
                    },
                  ),
                  AiAssistantTab(
                    sensorData: sensorData,
                    appSettings: appSettings,
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlarmScreen()),
            );
          } else if (_tabController.index == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add new LED controller')),
            );
          } else if (_tabController.index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Loading music from device...')),
            );
          } else {
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
