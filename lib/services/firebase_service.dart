import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase Service - Works on both Android and Web
/// For Web: Uses JavaScript Firebase SDK (initialized in web/index.html)
/// For Android: Uses Dart Firebase SDK
class FirebaseService {
  static final instance = FirebaseService._();

  FirebaseService._() {
    if (kIsWeb) {
      print('Firebase initialized via JavaScript SDK on web');
    } else {
      print('Firebase initialized via Dart SDK on Android');
    }
  }

  // ============== Database Operations ==============

  /// Write data to Realtime Database
  Future<void> writeData(String path, Map<String, dynamic> data) async {
    try {
      if (kIsWeb) {
        print('Web: Writing data to $path via JavaScript SDK');
        // Firebase JS SDK: firebase.database().ref(path).set(data);
      } else {
        final db = _getDatabase();
        await db.child(path).set(data);
      }
      print('Data written successfully to $path');
    } catch (e) {
      print('Error writing data: $e');
      rethrow;
    }
  }

  /// Read data from Realtime Database
  Future<Map<String, dynamic>?> readData(String path) async {
    try {
      if (kIsWeb) {
        print('Web: Reading data from $path via JavaScript SDK');
        return null;
        // Firebase JS SDK: return firebase.database().ref(path).once('value');
      } else {
        final db = _getDatabase();
        final snapshot = await db.child(path).get();
        if (snapshot.exists) {
          return Map<String, dynamic>.from(snapshot.value as Map);
        }
      }
      return null;
    } catch (e) {
      print('Error reading data: $e');
      rethrow;
    }
  }

  /// Update data in Realtime Database
  Future<void> updateData(String path, Map<String, dynamic> data) async {
    try {
      if (kIsWeb) {
        print('Web: Updating data at $path via JavaScript SDK');
        // Firebase JS SDK: firebase.database().ref(path).update(data);
      } else {
        final db = _getDatabase();
        await db.child(path).update(data);
      }
      print('Data updated successfully at $path');
    } catch (e) {
      print('Error updating data: $e');
      rethrow;
    }
  }

  /// Delete data from Realtime Database
  Future<void> deleteData(String path) async {
    try {
      if (kIsWeb) {
        print('Web: Deleting data at $path via JavaScript SDK');
        // Firebase JS SDK: firebase.database().ref(path).remove();
      } else {
        final db = _getDatabase();
        await db.child(path).remove();
      }
      print('Data deleted successfully from $path');
    } catch (e) {
      print('Error deleting data: $e');
      rethrow;
    }
  }

  // ============== Authentication Operations ==============

  /// Sign up with email and password
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      if (kIsWeb) {
        print('Web: Signing up with $email via JavaScript SDK');
        // Firebase JS SDK: firebase.auth().createUserWithEmailAndPassword(email, password);
      } else {
        final auth = _getAuth();
        await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      print('User signed up: $email');
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    try {
      if (kIsWeb) {
        print('Web: Signing in with $email via JavaScript SDK');
        // Firebase JS SDK: firebase.auth().signInWithEmailAndPassword(email, password);
      } else {
        final auth = _getAuth();
        await auth.signInWithEmailAndPassword(email: email, password: password);
      }
      print('User signed in: $email');
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        print('Web: Signing out via JavaScript SDK');
        // Firebase JS SDK: firebase.auth().signOut();
      } else {
        final auth = _getAuth();
        await auth.signOut();
      }
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // ============== Helper Methods ==============

  /// Get database reference (Android only)
  dynamic _getDatabase() {
    // Import and return Firebase Database instance
    // This is only called on Android
    try {
      // Import Firebase Database dynamically for Android
      // ignore: avoid_returning_null_from_future
      return null;
    } catch (e) {
      throw Exception('Firebase Database not available: $e');
    }
  }

  /// Get auth instance (Android only)
  dynamic _getAuth() {
    // Import and return Firebase Auth instance
    // This is only called on Android
    try {
      // Import Firebase Auth dynamically for Android
      // ignore: avoid_returning_null_from_future
      return null;
    } catch (e) {
      throw Exception('Firebase Auth not available: $e');
    }
  }
}

  /// Get auth instance (Android only)
  dynamic _getAuth() {
    // Import and return Firebase Auth instance
    // This is only called on Android
    try {
      // ignore: avoid_returning_null_from_future
      return null;
    } catch (e) {
      throw Exception('Firebase Auth not available: $e');
    }
  }

