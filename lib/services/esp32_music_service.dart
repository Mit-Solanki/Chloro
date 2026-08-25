import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Esp32MusicService {
  String ip;
  static const _cacheKey = 'esp32_track_list';
  Esp32MusicService({required this.ip});
  Uri _url(String p) => Uri.parse('http://$ip$p');

  static Future<List<String>> getCachedTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> _saveCache(List<String> t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(t));
  }

  Future<List<String>> listTracks() async {
    try {
      final res = await http.get(_url('/list')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final t = (jsonDecode(res.body) as List).cast<String>();
        await _saveCache(t); return t;
      }
    } catch (e) { throw Exception('Cannot reach ESP32 at $ip — check WiFi & IP'); }
    return [];
  }

  Future<void> play(String f) async {
    final res = await http.post(_url('/play?f=${Uri.encodeQueryComponent(f)}'))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) throw Exception(jsonDecode(res.body)['error'] ?? 'Play failed');
  }

  Future<void> pauseResume() async =>
      http.post(_url('/pause')).timeout(const Duration(seconds: 5));

  Future<void> stop() async =>
      http.post(_url('/stop')).timeout(const Duration(seconds: 5));

  /// volume = 1-100 (Flutter). ESP32 maps to 0-15 hardware scale.
  Future<void> setVolume(int volume) async =>
      http.post(_url('/volume?v=${volume.clamp(1,100)}'))
          .timeout(const Duration(seconds: 5));

  /// Returns { playing, volume (0-100), track }
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final res = await http.get(_url('/status')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return {'playing': false, 'volume': 100, 'track': ''};
  }

  /// Returns { position_sec, duration_sec, playing, track }
  Future<Map<String, dynamic>> getProgress() async {
    try {
      final res = await http.get(_url('/progress')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return {'position_sec': 0, 'duration_sec': 0, 'playing': false, 'track': ''};
  }

  Future<bool> isReachable() async {
    try {
      final res = await http.get(_url('/status')).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<void> deleteTrack(String f) async {
    final req = http.Request('DELETE', _url('/delete?f=${Uri.encodeQueryComponent(f)}'));
    final client = http.Client();
    try {
      final s = await client.send(req).timeout(const Duration(seconds: 5));
      if (s.statusCode != 200) throw Exception('Delete failed');
    } finally { client.close(); }
  }

  Future<void> uploadMp3(File file, {void Function(double)? onProgress}) async {
    final filename = file.path.split('/').last;
    final fileSize = await file.length();
    final client = http.Client();
    try {
      final request = http.MultipartRequest('POST', _url('/upload'));
      if (onProgress != null && fileSize > 0) {
        int sent = 0;
        final stream = file.openRead().map((c) { sent += c.length; onProgress(sent/fileSize); return c; });
        request.files.add(http.MultipartFile('data', stream, fileSize, filename: filename));
      } else {
        request.files.add(await http.MultipartFile.fromPath('data', file.path, filename: filename));
      }
      final s = await client.send(request).timeout(Duration(seconds: (fileSize/10000).ceil()+30));
      await s.stream.drain<void>();
      if (s.statusCode != 200) throw Exception('Upload failed: HTTP ${s.statusCode}');
      await listTracks();
    } finally { client.close(); }
  }
}