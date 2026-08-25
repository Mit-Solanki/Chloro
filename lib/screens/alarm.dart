import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/esp32_music_service.dart';
import 'music_player.dart';

// ── AlarmModel ──────────────────────────────────────────────────────────────
class AlarmModel {
  final String id;
  final int hour, minute;
  final Set<String> days;
  final String track;
  final bool light;
  bool enabled;

  AlarmModel({required this.id, required this.hour, required this.minute,
    required this.days, required this.track, required this.light, this.enabled = true});

  Map<String, dynamic> toJson() => {
    'id': id, 'hour': hour, 'minute': minute,
    'days': days.toList(), 'track': track, 'light': light, 'enabled': enabled,
  };

  factory AlarmModel.fromJson(Map<String, dynamic> j) => AlarmModel(
    id: j['id'] as String, hour: j['hour'] as int, minute: j['minute'] as int,
    days: Set<String>.from((j['days'] as List).cast<String>()),
    track: j['track'] as String, light: j['light'] as bool, enabled: j['enabled'] as bool,
  );

  String get timeLabel {
    return '${hour.toString().padLeft(2,'0')}:${minute.toString().padLeft(2,'0')}';
  }

  String get daysLabel {
    const order = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const map = {'Monday':'Mon','Tuesday':'Tue','Wednesday':'Wed',
      'Thursday':'Thu','Friday':'Fri','Saturday':'Sat','Sunday':'Sun'};
    return order.where((s) => days.any((d) => map[d] == s)).join(' · ');
  }
}

// ── AlarmScheduler ───────────────────────────────────────────────────────────
class AlarmScheduler {
  static Timer? _timer;
  static OverlayState? _overlayState;
  static OverlayEntry? _overlayEntry;
  static const _key = 'saved_alarms_v4';

  static void init({OverlayState? overlay}) {
    _overlayState = overlay;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  static void updateOverlay(OverlayState overlay) => _overlayState = overlay;

  static Future<void> _check() async {
    final alarms = await loadAlarms();
    if (alarms.isEmpty) return;
    final now = DateTime.now();
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final today = days[now.weekday - 1];
    for (final a in alarms) {
      if (!a.enabled || !a.days.contains(today)) continue;
      if (now.hour == a.hour && now.minute == a.minute) await _trigger(a);
    }
  }

  static Future<void> _trigger(AlarmModel alarm) async {
    debugPrint('[Alarm] Triggering ${alarm.track}');
    try {
      await http.post(Uri.parse(
          'http://$esp32Ip/play?f=${Uri.encodeQueryComponent(alarm.track)}'))
          .timeout(const Duration(seconds: 5));
    } catch (e) { debugPrint('[Alarm] play error: $e'); }
    if (alarm.light) {
      try { await http.post(Uri.parse('http://$esp32Ip/led?state=on'))
          .timeout(const Duration(seconds: 5)); } catch (_) {}
    }
    _showBanner(alarm);
  }

  static void _showBanner(AlarmModel alarm) {
    if (_overlayState == null) return;
    _dismissBanner();
    _overlayEntry = OverlayEntry(builder: (_) => _AlarmBanner(
      alarm: alarm,
      onDismiss: _dismissBanner,
      onStop: () async {
        _dismissBanner();
        try { await http.post(Uri.parse('http://$esp32Ip/stop'))
            .timeout(const Duration(seconds: 5)); } catch (_) {}
      },
    ));
    _overlayState!.insert(_overlayEntry!);
  }

  static void _dismissBanner() { _overlayEntry?.remove(); _overlayEntry = null; }

  static Future<void> saveAlarms(List<AlarmModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list.map((a) => a.toJson()).toList()));
  }

  static Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String,dynamic>>().map(AlarmModel.fromJson).toList();
  }
}

// ── Overlay banner ────────────────────────────────────────────────────────────
class _AlarmBanner extends StatelessWidget {
  const _AlarmBanner({required this.alarm, required this.onDismiss, required this.onStop});
  final AlarmModel alarm;
  final VoidCallback onDismiss, onStop;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Material(
        elevation: 12, color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.3),
                  blurRadius: 16, spreadRadius: 2)],
            ),
            child: Row(children: [
              const _RingingBell(),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, children: [
                  Text('⏰  Alarm — ${alarm.timeLabel}',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(alarm.track,
                      style: TextStyle(color: Colors.green[200], fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ])),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onStop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Stop', style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RingingBell extends StatefulWidget {
  const _RingingBell();
  @override State<_RingingBell> createState() => _RingingBellState();
}
class _RingingBellState extends State<_RingingBell> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))
        ..repeat(reverse: true);
    _anim = Tween<double>(begin: -0.2, end: 0.2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, child) => Transform.rotate(angle: _anim.value, child: child),
    child: const Icon(Icons.alarm, color: Colors.greenAccent, size: 30),
  );
}

