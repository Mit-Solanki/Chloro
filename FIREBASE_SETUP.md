# Firebase Integration Guide for Chloro

This guide walks you through using Firebase in your Flutter app.

## ✅ What's Already Done

1. **Dependencies Added** - Added Firebase packages to `pubspec.yaml`:
   - `firebase_core` - Core Firebase SDK
   - `firebase_database` - Realtime Database
   - `firebase_auth` - Authentication
   - `firebase_storage` - Cloud Storage

2. **Android Configuration** - Set up Google Services:
   - Added `google-services.json` in `android/app/src/`
   - Updated `android/build.gradle.kts` with Google Services plugin
   - Updated `android/app/build.gradle.kts` to apply Google Services plugin

3. **Web Configuration** - Added Firebase JavaScript SDK to `web/index.html`

4. **Firebase Initialization** - Updated `lib/main.dart` to initialize Firebase on app startup

5. **Firebase Options** - Created `lib/firebase_options.dart` with platform-specific configurations

6. **Helper Service** - Created `lib/services/firebase_service.dart` with convenient methods

## 🚀 Next Steps

### 1. Get Dependencies

Run this command in your project:

```bash
flutter pub get
```

### 2. Add iOS Configuration (Optional)

If you plan to run on iOS, you need to add the iOS app credentials:

1. Go to Firebase Console: https://console.firebase.google.com/project/chrolo-1fec8
2. Click on your iOS app
3. Download the `GoogleService-Info.plist` file
4. Add it to `ios/Runner/` folder via Xcode or by dragging it

Then update the iOS credentials in `lib/firebase_options.dart`:

```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY', // From GoogleService-Info.plist
  appId: '1:347936820144:ios:YOUR_IOS_APP_ID', // From GoogleService-Info.plist
  messagingSenderId: '347936820144',
  projectId: 'chrolo-1fec8',
  storageBucket: 'chrolo-1fec8.firebasestorage.app',
);
```

### 3. Database Setup

Set up your Realtime Database rules in Firebase Console:

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

## 📝 Usage Examples

### Import the Firebase Service

```dart
import 'package:chloro/services/firebase_service.dart';
```

### Write Data

```dart
await FirebaseService.instance.writeData('users/user1', {
  'name': 'John',
  'email': 'john@example.com',
  'timestamp': DateTime.now().toIso8601String(),
});
```

### Read Data

```dart
final data = await FirebaseService.instance.readData('users/user1');
print(data);
```

### Stream Real-time Data

```dart
FirebaseService.instance.streamData('users/user1').listen((event) {
  print('Data: ${event.snapshot.value}');
});
```

### Update Data

```dart
await FirebaseService.instance.updateData('users/user1', {
  'name': 'Jane',
});
```

### Delete Data

```dart
await FirebaseService.instance.deleteData('users/user1');
```

### Authentication - Sign Up

```dart
try {
  final userCredential = await FirebaseService.instance.signUpWithEmail(
    'user@example.com',
    'password123',
  );
  print('Signed up: ${userCredential.user?.email}');
} catch (e) {
  print('Error: $e');
}
```

### Authentication - Sign In

```dart
try {
  final userCredential = await FirebaseService.instance.signInWithEmail(
    'user@example.com',
    'password123',
  );
  print('Signed in: ${userCredential.user?.email}');
} catch (e) {
  print('Error: $e');
}
```

### Get Current User

```dart
final user = FirebaseService.instance.getCurrentUser();
print('Current user: ${user?.email}');
```

### Listen for Auth State Changes

```dart
FirebaseService.instance.authStateStream().listen((user) {
  if (user != null) {
    print('User logged in: ${user.email}');
  } else {
    print('User logged out');
  }
});
```

### Upload File

```dart
import 'dart:typed_data';

final bytes = Uint8List.fromList([...file bytes...]);
final downloadUrl = await FirebaseService.instance.uploadFile(
  'photos/user1/photo.jpg',
  bytes,
);
print('File uploaded: $downloadUrl');
```

### Download File

```dart
final bytes = await FirebaseService.instance.downloadFile('photos/user1/photo.jpg');
```

### Get File URL

```dart
final url = await FirebaseService.instance.getFileURL('photos/user1/photo.jpg');
```

### Delete File

```dart
await FirebaseService.instance.deleteFile('photos/user1/photo.jpg');
```

## 🔧 Troubleshooting

### Error: "Google Services plugin not found"

- Make sure you added `id("com.google.gms.google-services")` to both gradle files

### Error: "google-services.json not found"

- Verify the file is at: `android/app/src/google-services.json`

### Build errors on iOS

- Run `flutter clean`
- Delete `ios/Pods` folder
- Run `flutter pub get`
- Run `flutter run`

### Firebase not initializing

- Make sure `Firebase.initializeApp()` is called before `runApp()`
- Check that `firebase_options.dart` has correct credentials

## 📚 Resources

- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Realtime Database Docs](https://firebase.google.com/docs/database)
- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Firebase Storage Docs](https://firebase.google.com/docs/storage)

## ✨ Your Firebase Credentials

- **Project ID**: chrolo-1fec8
- **Android App ID**: 1:347936820144:android:ba70bbce8ab45e4013e475
- **Android API Key**: AIzaSyDOPQ-yQ13j3XrayxpJyDeWkxgYrHS6fUo
- **Web App ID**: 1:347936820144:web:e86c9dd9c3d5c27f13e475
- **Web API Key**: AIzaSyAA0Q2vGeD83oWFSCFhwFuv6CkIvo7hgqM

---

🎉 Firebase is ready to use in your Chloro app!
