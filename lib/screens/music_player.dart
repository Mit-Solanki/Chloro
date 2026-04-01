import 'package:flutter/material.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  // Sample device music library
  final List<Map<String, String>> deviceMusic = [
    {'title': 'Forest Ambience', 'artist': 'Nature Sounds', 'duration': '3:45'},
    {'title': 'Rain Sounds', 'artist': 'Relaxation', 'duration': '5:20'},
    {'title': 'Bird Songs', 'artist': 'Nature', 'duration': '4:15'},
    {'title': 'Ocean Waves', 'artist': 'Ambient', 'duration': '6:00'},
    {'title': 'Morning Chirps', 'artist': 'Nature', 'duration': '3:30'},
    {'title': 'Wind Chimes', 'artist': 'Relaxation', 'duration': '4:45'},
    {'title': 'Forest Creek', 'artist': 'Nature Sounds', 'duration': '5:15'},
    {'title': 'Thunder Storm', 'artist': 'Ambient', 'duration': '7:00'},
  ];

  Set<int> selectedMusic = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Music Library'),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: deviceMusic.length,
        itemBuilder: (context, index) {
          final music = deviceMusic[index];
          final isSelected = selectedMusic.contains(index);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.green : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedMusic.add(index);
                      } else {
                        selectedMusic.remove(index);
                      }
                    });
                  },
                  activeColor: Colors.green,
                ),
                title: Text(
                  music['title']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${music['artist']} - ${music['duration']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                trailing: Icon(Icons.music_note, color: Colors.green[700]),
                onTap: () {
                  setState(() {
                    if (selectedMusic.contains(index)) {
                      selectedMusic.remove(index);
                    } else {
                      selectedMusic.add(index);
                    }
                  });
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: selectedMusic.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${selectedMusic.length} music file(s) selected and sent to speaker',
                    ),
                  ),
                );
                Navigator.pop(context);
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.check),
              label: Text('Send ${selectedMusic.length} to Speaker'),
            )
          : null,
    );
  }
}
