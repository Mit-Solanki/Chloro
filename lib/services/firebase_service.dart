import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase Service - Matches actual Firestore structure:
/// - sensors_current/current  → live sensor data
/// - sensors_history/{autoId} → flat collection of historical readings
class FirebaseService {
  static final instance = FirebaseService._();
  late FirebaseFirestore _firestore;
  bool _initialized = false;

  FirebaseService._();

  Future<void> initializeFirestore() async {
    if (_initialized) return;

    try {
      _firestore = FirebaseFirestore.instance;

      if (!kIsWeb) {
        try {
          _firestore.settings = const Settings(
            persistenceEnabled: true,
            cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          );
          print('✅ Firestore offline persistence enabled');
        } catch (e) {
          print('⚠️ Could not enable offline persistence: $e');
        }
      }

      _initialized = true;
      print('✅ Firestore initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firestore: $e');
      rethrow;
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'FirebaseService not initialized. Call initializeFirestore() first.',
      );
    }
  }

  // ============================================================
  // CURRENT SENSOR READINGS
  // Collection: sensors_current, Document: current
  // Fields: humidity, ldr, soil_percent, soil_raw, temperature, time, timestamp
  // ============================================================

  /// Stream real-time current sensor data from sensors_current/current
  Stream<Map<String, dynamic>?> getSensorReadings() {
    try {
      _ensureInitialized();
      print('📡 Getting current sensor readings from sensors_current/current');
      return _firestore
          .collection('sensors_current')
          .doc('current')
          .snapshots()
          .map((snapshot) => snapshot.data());
    } catch (e) {
      print('❌ Error getting sensor readings: $e');
      return Stream.error(e);
    }
  }

  // ============================================================
  // HISTORY READINGS
  // Collection: sensors_history (flat — each doc has all sensor fields)
  // Fields per doc: humidity, ldr, soil_percent, soil_raw, temperature, time, timestamp (number)
  // ============================================================

  /// Get history readings for a specific sensor field from sensors_history
  /// [sensorField] should be one of: 'temperature', 'humidity', 'soil_percent', 'ldr'
  Future<List<Map<String, dynamic>>> getHistoryReadings(String sensorField) async {
    try {
      _ensureInitialized();
      print('📖 Getting history from sensors_history for field: $sensorField');
      final snapshot = await _firestore
          .collection('sensors_history')
          .orderBy('timestamp', descending: true)
          .limit(1440)
          .get();

      final readings = snapshot.docs.map((doc) => doc.data()).toList();
      print('✅ Retrieved ${readings.length} history records');
      return readings;
    } catch (e) {
      print('❌ Error getting history readings: $e');
      return [];
    }
  }

  /// Stream history readings from sensors_history (real-time)
  Stream<List<Map<String, dynamic>>> streamReadings(String sensorField) {
    try {
      _ensureInitialized();
      print('📡 Streaming sensors_history for field: $sensorField');
      return _firestore
          .collection('sensors_history')
          .orderBy('timestamp', descending: true)
          .limit(1440)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      print('❌ Error streaming readings: $e');
      return Stream.error(e);
    }
  }

  // ============================================================
  // GENERIC OPERATIONS (kept for flexibility)
  // ============================================================

  Future<Map<String, dynamic>?> readData(String collection, String document) async {
    try {
      _ensureInitialized();
      print('📖 Reading from $collection/$document');
      final snapshot = await _firestore.collection(collection).doc(document).get();
      if (snapshot.exists) {
        print('✅ Data found: ${snapshot.data()}');
        return snapshot.data();
      }
      print('⚠️ No data found at $collection/$document');
      return null;
    } catch (e) {
      print('❌ Error reading data: $e');
      return null;
    }
  }

  Future<void> writeData(String collection, String document, Map<String, dynamic> data) async {
    try {
      _ensureInitialized();
      print('✍️ Writing to $collection/$document');
      await _firestore.collection(collection).doc(document).set(data, SetOptions(merge: true));
      print('✅ Data written successfully');
    } catch (e) {
      print('❌ Error writing data: $e');
      rethrow;
    }
  }

  Future<void> updateData(String collection, String document, Map<String, dynamic> data) async {
    try {
      _ensureInitialized();
      print('🔄 Updating $collection/$document');
      await _firestore.collection(collection).doc(document).update(data);
      print('✅ Data updated successfully');
    } catch (e) {
      print('❌ Error updating data: $e');
      rethrow;
    }
  }

  FirebaseFirestore get firestore {
    _ensureInitialized();
    return _firestore;
  }
}