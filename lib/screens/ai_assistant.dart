import 'package:flutter/material.dart';

import '../models.dart';
import '../services/ai_advisor_service.dart';
import '../services/firebase_service.dart';
import '../widgets/ai_insight_card.dart';

class AiAssistantTab extends StatefulWidget {
  final SensorData sensorData;
  final AppSettings appSettings;

  const AiAssistantTab({
    super.key,
    required this.sensorData,
    required this.appSettings,
  });

  @override
  State<AiAssistantTab> createState() => _AiAssistantTabState();
}

class _AiAssistantTabState extends State<AiAssistantTab> {
  final _service = AiAdvisorService();
  AiAdvice? _advice;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAdvice();
  }

  Future<void> _loadAdvice({bool forceRefresh = false}) async {
    if (!_service.isConfigured) {
      setState(
        () => _error =
            'AI Assistant not configured. Run the app with --dart-define=GEMINI_API_KEY=your_key.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await FirebaseService.instance.getHistoryReadings(
        'soil_percent',
      );
      final points = raw
          .where(
            (item) => item['soil_percent'] is num && item['timestamp'] != null,
          )
          .map((item) {
            final timestamp = item['timestamp'];
            final numericTimestamp = (timestamp as num).toInt();
            final date = DateTime.fromMillisecondsSinceEpoch(
              numericTimestamp * (numericTimestamp < 100000000000 ? 1000 : 1),
            );
            return HistoryDataPoint(
              timestamp: date,
              value: (item['soil_percent'] as num).toDouble(),
            );
          })
          .toList();
      final result = await _service.getFullAdvice(
        widget.sensorData,
        widget.appSettings,
        summarizeTrend(points),
        forceRefresh: forceRefresh,
      );
      if (mounted)
        setState(() {
          _advice = result;
          _loading = false;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Plant Care',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Short advice based on your live readings and recent soil trend.',
          ),
          const SizedBox(height: 20),
          AiInsightCard(
            advice: _advice,
            isLoading: _loading,
            error: _error,
            onRetry: _loadAdvice,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loading
                  ? null
                  : () => _loadAdvice(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh advice'),
            ),
          ),
        ],
      ),
    );
  }
}
