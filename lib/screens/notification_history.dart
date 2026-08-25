// lib/screens/notification_history.dart
//
// Real sensor-driven notifications:
//  • NotificationService.checkAndLog() is called on every Firestore update in home.dart
//  • Each notification is persisted to SharedPreferences so it survives app restarts
//  • A notification fires only once per threshold-crossing (not every update)
//  • Notifications can be dismissed (swipe) or cleared all at once
//  • Conditions checked:
//      - Soil moisture below moistureThreshold  → Water alert
//      - LDR (light) below lightThreshold       → Low light alert
//      - Temperature > 35°C                     → High temperature alert
//      - Temperature < 10°C                     → Low temperature alert
//      - Humidity > 80%                         → High humidity alert
//      - Humidity < 30%                         → Low humidity alert

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Notification model
// ─────────────────────────────────────────────────────────────────────────────
class PlantNotification {
  final String   id;
  final String   title;
  final String   message;
  final DateTime timestamp;
  final String   type;       // 'water' | 'light' | 'temperature' | 'humidity' | 'info'

  PlantNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
  });

  IconData get icon {
    switch (type) {
      case 'water':       return Icons.water_drop;
      case 'light':       return Icons.light_mode;
      case 'temperature': return Icons.thermostat;
      case 'humidity':    return Icons.water_damage;
      default:            return Icons.info_outline;
    }
  }

  Color get color {
    switch (type) {
      case 'water':       return Colors.blue;
      case 'light':       return Colors.orange;
      case 'temperature': return Colors.red;
      case 'humidity':    return Colors.teal;
      default:            return Colors.green;
    }
  }

  Map<String, dynamic> toJson() => {
    'id':        id,
    'title':     title,
    'message':   message,
    'timestamp': timestamp.toIso8601String(),
    'type':      type,
  };

  factory PlantNotification.fromJson(Map<String, dynamic> j) => PlantNotification(
    id:        j['id']        as String,
    title:     j['title']     as String,
    message:   j['message']   as String,
    timestamp: DateTime.parse(j['timestamp'] as String),
    type:      j['type']      as String,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationService — called from home.dart on every sensor update
// ─────────────────────────────────────────────────────────────────────────────
class NotificationService {
  static const _listKey  = 'plant_notifications_v1';
  static const _stateKey = 'notif_alert_state_v1';
  static const _maxCount = 50; // cap stored notifications

  // Tracks which alerts are currently active to avoid repeated logging
  // Key = alert type, Value = true if alert is currently firing
  static final Map<String, bool> _activeAlerts = {};

  /// Called on every Firestore sensor update.
  static Future<void> checkAndLog({
    required SensorData  sensorData,
    required AppSettings settings,
  }) async {
    if (!settings.alertsEnabled) return;

    final toAdd = <PlantNotification>[];
    final now   = DateTime.now();

    // ── Moisture ──────────────────────────────────────────────
    _check(
      key:       'moisture_low',
      condition: sensorData.soilMoisture < settings.moistureThreshold,
      build:     () => PlantNotification(
        id:        '${now.millisecondsSinceEpoch}_moisture',
        title:     'Low Soil Moisture',
        message:   'Soil moisture is ${sensorData.soilMoisture.toStringAsFixed(0)}%'
                   ' — below your threshold of ${settings.moistureThreshold.toStringAsFixed(0)}%.'
                   ' Please water your plant.',
        timestamp: now,
        type:      'water',
      ),
      toAdd: toAdd,
    );

    // ── Light ─────────────────────────────────────────────────
    _check(
      key:       'light_low',
      condition: sensorData.lightIntensity < settings.lightThreshold,
      build:     () => PlantNotification(
        id:        '${now.millisecondsSinceEpoch}_light',
        title:     'Low Light Level',
        message:   'Light reading is ${sensorData.lightIntensity.toStringAsFixed(0)}'
                   ' — below your threshold of ${settings.lightThreshold.toStringAsFixed(0)}.'
                   ' Move plant to a brighter spot.',
        timestamp: now,
        type:      'light',
      ),
      toAdd: toAdd,
    );

    // ── High temperature ──────────────────────────────────────
    _check(
      key:       'temp_high',
      condition: sensorData.temperature > 35,
      build:     () => PlantNotification(
        id:        '${now.millisecondsSinceEpoch}_temp_high',
        title:     'High Temperature',
        message:   'Temperature is ${sensorData.temperature.toStringAsFixed(1)}°C'
                   ' — above 35°C. Move plant away from heat sources.',
        timestamp: now,
        type:      'temperature',
      ),
      toAdd: toAdd,
    );

    // ── Low temperature ───────────────────────────────────────
    _check(
      key:       'temp_low',
      condition: sensorData.temperature < 10,
      build:     () => PlantNotification(
        id:        '${now.millisecondsSinceEpoch}_temp_low',
        title:     'Low Temperature',
        message:   'Temperature is ${sensorData.temperature.toStringAsFixed(1)}°C'
                   ' — below 10°C. Move plant to a warmer location.',
        timestamp: now,
        type:      'temperature',
      ),
      toAdd: toAdd,
    );

    // ── High humidity ─────────────────────────────────────────
    _check(
      key:       'humidity_high',
      condition: sensorData.humidity > 80,
      build:     () => PlantNotification(
        id:        '${now.millisecondsSinceEpoch}_hum_high',
        title:     'High Humidity',
        message:   'Humidity is ${sensorData.humidity.toStringAsFixed(0)}%'
                   ' — above 80%. Ensure good air circulation.',
        timestamp: now,
        type:      'humidity',
      ),
      toAdd: toAdd,
    );

    // ── Low humidity ──────────────────────────────────────────
    _check(
      key:       'humidity_low',
      condition: sensorData.humidity < 30,
      build:     () => PlantNotification(
        id:        '${now.millisecondsSinceEpoch}_hum_low',
        title:     'Low Humidity',
        message:   'Humidity is ${sensorData.humidity.toStringAsFixed(0)}%'
                   ' — below 30%. Consider misting your plant.',
        timestamp: now,
        type:      'humidity',
      ),
      toAdd: toAdd,
    );

    if (toAdd.isNotEmpty) await _appendNotifications(toAdd);
  }

  /// Adds a one-off info notification (e.g. "Connected").
  static Future<void> addInfo(String title, String message) async {
    final n = PlantNotification(
      id:        '${DateTime.now().millisecondsSinceEpoch}_info',
      title:     title,
      message:   message,
      timestamp: DateTime.now(),
      type:      'info',
    );
    await _appendNotifications([n]);
  }

  // Only fires when a condition flips from false → true
  static void _check({
    required String key,
    required bool condition,
    required PlantNotification Function() build,
    required List<PlantNotification> toAdd,
  }) {
    final wasActive = _activeAlerts[key] ?? false;
    _activeAlerts[key] = condition;
    if (condition && !wasActive) {
      toAdd.add(build());
    }
  }

  // ── Storage ────────────────────────────────────────────────────────────────

  static Future<List<PlantNotification>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_listKey);
      if (raw == null) return [];
      final list  = jsonDecode(raw) as List;
      return list
          .map((e) => PlantNotification.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // newest first
    } catch (_) {
      return [];
    }
  }

  static Future<void> _appendNotifications(List<PlantNotification> newOnes) async {
    final prefs    = await SharedPreferences.getInstance();
    final existing = await loadAll();
    final combined = [...newOnes, ...existing];
    // Keep max _maxCount entries
    final trimmed  = combined.length > _maxCount
        ? combined.sublist(0, _maxCount)
        : combined;
    await prefs.setString(
        _listKey, jsonEncode(trimmed.map((n) => n.toJson()).toList()));
  }

  static Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list  = await loadAll();
    list.removeWhere((n) => n.id == id);
    await prefs.setString(
        _listKey, jsonEncode(list.map((n) => n.toJson()).toList()));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_listKey);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationHistoryScreen
// ─────────────────────────────────────────────────────────────────────────────
class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends State<NotificationHistoryScreen> {
  List<PlantNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await NotificationService.loadAll();
    if (mounted) setState(() { _notifications = list; _loading = false; });
  }

  Future<void> _dismiss(String id) async {
    await NotificationService.remove(id);
    setState(() => _notifications.removeWhere((n) => n.id == id));
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all notifications?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear all')),
        ],
      ),
    );
    if (confirmed != true) return;
    await NotificationService.clearAll();
    setState(() => _notifications = []);
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours   < 24) return '${diff.inHours} hr ago';
    if (diff.inDays    <  7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No notifications yet',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        'Alerts will appear here when sensor\nvalues cross your thresholds.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: Colors.green,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      return Dismissible(
                        key: Key(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _dismiss(n.id),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: n.color.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border(
                              left: BorderSide(color: n.color, width: 4),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: n.color,
                              child: Icon(n.icon, color: Colors.white, size: 20),
                            ),
                            title: Text(n.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(n.message,
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(_formatTime(n.timestamp),
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[500])),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: Icon(Icons.close,
                                  size: 16, color: Colors.grey[400]),
                              onPressed: () => _dismiss(n.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}