// ignore_for_file: type=lint
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (Platform.isAndroid) {
      return android;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are only supported for Web and Android.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDOPQ-yQ13j3XrayxpJyDeWkxgYrHS6fUo',
    appId: '1:347936820144:android:ba70bbce8ab45e4013e475',
    messagingSenderId: '347936820144',
    projectId: 'chrolo-1fec8',
    storageBucket: 'chrolo-1fec8.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAA0Q2vGeD83oWFSCFhwFuv6CkIvo7hgqM',
    appId: '1:347936820144:web:e86c9dd9c3d5c27f13e475',
    messagingSenderId: '347936820144',
    projectId: 'chrolo-1fec8',
    storageBucket: 'chrolo-1fec8.firebasestorage.app',
  );
}
