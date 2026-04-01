import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Initialize Firebase for Android native platform
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully for Android');
  } on FirebaseException catch (e) {
    print('❌ Firebase initialization error: ${e.message}');
    rethrow;
  } catch (e) {
    print('❌ Unexpected error during Firebase initialization: $e');
    rethrow;
  }
}
