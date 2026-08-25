import 'package:flutter/material.dart';
import 'firebase_init_native.dart'
    if (dart.library.js_interop) 'firebase_init_web.dart';
import 'screens/splash.dart';
import 'screens/alarm.dart';          // AlarmScheduler
import 'services/firebase_service.dart';

// Global navigator key so AlarmScheduler can access the overlay
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  await FirebaseService.instance.initializeFirestore();
  runApp(const MyApp());

  // Start background alarm checker after first frame (overlay is ready)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final overlay = navigatorKey.currentState?.overlay;
    AlarmScheduler.init(overlay: overlay);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chloro - Smart Plant Pot',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}