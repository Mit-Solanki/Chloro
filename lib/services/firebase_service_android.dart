import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

/// Firebase Service implementation for Android
class FirebaseServiceAndroid {
  static final FirebaseServiceAndroid _instance = FirebaseServiceAndroid._();
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  factory FirebaseServiceAndroid() {
    return _instance;
  }

  FirebaseServiceAndroid._();

  /// Get database reference
  DatabaseReference getDatabase() {
    return _database.ref();
  }

  /// Stream real-time data
  Stream<DatabaseEvent> streamData(String path) {
    try {
      return _database.ref(path).onValue;
    } catch (e) {
      print('Error streaming data: $e');
      return Stream.error(e);
    }
  }
}