// ── AlarmScreen ───────────────────────────────────────────────────────────────
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});
  @override State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<AlarmModel> _alarms       = [];
  List<String>     _musicOptions = [];
  bool             _loadingTracks = true;

  final List<String> _allDays = [
    'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadTracks();
    _loadAlarms();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AlarmScheduler.updateOverlay(Overlay.of(context));
    });
  }

  Future<void> _loadAlarms() async {
    final a = await AlarmScheduler.loadAlarms();
    if (mounted) setState(() => _alarms = a);
  }

  Future<void> _loadTracks() async {
    final cached = await Esp32MusicService.getCachedTracks();
    if (mounted && cached.isNotEmpty) setState(() { _musicOptions = cached; _loadingTracks = false; });
    try {
      final live = await Esp32MusicService(ip: esp32Ip).listTracks();
      if (mounted && live.isNotEmpty) setState(() { _musicOptions = live; _loadingTracks = false; });
    } catch (_) { if (mounted) setState(() => _loadingTracks = false); }
  }

  Future<void> _save() => AlarmScheduler.saveAlarms(_alarms);

  Future<void> _toggle(int i) async {
    setState(() => _alarms[i].enabled = !_alarms[i].enabled);
    await _save();
  }

  Future<void> _delete(int i) async {
    setState(() => _alarms.removeAt(i));
    await _save();
  }

  Future<void> _openDialog({AlarmModel? ex}) async {
    TimeOfDay time     = ex != null ? TimeOfDay(hour: ex.hour, minute: ex.minute) : TimeOfDay.now();
    Set<String> days   = ex?.days.toSet() ?? {'Monday'};
    String? track      = ex?.track ?? (_musicOptions.isNotEmpty ? _musicOptions.first : null);
    bool light         = ex?.light ?? false;

    final ok = await showDialog<bool>(
      context: context, barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, sd) => AlertDialog(
        backgroundColor: const Color(0xFF1A2A20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(ex == null ? '➕  New Alarm' : '✏️  Edit Alarm',
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time
            const Text('Time', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final p = await showTimePicker(context: ctx, initialTime: time);
                if (p != null) sd(() => time = p);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(time.format(ctx),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            ),
            const SizedBox(height: 16),
            // Days
            const Text('Repeat on', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: _allDays.map((d) {
                final sel = days.contains(d);
                return GestureDetector(
                  onTap: () => sd(() {
                    if (sel) { if (days.length > 1) days.remove(d); }
                    else days.add(d);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? Colors.green[700] : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? Colors.greenAccent : Colors.white24),
                    ),
                    child: Text(d.substring(0,3), style: TextStyle(
                      color: sel ? Colors.white : Colors.white60,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Ringtone
            const Text('Ringtone', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            if (_loadingTracks)
              const Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)))
            else if (_musicOptions.isEmpty)
              const Text('No tracks on ESP32.\nUpload MP3s in Music Player.',
                  style: TextStyle(color: Colors.white38, fontSize: 12))
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<String>(
                  value: track, isExpanded: true, underline: const SizedBox(),
                  dropdownColor: const Color(0xFF1A2A20),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => sd(() => track = v),
                  items: _musicOptions.map((m) =>
                      DropdownMenuItem(value: m, child: Text(m))).toList(),
                ),
              ),
            const SizedBox(height: 12),
            // Light
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Turn on LED', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Switch(value: light, onChanged: (v) => sd(() => light = v), activeColor: Colors.green),
            ]),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: track == null ? null : () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
            child: Text(ex == null ? 'Add' : 'Save', style: const TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );

    if (ok != true || track == null) return;
    final alarm = AlarmModel(
      id: ex?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      hour: time.hour, minute: time.minute,
      days: days, track: track!, light: light,
    );
    setState(() {
      if (ex != null) {
        final i = _alarms.indexWhere((a) => a.id == ex.id);
        if (i >= 0) _alarms[i] = alarm; else _alarms.add(alarm);
      } else {
        _alarms.add(alarm);
      }
    });
    await _save();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ Alarm set for ${alarm.timeLabel}  (${alarm.daysLabel})'),
      backgroundColor: Colors.green[700],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text('⏰  Alarms', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A3A2A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _alarms.isEmpty ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: _alarms.length,
              itemBuilder: (_, i) => _buildCard(_alarms[i], i),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add_alarm, color: Colors.white),
        label: const Text('Add Alarm', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCard(AlarmModel a, int i) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: a.enabled ? Colors.green.withOpacity(0.5) : Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.timeLabel, style: TextStyle(
              color: a.enabled ? Colors.white : Colors.white38,
              fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 1.5,
            )),
            const SizedBox(height: 2),
            Text(a.daysLabel.isEmpty ? 'No days' : a.daysLabel,
                style: TextStyle(color: a.enabled ? Colors.green[300] : Colors.white24, fontSize: 12)),
            const SizedBox(height: 2),
            Text('🎵 ${a.track}',
                style: TextStyle(color: a.enabled ? Colors.white54 : Colors.white24, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ])),
          Switch(value: a.enabled, onChanged: (_) => _toggle(i), activeColor: Colors.green),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 20),
            onPressed: () => _openDialog(ex: a),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1A2A20),
                  title: const Text('Delete alarm?', style: TextStyle(color: Colors.white)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                    TextButton(onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true) await _delete(i);
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.alarm_off, color: Colors.white24, size: 72),
      const SizedBox(height: 16),
      const Text('No alarms set', style: TextStyle(color: Colors.white38, fontSize: 18)),
      const SizedBox(height: 8),
      const Text('Tap + Add Alarm to get started',
          style: TextStyle(color: Colors.white24, fontSize: 13)),
    ],
  ));
}