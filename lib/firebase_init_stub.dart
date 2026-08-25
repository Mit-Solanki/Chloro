// Stub file for unsupported platforms
Future<void> initializeFirebase() async {
  throw UnsupportedError(
    'Firebase is only supported on Android and Web platforms',
  );
}
