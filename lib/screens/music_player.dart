import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/esp32_music_service.dart';

String esp32Ip = '10.121.131.241';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});
  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late Esp32MusicService _svc;

  List<String> _tracks       = [];
  String       _currentTrack = '';
  bool         _isPlaying    = false;
  double       _volume       = 100;

  int _positionSec = 0;
  int _durationSec = 0;
  Timer? _progressTimer;

  bool   _cacheLoaded = false;
  bool   _liveLoaded  = false;
  bool   _esp32Online = false;
  String? _error;

  double? _uploadProgress;
  String  _uploadName = '';

  @override
  void initState() {
    super.initState();
    _svc = Esp32MusicService(ip: esp32Ip);
    _loadCacheThenRefresh();
  }

  @override
  void dispose() { _progressTimer?.cancel(); super.dispose(); }

  Future<void> _loadCacheThenRefresh() async {
    final cached = await Esp32MusicService.getCachedTracks();
    if (mounted) setState(() { _tracks = cached; _cacheLoaded = true; });
    await _refreshFromDevice();
  }

  Future<void> _refreshFromDevice() async {
    try {
      final results = await Future.wait([_svc.listTracks(), _svc.getStatus()]);
      final tracks = results[0] as List<String>;
      final status = results[1] as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _tracks       = tracks;
          _currentTrack = (status['track'] as String).replaceAll('/', '');
          _isPlaying    = status['playing'] as bool;
          _volume       = (status['volume'] as num).toDouble().clamp(1.0, 100.0);
          _esp32Online  = true;
          _liveLoaded   = true;
          _error        = null;
        });
        if (_isPlaying) _startProgressPolling();
      }
    } catch (e) {
      if (mounted) setState(() {
        _esp32Online = false; _liveLoaded = true;
        _error = _tracks.isEmpty ? e.toString().replaceFirst('Exception: ', '') : null;
      });
    }
  }

  void _startProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_isPlaying) { _progressTimer?.cancel(); return; }
      try {
        final p = await _svc.getProgress();
        if (!mounted) return;
        setState(() {
          _positionSec = (p['position_sec'] as num?)?.toInt() ?? _positionSec;
          _durationSec = (p['duration_sec'] as num?)?.toInt() ?? _durationSec;
          final still = p['playing'] as bool? ?? true;
          if (!still) {
            _isPlaying = false; _currentTrack = '';
            _positionSec = 0; _durationSec = 0;
            _progressTimer?.cancel();
          }
        });
      } catch (_) {}
    });
  }

  void _stopProgressPolling() {
    _progressTimer?.cancel();
    setState(() { _positionSec = 0; _durationSec = 0; });
  }

  Future<void> _playTrack(String f) async {
    try {
      await _svc.play(f);
      setState(() { _currentTrack = f; _isPlaying = true; _positionSec = 0; _durationSec = 0; });
      _startProgressPolling();
    } catch (e) { _showErr('Play failed: $e'); }
  }

  Future<void> _togglePause() async {
    await _svc.pauseResume();
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) { _startProgressPolling(); } else { _progressTimer?.cancel(); }
  }

  Future<void> _stop() async {
    await _svc.stop();
    setState(() { _isPlaying = false; _currentTrack = ''; });
    _stopProgressPolling();
  }

  Future<void> _setVolume(double v) async {
    setState(() => _volume = v);
    await _svc.setVolume(v.round());
  }

  Future<void> _deleteTrack(String f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete track?'),
        content: Text('Remove "$f" from ESP32 SD card?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (_currentTrack == f) await _stop();
      await _svc.deleteTrack(f);
      await _refreshFromDevice();
    } catch (e) { _showErr('Delete failed: $e'); }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['mp3']);
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    final filename = result.files.single.name;
    setState(() { _uploadProgress = 0; _uploadName = filename; });
    try {
      await _svc.uploadMp3(file, onProgress: (p) => setState(() => _uploadProgress = p));
      setState(() => _uploadProgress = null);
      await _refreshFromDevice();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ $filename uploaded'), backgroundColor: Colors.green[700]));
    } catch (e) {
      setState(() => _uploadProgress = null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Upload failed: $e'), backgroundColor: Colors.red[700]));
    }
  }

  void _showErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red[700]));
  }

  String _fmt(int s) {
    final m = s ~/ 60; final sec = s % 60;
    return '${m.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_cacheLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F2027),
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text('🌿 Chloro Music', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A3A2A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_liveLoaded)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(_esp32Online ? 'Live' : 'Cached',
                    style: const TextStyle(fontSize: 11, color: Colors.white)),
                backgroundColor: _esp32Online ? Colors.green[700] : Colors.grey[700],
                padding: EdgeInsets.zero,
              ),
            ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _refreshFromDevice),
        ],
      ),
      body: Column(children: [
        if (_liveLoaded && !_esp32Online && _tracks.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange[900],
            child: const Row(children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 16), SizedBox(width: 8),
              Expanded(child: Text('ESP32 offline — showing cached track list',
                  style: TextStyle(color: Colors.white, fontSize: 12))),
            ]),
          ),
        _buildNowPlaying(),
        _buildProgressBar(),
        _buildControls(),
        if (_uploadProgress != null) _buildUploadProgress(),
        const Divider(color: Colors.white24, height: 1),
        if (_error != null && _tracks.isEmpty) _buildError()
        else Expanded(child: _buildTrackList()),
      ]),
      floatingActionButton: _uploadProgress == null
          ? FloatingActionButton.extended(
              onPressed: _pickAndUpload,
              backgroundColor: Colors.green[700],
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text('Upload MP3', style: TextStyle(color: Colors.white)))
          : null,
    );
  }

  Widget _buildNowPlaying() {
    final name = _currentTrack.isEmpty ? 'Nothing playing' : _currentTrack;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[900]!, Colors.green[700]!],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0,4))],
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(_isPlaying ? Icons.music_note : Icons.music_off, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isPlaying ? 'Now Playing' : 'Stopped',
              style: TextStyle(color: Colors.green[100], fontSize: 12)),
          const SizedBox(height: 4),
          Text(name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _buildProgressBar() {
    final hasDur = _durationSec > 0;
    final progress = hasDur ? (_positionSec / _durationSec).clamp(0.0, 1.0) : 0.0;
    final remaining = hasDur ? (_durationSec - _positionSec).clamp(0, _durationSec) : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: hasDur ? progress : null,
            backgroundColor: Colors.white12,
            color: Colors.green,
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_currentTrack.isEmpty ? '--:--' : _fmt(_positionSec),
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          if (hasDur)
            Text('-${_fmt(remaining)}',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Text(hasDur ? _fmt(_durationSec) : '--:--',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: _currentTrack.isEmpty ? null : _stop,
              icon: const Icon(Icons.stop_circle_outlined), color: Colors.white70, iconSize: 40),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _currentTrack.isEmpty ? null : _togglePause,
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: _currentTrack.isEmpty ? Colors.grey[700] : Colors.green[600],
                shape: BoxShape.circle,
              ),
              child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(onPressed: _refreshFromDevice,
              icon: const Icon(Icons.sync), color: Colors.white70, iconSize: 40),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.volume_mute, color: Colors.white54, size: 20),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.green,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.green[300],
              ),
              child: Slider(
                value: _volume, min: 1, max: 100, divisions: 99,
                onChanged: _setVolume,
              ),
            ),
          ),
          const Icon(Icons.volume_up, color: Colors.white54, size: 20),
          SizedBox(
            width: 44,
            child: Text('${_volume.round()}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.right),
          ),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildUploadProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Uploading $_uploadName…', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: _uploadProgress, backgroundColor: Colors.white24,
            color: Colors.green, minHeight: 6, borderRadius: BorderRadius.circular(4)),
        const SizedBox(height: 4),
        Text('${((_uploadProgress ?? 0) * 100).round()}%',
            style: const TextStyle(color: Colors.green, fontSize: 12)),
      ]),
    );
  }

  Widget _buildTrackList() {
    if (_tracks.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.library_music_outlined, color: Colors.white24, size: 64),
        const SizedBox(height: 12),
        const Text('No MP3s on SD card', style: TextStyle(color: Colors.white38)),
        const SizedBox(height: 8),
        const Text('Upload an MP3 to get started',
            style: TextStyle(color: Colors.white24, fontSize: 12)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      itemCount: _tracks.length,
      itemBuilder: (_, i) {
        final track = _tracks[i];
        final isActive = _currentTrack == track;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withOpacity(0.15) : const Color(0xFF1A2A20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? Colors.green : Colors.white10, width: isActive ? 1.5 : 1),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? Colors.green[700] : Colors.white10,
              child: Icon(isActive && _isPlaying ? Icons.equalizer : Icons.music_note,
                  color: isActive ? Colors.white : Colors.white54, size: 18),
            ),
            title: Text(track, style: TextStyle(
              color: isActive ? Colors.green[200] : Colors.white,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            )),
            onTap: _esp32Online ? () => _playTrack(track) : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
              onPressed: _esp32Online ? () => _deleteTrack(track) : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Expanded(child: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off, color: Colors.red, size: 64),
        const SizedBox(height: 16),
        const Text('Cannot reach ESP32',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_error ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Text('ESP32 IP: $esp32Ip\nMake sure both devices are on the same WiFi',
            style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: _refreshFromDevice,
            icon: const Icon(Icons.refresh), label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700])),
      ]),
    )));
  }
}