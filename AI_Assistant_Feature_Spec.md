# Chloro — AI Plant Care Assistant: Implementation Spec

Paste this whole document to your coding agent as the task instructions.

## Context
Flutter app "Chloro" (smart plant pot). Existing structure:
- `lib/models.dart` — SensorData, LEDSettings, SpeakerSettings, AppSettings, SensorHistory
- `lib/services/firebase_service.dart` — Firestore reads: `sensors_current/current` (fields: `temperature`, `humidity`, `soil_percent`, `ldr`) and `sensors_history` (same fields + `timestamp`)
- `lib/screens/home.dart` — HomePage with a 4-tab `TabController` (Dashboard, LED Control, Speaker, Settings) inside a `TabBarView`
- Dependencies already in `pubspec.yaml`: `http: ^1.2.0`, `shared_preferences: ^2.3.0`

## Goal
Add a 5th tab, **"AI Assistant"**, that calls the **Google Gemini API (free tier)** to turn live sensor data into short, structured plant care advice. Also add an "Explain" action on individual sensor cards that requests advice for just that one metric.

## 0. Why Gemini (free tier)
Anthropic and OpenAI don't offer a standing free API tier (only limited trial credits, which can expire or require a card). Google's Gemini API free tier requires no credit card and is generous enough for a class project's call volume. Get a key at **aistudio.google.com** → "Get API key". Rate limits are modest (roughly tens of requests/day depending on model at time of writing) — fine for a demo, but the caching in Section 2 matters more here than it would on a paid tier.

## 1. API key handling
Do NOT hardcode the API key in source. Read it via a compile-time define:
```
flutter run --dart-define=GEMINI_API_KEY=xxxx
```
In code: `const apiKey = String.fromEnvironment('GEMINI_API_KEY');`
Add a check: if `apiKey.isEmpty`, show a "AI Assistant not configured" state instead of crashing.
Add `GEMINI_API_KEY` usage instructions to a new `AI_ASSISTANT_SETUP.md` and make sure `.gitignore` covers any local env files you create.

## 2. New service: `lib/services/ai_advisor_service.dart`
Responsibilities:
- Build the prompt (see Section 3) from a `SensorData` object, an `AppSettings` object, and an optional trend summary string.
- POST to `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey` with a JSON body:
```json
{
  "systemInstruction": { "parts": [ { "text": "<system prompt>" } ] },
  "contents": [
    { "role": "user", "parts": [ { "text": "<few-shot user turn>" } ] },
    { "role": "model", "parts": [ { "text": "<few-shot assistant JSON>" } ] },
    { "role": "user", "parts": [ { "text": "<actual filled prompt>" } ] }
  ],
  "generationConfig": { "responseMimeType": "application/json", "maxOutputTokens": 300 }
}
```
  Setting `responseMimeType: "application/json"` makes Gemini return valid JSON directly — use it instead of relying on prompt instructions alone.
- Parse the response's `candidates[0].content.parts[0].text` as JSON matching the schema in Section 3. If parsing fails, retry the call once. If it fails again, return a fallback object with `status: "Unknown"` and a generic message.
- Handle HTTP 429 (rate limit) explicitly — since the free tier is capped, show "AI Assistant is taking a short break, try again in a minute" rather than a generic error.
- Cache the last full-advice result in memory with a timestamp; if called again within 15 minutes and sensor values haven't changed by more than a small delta, return the cached result instead of calling the API again. (Caching matters more on a free, rate-limited tier — lean toward a longer cache window than you would on a paid API.)
- Expose two methods:
  - `Future<AiAdvice> getFullAdvice(SensorData data, AppSettings settings, String trendSummary)`
  - `Future<AiAdvice> explainMetric(String metricName, double value, String unit, String trendSummary)`

## 3. Prompt design

### System prompt (full advice)
```
You are Chloro's plant care advisor. You receive live sensor readings from a
smart plant pot (soil moisture %, temperature °C, humidity %, light level)
and must give short, practical care advice.

Rules:
- Base advice ONLY on the data given. Never invent readings.
- If a value is missing, say so instead of guessing.
- Keep "advice" under 40 words.
- Classify "status" as exactly one of: "Healthy", "Needs Water", "Too Dry",
  "Too Wet", "Low Light", "Too Hot", "Too Cold".
- Respond ONLY with valid JSON matching this schema, nothing else, no markdown fences:
{
  "status": string,
  "headline": string,
  "advice": string,
  "confidence": "low" | "medium" | "high"
}
```

