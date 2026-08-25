import 'dart:async';

/// Firebase Service implementation for Web
class FirebaseServiceWeb {
  static final FirebaseServiceWeb _instance = FirebaseServiceWeb._();

  factory FirebaseServiceWeb() {
    return _instance;
  }

  FirebaseServiceWeb._();

  /// Get database reference (stub for web)
  dynamic getDatabase() {
    print('Web: Database operations use JavaScript SDK via web/index.html');
    return null;
  }

  /// Stream real-time data (stub for web)
  Stream<dynamic> streamData(String path) {
    print('Web: Streaming data from $path via JavaScript SDK');
    return const Stream.empty();
  }
}
