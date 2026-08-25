import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';

class AiAdvisorException implements Exception {
  final String message;
  final bool isRateLimited;

  const AiAdvisorException(this.message, {this.isRateLimited = false});

  @override
  String toString() => message;
}

class AiAdvisorService {
  static const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  static const _fullSystemPrompt =
      '''You are Chloro's plant care advisor. You receive live sensor readings from a smart plant pot (soil moisture %, temperature °C, humidity %, light level) and must give short, practical care advice.

Rules:
- Base advice ONLY on the data given. Never invent readings.
- If a value is missing, say so instead of guessing.
- Keep "advice" under 40 words.
- Classify "status" as exactly one of: "Healthy", "Needs Water", "Too Dry", "Too Wet", "Low Light", "Too Hot", "Too Cold".
- Respond ONLY with valid JSON matching this schema, nothing else, no markdown fences:
{"status": string, "headline": string, "advice": string, "confidence": "low" | "medium" | "high"}''';
  static const _metricSystemPrompt =
      '''You are Chloro's plant care advisor. You are given ONE sensor reading and must explain what it means for the plant in plain language.

Rules:
- Keep "advice" under 30 words.
- Respond ONLY with valid JSON, no markdown fences:
{"headline": string, "advice": string}''';

  AiAdvice? _cachedAdvice;
  DateTime? _cachedAt;
  SensorData? _cachedData;

  bool get isConfigured => apiKey.isNotEmpty;

  Future<AiAdvice> getFullAdvice(
    SensorData data,
    AppSettings settings,
    String trendSummary, {
    bool forceRefresh = false,
  }) async {
    if (!isConfigured) {
      throw const AiAdvisorException('AI Assistant not configured');
    }

    if (!forceRefresh && _isCacheValid(data)) return _cachedAdvice!;

    final prompt =
        '''Current readings:
- Soil moisture: ${data.soilMoisture}%
- Temperature: ${data.temperature}°C
- Humidity: ${data.humidity}%
- Light: ${data.lightIntensity}

Trend (last 6 hours, soil moisture): $trendSummary
Configured thresholds: moisture < ${settings.moistureThreshold}%, light < ${settings.lightThreshold}

Give plant care advice.''';
    final advice = await _requestFullAdvice(prompt);
    _cachedAdvice = advice;
    _cachedAt = DateTime.now();
    _cachedData = SensorData(
      soilMoisture: data.soilMoisture,
      temperature: data.temperature,
      humidity: data.humidity,
      lightIntensity: data.lightIntensity,
    );
    return advice;
  }

  Future<AiAdvice> explainMetric(
    String metricName,
    double value,
    String unit,
    String trendSummary,
  ) async {
    if (!isConfigured) {
      throw const AiAdvisorException('AI Assistant not configured');
    }

    final prompt =
        '''Metric: $metricName
Value: $value$unit
Trend: $trendSummary
Explain what this means for the plant.''';
    final result = await _requestMetricAdvice(prompt);
    return AiAdvice(status: '', headline: result.$1, advice: result.$2);
  }

  bool _isCacheValid(SensorData data) {
    if (_cachedAdvice == null || _cachedAt == null || _cachedData == null) {
      return false;
    }
    if (DateTime.now().difference(_cachedAt!) > const Duration(minutes: 15)) {
      return false;
    }
    return (data.soilMoisture - _cachedData!.soilMoisture).abs() <= 1 &&
        (data.temperature - _cachedData!.temperature).abs() <= 0.5 &&
        (data.humidity - _cachedData!.humidity).abs() <= 1 &&
        (data.lightIntensity - _cachedData!.lightIntensity).abs() <= 100;
  }

  Future<AiAdvice> _requestFullAdvice(String prompt) async {
    final body = {
      'systemInstruction': {
        'parts': [
          {'text': _fullSystemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text':
                  'Current readings: soil moisture 18%, temperature 24°C, humidity 55%, light 4200. Trend: falling steadily. Configured thresholds: moisture < 30%, light < 3000. Give plant care advice.',
            },
          ],
        },
        {
          'role': 'model',
          'parts': [
            {
              'text':
                  '{"status":"Too Dry","headline":"Soil moisture dropping fast","advice":"Water your plant today.","confidence":"high"}',
            },
          ],
        },
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'maxOutputTokens': 300,
      },
    };

    return _withJsonRetry(() async {
      final response = await _post(body);
      final json = jsonDecode(response) as Map<String, dynamic>;
      return AiAdvice(
        status: json['status'] as String? ?? 'Unknown',
        headline: json['headline'] as String? ?? 'Plant care update',
        advice: json['advice'] as String? ?? 'Keep monitoring your plant.',
        confidence: json['confidence'] as String? ?? 'low',
      );
    });
  }

  Future<(String, String)> _requestMetricAdvice(String prompt) async {
    final body = {
      'systemInstruction': {
        'parts': [
          {'text': _metricSystemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'maxOutputTokens': 180,
      },
    };

    return _withJsonRetry(() async {
      final response = await _post(body);
      final json = jsonDecode(response) as Map<String, dynamic>;
      return (
        json['headline'] as String? ?? 'Sensor reading',
        json['advice'] as String? ?? 'Keep monitoring this reading.',
      );
    });
  }

  Future<T> _withJsonRetry<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on FormatException {
      try {
        return await request();
      } catch (error) {
        if (error is FormatException && T == AiAdvice) {
          return AiAdvice(
                status: 'Unknown',
                headline: 'Advice unavailable',
                advice: 'Keep monitoring your plant and try again shortly.',
                confidence: 'low',
              )
              as T;
        }
        if (error is AiAdvisorException) rethrow;
        throw const AiAdvisorException(
          'The AI response could not be understood.',
        );
      }
    }
  }

  Future<String> _post(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 429) {
        throw const AiAdvisorException(
          'AI Assistant is taking a short break, try again in a minute',
          isRateLimited: true,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _errorMessage(response.body);
        if (response.statusCode == 404) {
          throw AiAdvisorException(
            'Gemini model or API endpoint was not found. $message',
          );
        }
        if (response.statusCode == 400 ||
            response.statusCode == 401 ||
            response.statusCode == 403) {
          throw AiAdvisorException(
            'Gemini API key was rejected. Use a valid key from Google AI Studio. $message',
          );
        }
        throw AiAdvisorException(
          'Gemini API error (${response.statusCode}). $message',
        );
      }
      final root = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = root['candidates'] as List<dynamic>?;
      final candidate = candidates?.isNotEmpty == true
          ? candidates!.first as Map<String, dynamic>
          : null;
      final content = candidate?['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final part = parts?.isNotEmpty == true
          ? parts!.first as Map<String, dynamic>
          : null;
      final text = part?['text'] as String?;
      if (text == null || text.isEmpty)
        throw const FormatException('Missing AI response text');
      return text;
    } on AiAdvisorException {
      rethrow;
    } catch (_) {
      throw const AiAdvisorException(
        'Unable to reach the AI Assistant. Check your connection and try again.',
      );
    }
  }

  String _errorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['message'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}

String summarizeTrend(List<HistoryDataPoint> points) {
  if (points.length < 2) return 'not enough history';
  final ordered = [...points]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final first = ordered.first.value;
  final last = ordered.last.value;
  final delta = last - first;
  final threshold = (first.abs() * 0.05).clamp(0.5, double.infinity);
  if (delta.abs() < threshold) return 'stable';
  if (delta < 0 && delta.abs() >= threshold * 2) return 'falling steadily';
  return delta > 0 ? 'rising' : 'falling';
}
