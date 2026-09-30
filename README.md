# 🌱 Chloro - Smart Plant Pot

A comprehensive Flutter application for real-time plant monitoring with Firebase integration. Chloro connects to IoT sensors to track soil moisture, temperature, humidity, and light levels, providing plant care insights through an intuitive dashboard and detailed analytics.

## 📱 Features

### Core Functionality
- **Real-Time Sensor Monitoring** - Live tracking of soil moisture, temperature, humidity, and light levels
- **Plant Status Detection** - Automatic plant health status evaluation (Healthy, Thirsty, At Risk, etc.)
- **Interactive Dashboard** - Visual display of current sensor readings with status indicators
- **Historical Analytics** - Track sensor data trends over time with detailed charts and statistics
- **AI Plant Care Assistant** - Gemini-powered, plain-language care advice generated from live sensor data (see [AI Plant Care Assistant](#-ai-plant-care-assistant))
- **Multi-Platform Support** - Works on Android, iOS, Web, Windows, macOS, and Linux

### User-Friendly Design
- **Material Design 3** - Modern UI with smooth animations and responsive layouts
- **Real-Time Updates** - Firebase Realtime Database for instant data synchronization
- **Chart Visualizations** - Interactive line charts powered by `fl_chart` showing historical trends
- **Splash Screen** - Custom introduction screen with app branding

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.11.3)
- Dart SDK (^3.11.3)
- Firebase project configured
- Git for version control

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd Chloro
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
   - Download `google-services.json` from Firebase Console
   - Place it in `android/app/src/`
   - For iOS, download `GoogleService-Info.plist` and add to `ios/Runner/` folder
   - Update `lib/firebase_options.dart` with your Firebase credentials

4. **Run the app**
```bash
flutter run
```

## 📋 Project Structure

```
lib/
├── main.dart                      # App entry point with Firebase initialization
├── models.dart                    # Data models (SensorData, HistoryDataPoint, etc.)
├── firebase_options.dart          # Firebase configuration for all platforms
├── firebase_init_native.dart      # Native platform Firebase initialization
├── firebase_init_web.dart         # Web platform Firebase initialization
├── firebase_init_stub.dart        # Stub for build purposes
├── screens/                       # App screens
│   ├── dashboard.dart             # Main dashboard with sensor cards
│   ├── splash.dart                # Splash screen
│   └── ...
├── services/                      # Business logic services
│   ├── firebase_service.dart      # Firebase operations
│   ├── ai_advisor_service.dart    # Gemini prompts, JSON parsing, fallback handling
│   └── ...
└── widgets/                       # Reusable UI components
    ├── sensor_card.dart           # Sensor data cards
    ├── history_modal.dart         # History detail modal
    ├── ai_insight_card.dart       # Renders structured AI advice
    ├── metric_explanation.dart    # Per-sensor "Explain" sheet
    └── ...
```

## 🔧 Key Technologies

- **Flutter** - Cross-platform UI framework
- **Firebase Core** - Backend services
- **Firebase Realtime Database** - Real-time data storage and synchronization
- **fl_chart** - Interactive charting library
- **intl** - Internationalization support

## 📊 Main Components

### Dashboard Tab
Displays the current plant status and live sensor readings:
- Plant Health Status with color-coded indicator
- Soil Moisture percentage
- Temperature in Celsius
- Humidity percentage
- Light level readings

### History Tab
Tracks sensor data over time with:
- Line charts showing historical trends
- Min, max, and average statistics
- Detailed data points with timestamps
- Interactive modal dialogs for in-depth analysis

### Sensor Card Widget
Reusable component featuring:
- Current sensor value
- Translucent background chart
- Click-to-expand functionality
- Customizable colors and icons

## 🤖 AI Plant Care Assistant

The AI Plant Care Assistant turns raw sensor numbers into structured, plain-language care advice using the **Google Gemini API** (`gemini-3.6-flash`, free tier from Google AI Studio).

### Running with the API key
The key is **never hardcoded or committed**. Pass it at launch:

```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=your_key_here
```

Without the key, the AI tab shows "AI Assistant not configured". In VS Code, add the same flag under `"args"` in `.vscode/launch.json` (do not commit a real key).

### Data used by the assistant
- `sensors_current/current` - live soil moisture, temperature, humidity and light values
- `sensors_history` - up to 1440 records of `soil_percent` + `timestamp`, summarised into a trend ("rising", "falling steadily", "stable")

## 🔄 Before vs During Enhancement

**Before enhancement**, Chloro displayed live sensor readings (soil moisture, temperature, humidity, light), historical trends, LED control, a speaker/music player, alarms, notification history and threshold settings. Limitations: unstable database connectivity with errors only logged to the console (no user feedback), a glitchy UI, no validation of missing/malformed sensor readings, static hardcoded thresholds, duplicate dashboard logic, no automated tests, and - most importantly - **no interpretive layer**: the app showed raw numbers and left the user to judge what they meant for the plant.

**During enhancement**, an AI Plant Care Assistant was designed and built to close that gap: a new `ai_advisor_service.dart`, an **AI Assistant** tab, and a per-sensor **Explain** action on the dashboard. It applies these prompt-engineering techniques:

| Technique | How it is used in Chloro |
|---|---|
| Role / persona prompting | Model is told it is a friendly plant-care expert for a smart pot |
| Explicit rule-based instructions | Hard rules on tone, length, and how to treat each sensor range |
| Enforced JSON output schema | Model must return only JSON with fixed keys so the UI can render it |
| Few-shot examples | Example input/output pairs anchor format and tone |
| Dynamic context injection | Live readings, thresholds and the history trend are inserted into every prompt |
| Task scoping | One prompt for full advice, a separate one for explaining a single metric |
| Failure-aware fallback | Malformed/empty output is retried once, then replaced by a safe fallback message |

## 🧾 Prompts / Prompt Cards Used for Project Enhancement

This section documents every prompt used to refine and enhance the project. It has two parts: **(A)** the prompts written to an AI coding assistant (Claude, via Claude Code) while building and debugging the project, and **(B)** the prompt cards embedded in the app that are sent to Gemini at runtime.

### Part A - Development prompts 

#### Card A1 - Review, fix and complete the enhancement
- **Stage:** Enhancement / debugging
- **Tool:** Claude (Claude Code)
- **Prompt:**
  > Here is an error in this project initially. **Before enhancement**, Chloro was a Flutter companion app for a smart plant pot that used Firebase to display live sensor readings (soil moisture, temperature, humidity, light) on a dashboard, along with historical trends, LED control, a speaker/music player, alarms, notification history, and settings for configuring thresholds. However, the project had several limitations: unstable database connectivity with errors only logged to console and no feedback shown to the user, a difficult and glitchy UI, no data validation for missing or malformed sensor readings, static hardcoded thresholds, duplicate dashboard logic, no automated testing, and most notably, no interpretive layer - the app simply displayed raw numbers and left the user to manually judge what the readings meant for their plant's health.
  >
  > **During enhancement**, I designed and proposed an AI Plant Care Assistant feature to close that interpretive gap, using the Google Gemini API (free tier) to turn live sensor data into structured, plain-language care advice. This involved role/persona prompting, explicit rule-based instructions, enforced JSON output schemas, few-shot examples, dynamic context injection from real sensor data, task scoping (a full-advice prompt versus a single-metric "explain" prompt), and failure-aware fallback handling - implemented through a new `ai_advisor_service.dart`, a new AI Assistant tab, and a per-sensor "Explain" action on the dashboard. The remaining steps are to obtain a Gemini API key, run the app with the key passed securely via `--dart-define`, test the AI's output against a range of real sensor scenarios, and document the results.
  >
  > But now there is an error when I was trying to enhance. Can you try to solve it and enhance it if there was a mistake made, or the task is incomplete, or there is an error?
- **Outcome:** Assistant ran `flutter analyze` (no compile errors), verified the AI tab wiring, and asked for the exact runtime error.

#### Card A2 - Runtime log + API key question
- **Stage:** Debugging
- **Prompt:** Pasted the full `flutter run` output (Firebase initialised, 1440 history records retrieved) and the AI tab message *"AI Assistant not configured. Run the app with --dart-define=GEMINI_API_KEY=your_key"*, then asked: *"for the AI assistance tab do I need API key set up, if yes then where or how do I run it?"*
- **Outcome:** Confirmed the key is read via `String.fromEnvironment('GEMINI_API_KEY')` and must be supplied with `--dart-define`; explained the harmless `objective_c` native-assets warning caused by the space in the Windows folder path.

#### Card A3 - Deprecated model error
- **Stage:** Debugging
- **Prompt:** Pasted: *"Gemini model or API endpoint was not found. This model models/gemini-2.5-flash is no longer available to new users. Please update your code to use models/gemini-3.6-flash..."*
- **Outcome:** Model updated from `gemini-2.5-flash` to `gemini-3.6-flash` in `ai_advisor_service.dart` and the feature spec.

#### Card A4 - "Advice unavailable" fallback
- **Stage:** Debugging
- **Prompt:** Reported the fallback text *"Advice unavailable. Keep monitoring your plant and try again shortly."*, then asked *"is it because the data is too old like about 3-4 months ago?"* and later *"same output"*.
- **Outcome:** Diagnosed as a JSON-parse failure (hidden "thinking" tokens consuming a tiny `maxOutputTokens` budget), not data age. Raised output limits (300 -> 1024 for full advice, 180 -> 512 for explain) and added console logging of failed parses.

#### Card A5 - Invalid argument (HTTP 400)
- **Stage:** Debugging
- **Prompt:** Pasted: *"Gemini API key was rejected. Use a valid key from Google AI Studio. Request contains an invalid argument."*
- **Outcome:** Assistant researched current docs and found Gemini 3.x models reject the legacy `thinkingBudget`; replaced it with `'thinkingConfig': {'thinkingLevel': 'minimal'}` in both request bodies.

#### Card A6 - Data-source clarification
- **Stage:** Understanding / validation
- **Prompt:** Described the Firestore layout (`sensors` - new, unused; `sensors_current` - live data, single doc `current`; `sensors_history` - auto-ID documents with `humidity, ldr, soil_percent, soil_raw, temperature, time, timestamp`) and asked: *"so if the AI assistance is needed to be used it should be from this table right, sensors_history?"*
- **Outcome:** Confirmed the AI uses `sensors_current/current` for live values and `sensors_history` for the trend summary; the `sensors` collection is not used.

#### Card A7 - Commit and push
- **Stage:** Version control
- **Prompt:** *"commit in github with the updated modification in the project https://github.com/Mit-Solanki/Chloro.git - do not remove the previous files that were pushed"*
- **Outcome:** Only the modified source/doc files were committed and fast-forward pushed to `origin/master`; nothing was removed or force-pushed.

#### Card A8 - Faculty documentation requirement
- **Stage:** Documentation
- **Prompt:** *"It has been noticed that many students have not specified the prompts/prompt cards used to refine and enhance their projects. If you have a GitHub repo, add all the prompts/prompt cards used for project enhancement in the README file."*
- **Outcome:** This section of the README.

### Part B - Runtime prompt cards 

> The wording below is a condensed representation of each prompt's structure. The exact strings live in `lib/services/ai_advisor_service.dart`.

#### Card B1 - Full plant-care advice
- **Purpose:** Convert current readings + trend into structured advice for the AI Assistant tab.
- **Techniques:** Role prompting, rule-based instructions, JSON schema, few-shot example, dynamic context injection.
- **Prompt template:**
  ```text
  ROLE: You are a friendly plant-care expert for a smart plant pot.

  RULES:
  - Base advice only on the readings provided; never invent values.
  - Use plain, non-technical language; keep each field short.
  - Compare readings against the user's thresholds.
  - Return ONLY valid JSON, no markdown, no extra text.

  OUTPUT SCHEMA:
  { "status": "...", "summary": "...", "actions": ["..."], "watch_out": "..." }

  EXAMPLE:
  Input: soil 18%, temp 24C, humidity 55%, light low, trend falling steadily
  Output: { "status": "Thirsty", "summary": "...", "actions": ["Water now", "..."], "watch_out": "..." }

  CURRENT DATA (injected at runtime):
  soil_moisture={soil}%, temperature={temp}C, humidity={hum}%, light={ldr}
  thresholds: moisture={moistureThreshold}, light={lightThreshold}
  soil_moisture_trend={trend}
  ```

#### Card B2 - Explain a single metric
- **Purpose:** Powers the per-sensor "Explain" action on the dashboard.
- **Techniques:** Task scoping, role prompting, JSON schema, dynamic context injection.
- **Prompt template:**
  ```text
  ROLE: You are a plant-care expert explaining one sensor reading to a beginner.
  TASK: Explain what the {metric} value of {value}{unit} means for this plant,
        whether it is good, low or high, and one simple action.
  Return ONLY JSON: { "meaning": "...", "verdict": "good|low|high", "tip": "..." }
  ```

#### Card B3 - Failure-aware retry and fallback
- **Purpose:** Keep the UI stable when Gemini returns empty or malformed output.
- **Techniques:** Failure-aware handling.
- **Behaviour:** The response is parsed as JSON; on failure the request is retried once with the same prompt; if it fails again the app shows the safe fallback *"Advice unavailable. Keep monitoring your plant and try again shortly."* and logs the raw response to the console for debugging.

### Request configuration (final)
- Model: `gemini-3.6-flash`
- `thinkingConfig: { thinkingLevel: "minimal" }` (Gemini 3.x does not accept `thinkingBudget`)
- `maxOutputTokens`: 1024 (full advice), 512 (explain)

## ✅ After-Enhancement Results

| Area | Before | After |
|---|---|---|
| Interpreting sensor data | Raw numbers only | Plain-language, structured advice |
| Per-sensor understanding | None | "Explain" action on each sensor |
| Model failures | Not applicable | Retry + safe fallback + console diagnostics |
| API key handling | Not applicable | Passed via `--dart-define`, never committed |

## 🔐 Firebase Setup

This project uses Firebase for real-time data synchronization. See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for:
- Complete Firebase configuration guide
- Platform-specific setup instructions
- Firestore/Realtime Database setup

## 📚 Documentation

- [Firebase Setup Guide](FIREBASE_SETUP.md) - Firebase integration instructions
- [Firebase Database Guide](FIREBASE_DATABASE_SETUP.md) - Database configuration
- [History Feature Guide](HISTORY_FEATURE_GUIDE.md) - Implementing data history views
- [Send Sensor Data Guide](SEND_SENSOR_DATA.md) - Guide for IoT device data transmission
- [Prompts / Prompt Cards](#-prompts--prompt-cards-used-for-project-enhancement) - All prompts used to enhance this project

## 🐛 Troubleshooting

### Common Issues
- **Firebase initialization errors** - Ensure `google-services.json` is in the correct location
- **iOS build failures** - Run `flutter clean` and `flutter pub get`
- **Database connection timeouts** - Verify Firebase Realtime Database rules allow read/write access

## 📝 Development Notes

- **Platforms Supported**: Android, iOS, Web, Windows, macOS, Linux
- **Material Design**: Uses ColorScheme derived from green seed color
- **State Management**: Widget-based state management with `StatefulWidget`

## 🤝 Contributing

Feel free to fork, enhance, and submit pull requests for improvements.

## 📄 License

This project is private and not for public distribution.

---

**Happy Gardening! 🌿**
