import 'package:flutter/material.dart';
import 'dart:math' as Math;
import '../models.dart';

class LEDControlTab extends StatefulWidget {
  final LEDSettings ledSettings;
  final Function(bool) onLEDToggle;
  final Function(double) onBrightnessChange;
  final Function(Color) onColorChange;

  const LEDControlTab({
    super.key,
    required this.ledSettings,
    required this.onLEDToggle,
    required this.onBrightnessChange,
    required this.onColorChange,
  });

  @override
  State<LEDControlTab> createState() => _LEDControlTabState();
}

class _LEDControlTabState extends State<LEDControlTab> {
  bool _showBrightnessMenu = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          // Main LED Control Circle
          Center(
            child: GestureDetector(
              onTap: () {
                widget.onLEDToggle(!widget.ledSettings.isOn);
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: widget.ledSettings.isOn
                      ? const Color(0xFFFFFF45).withOpacity(0.15)
                      : const Color(0xFF333333).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.ledSettings.isOn
                        ? const Color(0xFFFFFF45)
                        : const Color(0xFF333333),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.ledSettings.isOn
                          ? const Color(0xFFFFFF45).withOpacity(0.5)
                          : Colors.grey.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lightbulb,
                      size: 100,
                      color: widget.ledSettings.isOn
                          ? const Color(0xFFFFFF45)
                          : const Color(0xFF333333),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.ledSettings.isOn ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.ledSettings.isOn
                            ? const Color(0xFFFFFF45)
                            : const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),

          // Brightness Control Button
          Center(
            child: GestureDetector(
              onTap: widget.ledSettings.isOn
                  ? () {
                      setState(() {
                        _showBrightnessMenu = !_showBrightnessMenu;
                      });
                    }
                  : null,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.brightness_4,
                      size: 48,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.ledSettings.brightness.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Brightness',
                      style: TextStyle(fontSize: 12, color: Colors.amber[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Brightness Slider Popup
          if (_showBrightnessMenu)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Brightness Control',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.brightness_low, color: Colors.amber),
                        Expanded(
                          child: Slider(
                            value: widget.ledSettings.brightness,
                            min: 0,
                            max: 100,
                            onChanged: (value) {
                              widget.onBrightnessChange(value);
                            },
                            activeColor: Colors.amber,
                          ),
                        ),
                        const Icon(Icons.brightness_high, color: Colors.amber),
                      ],
                    ),
                    Text(
                      '${widget.ledSettings.brightness.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Color Wheel Popup removed - only brightness control available now
        ],
      ),
    );
  }
}
