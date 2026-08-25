import 'package:flutter/material.dart';

import '../models.dart';
import '../services/ai_advisor_service.dart';
import 'ai_insight_card.dart';

class MetricExplanation extends StatefulWidget {
  final String name;
  final double value;
  final String unit;

  const MetricExplanation({
    super.key,
    required this.name,
    required this.value,
    required this.unit,
  });

  @override
  State<MetricExplanation> createState() => _MetricExplanationState();
}

class _MetricExplanationState extends State<MetricExplanation> {
  final _service = AiAdvisorService();
  AiAdvice? _advice;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final advice = await _service.explainMetric(
        widget.name,
        widget.value,
        widget.unit,
        'current reading',
      );
      if (mounted)
        setState(() {
          _advice = advice;
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Explain ${widget.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AiInsightCard(
              advice: _advice,
              isLoading: _loading,
              error: _error,
              onRetry: _load,
            ),
          ],
        ),
      ),
    );
  }
}
