import 'package:flutter/material.dart';
import '../models.dart';
import 'music_player.dart';

class SpeakerControlTab extends StatefulWidget {
  final SpeakerSettings speakerSettings;
  final Function(bool) onPlayPauseToggle;
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
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Now Playing Card
          Container(
            width: 5000,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[300]!, width: 2),
            ),
            // crossAxisAlignment: CrossAxisAlignment.center,
            child: Column(
              children: [
                Icon(Icons.music_note, size: 64, color: Colors.blue[700]),
                const SizedBox(height: 16),
                Text(
                  'Now Playing',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.speakerSettings.selectedTrack,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Play/Pause Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                widget.onPlayPauseToggle(!widget.speakerSettings.isPlaying);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.speakerSettings.isPlaying
                    ? Colors.red
                    : Colors.green,
              ),
              child: Icon(
                widget.speakerSettings.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Device Music Library Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MusicPlayerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.library_music),
              label: const Text('Browse Device Music'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Track Selection
          Text(
            'Select Track',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: widget.speakerSettings.selectedTrack,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  widget.onTrackChange(newValue);
                }
              },
              items: predefinedTracks.map<DropdownMenuItem<String>>((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Volume Control
          Text(
            'Volume',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.volume_mute),
              Expanded(
                child: Slider(
                  value: widget.speakerSettings.volume,
                  min: 0,
                  max: 100,
                  onChanged: (value) {
                    widget.onVolumeChange(value);
                  },
                  activeColor: Colors.blue,
                ),
              ),
              const Icon(Icons.volume_up),
              SizedBox(
                width: 50,
                child: Text(
                  '${widget.speakerSettings.volume.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
