# AI Assistant Setup

The AI Assistant uses Google's Gemini API free tier. Get an API key from [Google AI Studio](https://aistudio.google.com/) using **Get API key**.

Run the app with the key supplied at compile time:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

For a release build, provide the same define when building:

```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
```

The key is intentionally not stored in the source code. Do not commit API keys or local environment files containing keys. The app shows an unconfigured state when the define is missing.