### User prompt template (full advice)
```
Current readings:
- Soil moisture: {soil_percent}%
- Temperature: {temperature}°C
- Humidity: {humidity}%
- Light: {ldr}

Trend (last 6 hours, soil moisture): {trendSummary}
Configured thresholds: moisture < {moistureThreshold}%, light < {lightThreshold}

Give plant care advice.
```

### One few-shot example to include as a prior user/assistant turn (locks tone + format)
User:
```
Current readings:
- Soil moisture: 18%
- Temperature: 24°C
- Humidity: 55%
- Light: 4200
Trend (last 6 hours, soil moisture): falling steadily
Configured thresholds: moisture < 30%, light < 3000
Give plant care advice.
```
Assistant:
```
{"status":"Too Dry","headline":"Soil moisture dropping fast","advice":"Water your plant today — moisture has fallen steadily and is well below the healthy range. Check again in a few hours to confirm it's absorbing water.","confidence":"high"}
```

### System prompt (single-metric explain)
```
You are Chloro's plant care advisor. You are given ONE sensor reading and
must explain what it means for the plant in plain language.

Rules:
- Keep "advice" under 30 words.
- Respond ONLY with valid JSON, no markdown fences:
{"headline": string, "advice": string}
```
User prompt template:
```
Metric: {metricName}
Value: {value}{unit}
Trend: {trendSummary}
Explain what this means for the plant.
```

## 4. Trend summary helper
Add a small pure function (in `ai_advisor_service.dart` or `models.dart`) that takes a `List<HistoryDataPoint>` (or the raw `sensors_history` docs already fetched by `FirebaseService`) and returns a short string like `"rising"`, `"falling steadily"`, `"stable"`, or `"falling 15% since this morning"`. Compute this client-side — don't send raw history arrays into the prompt.

## 5. New model: add to `lib/models.dart`
```dart
class AiAdvice {
  final String status;
  final String headline;
  final String advice;
  final String confidence; // "low" | "medium" | "high" or "" for metric explain
  AiAdvice({
    required this.status,
    required this.headline,
    required this.advice,
    this.confidence = '',
  });
}
```

## 6. New widget: `lib/widgets/ai_insight_card.dart`
A card showing a small AI/sparkle icon, the `headline` in bold, the `advice` text, and a subtle "AI-generated" label. Accepts a loading state (show a shimmer/spinner while awaiting the API call) and an error state (show a retry button).

## 7. New screen: `lib/screens/ai_assistant.dart`
- `StatefulWidget` that on load calls `AiAdvisorService.getFullAdvice(...)` using the current `SensorData`, `AppSettings`, and a trend summary computed from `FirebaseService.instance.getHistoryReadings('soil_percent')`.
- Shows the `AiInsightCard` for the result.
- A "Refresh advice" button that forces a new (non-cached) call.
- Handle the "not configured" (missing API key) and error states clearly.

## 8. Wire into `home.dart`
- Change `TabController(length: 4, ...)` to `length: 5`.
- Add a 5th `Tab(text: 'AI Assistant', icon: Icon(Icons.auto_awesome))` to the `TabBar`.
- Add the corresponding `AiAssistantTab(...)` widget to the `TabBarView` children, passing `sensorData` and `appSettings`.

## 9. Per-sensor "Explain" action
In `sensor_card.dart`, add a small icon button (e.g. `Icons.psychology` or `Icons.auto_awesome`) that opens a bottom sheet calling `AiAdvisorService.explainMetric(...)` for that specific sensor and displays the result in an `AiInsightCard`.

## 10. Error/edge cases to handle
- No internet / API timeout → show retry UI, never crash.
- Missing API key → disabled state with a short explanation, not a runtime error.
- Malformed JSON from the model → one retry, then fallback message.
- Don't call the API on every `setState` from the realtime sensor stream — only on tab open, manual refresh, or significant value change (debounce).

## Deliverable checklist for the agent
- [ ] `lib/services/ai_advisor_service.dart`
- [ ] `AiAdvice` model added to `lib/models.dart`
- [ ] `lib/widgets/ai_insight_card.dart`
- [ ] `lib/screens/ai_assistant.dart`
- [ ] `home.dart` updated to 5 tabs
- [ ] `sensor_card.dart` updated with "Explain" action
- [ ] `AI_ASSISTANT_SETUP.md` with instructions for getting a free key at aistudio.google.com and running with `--dart-define=GEMINI_API_KEY=...`
