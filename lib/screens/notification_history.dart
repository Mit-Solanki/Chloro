import 'package:flutter/material.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  List<Map<String, dynamic>> notifications = [
    {
      'title': 'Low Moisture Level',
      'message': 'Soil moisture is below threshold. Please water your plant.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'type': 'water',
      'icon': Icons.opacity,
      'color': Colors.blue,
    },
    {
      'title': 'Low Light Intensity',
      'message':
          'Light level is insufficient. Move plant to brighter location.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'type': 'light',
      'icon': Icons.light_mode,
      'color': Colors.orange,
    },
    {
      'title': 'Connected Successfully',
      'message': 'Device connected to Smart Plant Pot system.',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'type': 'info',
      'icon': Icons.cloud_done,
      'color': Colors.green,
    },
    {
      'title': 'Temperature Alert',
      'message': 'Room temperature is above optimal range.',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'type': 'temperature',
      'icon': Icons.thermostat,
      'color': Colors.red,
    },
    {
      'title': 'System Updated',
      'message': 'App has been updated to the latest version.',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'type': 'info',
      'icon': Icons.system_update,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification History'),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final notificationColor = notification['color'] as Color;

          return Dismissible(
            key: Key(index.toString()),
            onDismissed: (direction) {
              setState(() {
                notifications.removeAt(index);
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: notificationColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: notificationColor, width: 4),
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: notificationColor,
                  child: Icon(notification['icon'], color: Colors.white),
                ),
                title: Text(
                  notification['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notification['message']),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notification['timestamp']),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return dateTime.toString().split(' ')[0];
    }
  }
}
