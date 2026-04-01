import 'package:flutter/material.dart';
import '../models.dart';

class SettingsTab extends StatefulWidget {
  final AppSettings appSettings;
  final Function(String) onDeviceNameChange;
  final Function(double) onMoistureThresholdChange;
  final Function(double) onLightThresholdChange;

  const SettingsTab({
    super.key,
    required this.appSettings,
    required this.onDeviceNameChange,
    required this.onMoistureThresholdChange,
    required this.onLightThresholdChange,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late TextEditingController _deviceNameController;

  @override
  void initState() {
    super.initState();
    _deviceNameController = TextEditingController(
      text: widget.appSettings.deviceName,
    );
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Name
          Text(
            'Device Name',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _deviceNameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Enter device name',
            ),
            onChanged: (value) {
              widget.onDeviceNameChange(
                value.isEmpty ? widget.appSettings.deviceName : value,
              );
            },
          ),
          const SizedBox(height: 24),
          // Moisture Threshold
          Text(
            'Moisture Alert Threshold (%)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: widget.appSettings.moistureThreshold,
                  min: 0,
                  max: 100,
                  onChanged: (value) {
                    widget.onMoistureThresholdChange(value);
                  },
                  activeColor: Colors.blue,
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  '${widget.appSettings.moistureThreshold.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Light Level Threshold
          Text(
            'Light Level Alert Threshold (lux)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: widget.appSettings.lightThreshold,
                  min: 0,
                  max: 10000,
                  onChanged: (value) {
                    widget.onLightThresholdChange(value);
                  },
                  activeColor: Colors.amber,
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  '${widget.appSettings.lightThreshold.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Alert Preferences
          Text(
            'Alert Preferences',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Enable Alerts'),
            value: widget.appSettings.alertsEnabled,
            onChanged: (value) {
              setState(() {
                widget.appSettings.alertsEnabled = value;
              });
            },
            activeColor: Colors.green,
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            value: widget.appSettings.pushNotificationsEnabled,
            onChanged: (value) {
              setState(() {
                widget.appSettings.pushNotificationsEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Push notifications enabled'
                        : 'Push notifications disabled',
                  ),
                ),
              );
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
