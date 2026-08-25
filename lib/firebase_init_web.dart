// Firebase initialization for web
// Firebase is initialized via JavaScript in web/index.html

// Future<void> initializeFirebase() async {
//   // Firebase for web is already initialized in web/index.html
//   print('✅ Firebase initialized via JavaScript SDK on Web');
// }

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Initialize Firebase for Web platform using Dart SDK
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.web,
    );
    print('✅ Firebase initialized successfully for Web');
  } on FirebaseException catch (e) {
    // Already initialized — safe to ignore
    if (e.code == 'duplicate-app') {
      print('✅ Firebase already initialized for Web');
    } else {
      print('❌ Firebase initialization error on Web: ${e.message}');
      rethrow;
    }
  } catch (e) {
    print('❌ Unexpected error during Firebase Web initialization: $e');
    rethrow;
  }
}