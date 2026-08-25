import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// Helper class to populate Firestore with test data
/// 
/// Usage in main.dart during development:
/// ```dart
/// await FirestoreTestDataHelper.populateAllTestData();
/// ```
class FirestoreTestDataHelper {
  static final _db = FirebaseFirestore.instance;
  static final _random = Random();

  /// Populate all test data at once
  static Future<void> populateAllTestData() async {
    print('📝 Starting Firestore test data population...');
    try {
      await populateSensorsCurrent();
      await populateTemperatureHistory();
      await populateHumidityHistory();
      await populateMoistureHistory();
      await populateLightHistory();
      print('✅ All test data populated successfully!');
    } catch (e) {
      print('❌ Error populating test data: $e');
      rethrow;
    }
  }

  /// Populate current sensor readings
  static Future<void> populateSensorsCurrent() async {
    try {
      print('📝 Populating sensors/current...');
      await _db.collection('sensors').doc('current').set({
        'temperature': 25.5,
        'humidity': 72.0,
        'soil_moisture': 65.0,
        'light_intensity': 8500.0,
      }, SetOptions(merge: true));
      print('✅ sensors/current populated');
    } catch (e) {
      print('❌ Error populating sensors/current: $e');
    }
  }

  /// Populate temperature history (72 data points = 72 minutes of data)
  static Future<void> populateTemperatureHistory() async {
    try {
      print('📝 Populating temperature history...');
      final batch = _db.batch();
      int count = 0;

      for (int i = 0; i < 72; i++) {
        final timestamp = DateTime.now().subtract(Duration(minutes: i));
        // Temperature varies between 22 and 28 degrees
        final baseTemp = 25.0 + (sin(i / 10) * 3.0);
        final value = baseTemp + (_random.nextDouble() - 0.5) * 2;

        final doc = _db
            .collection('history')
            .doc('temperature')
            .collection('readings')
            .doc();

        batch.set(doc, {
          'timestamp': timestamp.toIso8601String(),
          'value': double.parse(value.toStringAsFixed(1)),
        });
        count++;
      }

      await batch.commit();
      print('✅ Temperature history populated ($count readings)');
    } catch (e) {
      print('❌ Error populating temperature history: $e');
    }
  }

  /// Populate humidity history (72 data points)
  static Future<void> populateHumidityHistory() async {
    try {
      print('📝 Populating humidity history...');
      final batch = _db.batch();
      int count = 0;

      for (int i = 0; i < 72; i++) {
        final timestamp = DateTime.now().subtract(Duration(minutes: i));
        // Humidity varies between 60 and 85 percent
        final baseHumidity = 72.0 + (sin(i / 15) * 12.0);
        final value =
            (baseHumidity + (_random.nextDouble() - 0.5) * 5).clamp(50, 95);

        final doc = _db
            .collection('history')
            .doc('humidity')
            .collection('readings')
            .doc();

        batch.set(doc, {
          'timestamp': timestamp.toIso8601String(),
          'value': double.parse(value.toStringAsFixed(1)),
        });
        count++;
      }

      await batch.commit();
      print('✅ Humidity history populated ($count readings)');
    } catch (e) {
      print('❌ Error populating humidity history: $e');
    }
  }

  /// Populate soil moisture history (72 data points)
  static Future<void> populateMoistureHistory() async {
    try {
      print('📝 Populating soil moisture history...');
      final batch = _db.batch();
      int count = 0;

      for (int i = 0; i < 72; i++) {
        final timestamp = DateTime.now().subtract(Duration(minutes: i));
        // Soil moisture varies between 45 and 75 percent
        final baseMoisture = 60.0 + (sin(i / 20) * 15.0);
        final value = (baseMoisture + (_random.nextDouble() - 0.5) * 8)
            .clamp(40, 80);

        final doc = _db
            .collection('history')
            .doc('soil_moisture')
            .collection('readings')
            .doc();

        batch.set(doc, {
          'timestamp': timestamp.toIso8601String(),
          'value': double.parse(value.toStringAsFixed(1)),
        });
        count++;
      }

      await batch.commit();
      print('✅ Soil moisture history populated ($count readings)');
    } catch (e) {
      print('❌ Error populating soil moisture history: $e');
    }
  }

  /// Populate light intensity history (72 data points)
  static Future<void> populateLightHistory() async {
    try {
      print('📝 Populating light intensity history...');
      final batch = _db.batch();
      int count = 0;

      for (int i = 0; i < 72; i++) {
        final timestamp = DateTime.now().subtract(Duration(minutes: i));
        // Light intensity varies between 5000 and 12000 lux
        final baseLight = 8500.0 + (sin(i / 12) * 3500.0);
        final value =
            (baseLight + (_random.nextDouble() - 0.5) * 1500).clamp(4000, 12000);

        final doc = _db
            .collection('history')
            .doc('light_intensity')
            .collection('readings')
            .doc();

        batch.set(doc, {
          'timestamp': timestamp.toIso8601String(),
          'value': double.parse(value.toStringAsFixed(0)),
        });
        count++;
      }

      await batch.commit();
      print('✅ Light intensity history populated ($count readings)');
    } catch (e) {
      print('❌ Error populating light intensity history: $e');
    }
  }

  /// Clear all test data (use with caution!)
  static Future<void> clearAllTestData() async {
    try {
      print('⚠️ Clearing all test data...');

      // Delete all history collections
      await _clearCollection('history', 'temperature', 'readings');
      await _clearCollection('history', 'humidity', 'readings');
      await _clearCollection('history', 'soil_moisture', 'readings');
      await _clearCollection('history', 'light_intensity', 'readings');

      print('✅ All test data cleared');
    } catch (e) {
      print('❌ Error clearing test data: $e');
    }
  }

  static Future<void> _clearCollection(
      String collectionPath, String docId, String subCollectionName) async {
    final querySnapshot = await _db
        .collection(collectionPath)
        .doc(docId)
        .collection(subCollectionName)
        .get();

    for (final doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }
}
