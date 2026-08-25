// lib/screens/speaker_control.dart
//
// Speaker tab in the main Home screen.
// Quick controls + opens the full MusicPlayerScreen.
// Volume / play-pause are kept here for convenience so the user
// doesn't have to navigate away for basic controls.

import 'package:flutter/material.dart';
import '../models.dart';
import '../services/esp32_music_service.dart';
import 'music_player.dart';

class SpeakerControlTab extends StatefulWidget {
  final SpeakerSettings speakerSettings;
  final Function(bool)   onPlayPauseToggle;
  final Function(String) onTrackChange;
  final Function(double) onVolumeChange;

  const SpeakerControlTab({
    super.key,
    required this.speakerSettings,
    required this.onPlayPauseToggle,
    required this.onTrackChange,
    required this.onVolumeChange,
  });

  @override
  State<SpeakerControlTab> createState() => _SpeakerControlTabState();
}

class _SpeakerControlTabState extends State<SpeakerControlTab> {
  late Esp32MusicService _svc;

  @override
  void initState() {
    super.initState();
    _svc = Esp32MusicService(ip: esp32Ip);
    _syncStatus();
  }

  /// Sync real ESP32 status into the parent's SpeakerSettings model.
  Future<void> _syncStatus() async {
    try {
      final status = await _svc.getStatus();
      widget.onPlayPauseToggle(status['playing'] as bool);
      if ((status['track'] as String).isNotEmpty) {
        widget.onTrackChange(status['track'] as String);
      }
      widget.onVolumeChange((status['volume'] as num).toDouble());
    } catch (_) {
      // ESP32 might not be reachable yet — silent fail
    }
  }

  Future<void> _togglePlay() async {
    try {
      if (widget.speakerSettings.isPlaying) {
        await _svc.pauseResume();
        widget.onPlayPauseToggle(false);
      } else {
        // If there's a current track resume it, otherwise open full player
        if (widget.speakerSettings.selectedTrack.isNotEmpty &&
            widget.speakerSettings.selectedTrack != 'Forest Ambience') {
          await _svc.pauseResume();
          widget.onPlayPauseToggle(true);
        } else {
          _openPlayer();
        }
      }
    } catch (e) {
      _showErr('ESP32 not reachable');
    }
  }

  void _openPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MusicPlayerScreen()),
    ).then((_) => _syncStatus()); // refresh after returning
  }

  void _showErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = widget.speakerSettings;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Now Playing card ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[300]!, width: 2),
            ),
            child: Column(
              children: [
                Icon(
                  sp.isPlaying ? Icons.equalizer : Icons.music_note,
                  size: 64,
                  color: Colors.blue[700],
                ),
                const SizedBox(height: 16),
                Text(
                  'Now Playing',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  sp.selectedTrack.isEmpty ? 'Nothing selected' : sp.selectedTrack,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Play / Pause ────────────────────────────────────────────────
          SizedBox(
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _togglePlay,
              icon: Icon(
                sp.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
              label: Text(
                sp.isPlaying ? 'Pause' : 'Play',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: sp.isPlaying ? Colors.orange[700] : Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Open full music player ──────────────────────────────────────
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _openPlayer,
              icon: const Icon(Icons.library_music),
              label: const Text('Manage Music on ESP32'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Volume ──────────────────────────────────────────────────────
          Text(
            'Volume',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.volume_mute),
              Expanded(
                child: Slider(
                  value: sp.volume,
                  min: 0,
                  max: 100,
                  activeColor: Colors.blue,
                  onChanged: (v) => widget.onVolumeChange(v),
                  onChangeEnd: (v) async {
                    try {
                      await _svc.setVolume(v.round());
                    } catch (_) {}
                  },
                ),
              ),
              const Icon(Icons.volume_up),
              SizedBox(
                width: 48,
                child: Text(
                  '${sp.volume.round()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── ESP32 IP hint ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.router, color: Colors.grey[600], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ESP32 IP: $esp32Ip\n(Change in Settings)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}