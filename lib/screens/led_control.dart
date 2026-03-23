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
  bool _showColorMenu = false;

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
                      ? widget.ledSettings.color.withOpacity(0.3)
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.ledSettings.isOn
                        ? widget.ledSettings.color
                        : Colors.grey,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.ledSettings.isOn
                          ? widget.ledSettings.color.withOpacity(0.4)
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
                          ? widget.ledSettings.color
                          : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.ledSettings.isOn ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.ledSettings.isOn
                            ? widget.ledSettings.color
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),

          // Brightness and Color Control Circles Below
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Brightness Control
              GestureDetector(
                onTap: widget.ledSettings.isOn
                    ? () {
                        setState(() {
                          _showBrightnessMenu = !_showBrightnessMenu;
                          _showColorMenu = false;
                        });
                      }
                    : null,
                child: Container(
                  width: 120,
                  height: 120,
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
                        size: 40,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.ledSettings.brightness.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Brightness',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
              // Color Control
              GestureDetector(
                onTap: widget.ledSettings.isOn
                    ? () {
                        setState(() {
                          _showColorMenu = !_showColorMenu;
                          _showBrightnessMenu = false;
                        });
                      }
                    : null,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: widget.ledSettings.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.ledSettings.color,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.ledSettings.color.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.palette,
                        size: 40,
                        color: widget.ledSettings.color,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 30,
                        height: 20,
                        decoration: BoxDecoration(
                          color: widget.ledSettings.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Color',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

          // Color Wheel Popup
          if (_showColorMenu)
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Select Color',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.ledSettings.color,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildColorWheel(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorWheel() {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer gradient circle (full saturation)
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.cyan,
                  Colors.blue,
                  Colors.purple,
                  Colors.red,
                ],
                stops: const [0.0, 0.15, 0.3, 0.45, 0.6, 0.75, 0.9, 1.0],
              ),
            ),
          ),
          // Inner radial gradient for saturation variation (lighter towards center)
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white.withOpacity(0.7), Colors.transparent],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          // Center circle for current color
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: widget.ledSettings.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: widget.ledSettings.color.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.palette, size: 40, color: Colors.white),
                const SizedBox(height: 4),
                const Text(
                  'Selected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Clickable color wheel
          GestureDetector(
            onTapDown: (details) {
              _selectColorFromWheel(details.localPosition);
            },
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }

  void _selectColorFromWheel(Offset position) {
    final centerX = 130.0;
    final centerY = 130.0;
    final dx = position.dx - centerX;
    final dy = position.dy - centerY;
    final distance = Math.sqrt(dx * dx + dy * dy);

    // Allow selection from edge to center for saturation variation
    if (distance < 130 && distance > 5) {
      // Calculate hue from angle (0-360)
      final angle = (Math.atan2(dy, dx) * 180 / Math.pi + 180) % 360;

      // Calculate saturation from distance (0-1)
      // Outer edge = full saturation, inner = less saturation (lighter)
      final saturation = (distance / 130).clamp(0.3, 1.0);

      // Value (brightness) based on distance from center
      // Outer = brighter, inner = lighter but still visible
      final brightness = 1.0;

      // Convert HSV to RGB Color
      final color = HSVColor.fromAHSV(
        1.0,
        angle,
        saturation,
        brightness,
      ).toColor();

      widget.onColorChange(color);
    }
  }
}
