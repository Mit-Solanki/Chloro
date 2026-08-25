# Chloro Smart Plant Pot - Firebase Connection Fix & Setup Guide

## ✅ Fixed Issues

### Problems Fixed
1. **LateInitializationError** - `_firestore` field was never initialized
2. **Async Initialization Issue** - Firebase initialization was happening synchronously before Firebase was ready
3. **Firestore Not Ready** - All Firestore operations were failing because the service wasn't properly initialized

### Changes Made

#### 1. `lib/services/firebase_service.dart`
✅ Changed `late final _firestore` to `late _firestore` with `_initialized` flag
✅ Made `_initializeFirestore()` async with proper error handling
✅ Added `_ensureInitialized()` check before all Firestore operations
✅ Improved error handling to return empty lists instead of throwing on failures
✅ Fixed stream error handling

#### 2. `lib/main.dart`
✅ Added explicit call to `FirebaseService.instance.initializeFirestore()` after Firebase initialization
✅ Now Firebase is fully initialized BEFORE Firestore service is set up
✅ Proper sequential initialization: Firebase → FirebaseService → App

#### 3. `lib/screens/dashboard_with_history.dart`
✅ Improved error handling in history fetching methods
✅ Better null safety checks in real-time listeners
✅ All history methods now check if mounted before updating state

## 🗄️ Firestore Database Setup (Required)

### Step 1: Create the Database Structure

Go to Firebase Console → Firestore Database and create the following structure:

**Collection: `sensors`**
```
sensors/
  └── current (document)
      ├── temperature: 25.5 (number - e.g., Celsius)
      ├── humidity: 72.0 (number - percentage %)
      ├── soil_moisture: 65.0 (number - percentage %)
      └── light_intensity: 8500.0 (number - lux)
```

### Step 2: Create Historical Data Collections

**Collection: `history` with Sub-collections**

Create these sub-collections under `history/`:

1. **`history/temperature/readings`** (sub-collection)
   - Auto-generated document IDs
   - Fields in each document:
     - `timestamp`: "2025-01-07T10:30:00.000Z" (string, ISO 8601 format)
     - `value`: 25.5 (number)

2. **`history/humidity/readings`** (sub-collection)
   - Fields:
     - `timestamp`: ISO 8601 string
     - `value`: number (0-100)

3. **`history/soil_moisture/readings`** (sub-collection)
   - Fields:
     - `timestamp`: ISO 8601 string
     - `value`: number (0-100)

4. **`history/light_intensity/readings`** (sub-collection)
   - Fields:
     - `timestamp`: ISO 8601 string
     - `value`: number (lux)

### Step 3: Create Firebase Indexes

For optimal query performance, create composite indexes:

**For each sensor history collection**, create an index:
- Collection: `history/{sensorName}/readings`
- Fields: `timestamp` (Descending)
- Query Scope: Collection

Steps in Firebase Console:
1. Go to Firestore Database → Indexes
2. Click "Create Index"
3. Set Collection to `history/{sensorName}/readings`
4. Add field `timestamp` with Descending order
5. Repeat for all 4 sensor types

### Step 4: Add Sample Data to Firestore

You can add sample historical data manually or use a script. Here's sample data to add:

**Option A: Manual Addition (via Firebase Console)**

1. Go to Firestore Database
2. Click on `history` collection
3. Create document: `temperature`
4. Inside, create sub-collection: `readings`
5. Add documents with:
   ```
   timestamp: 2025-01-07T10:00:00.000Z
   value: 24.5
   ```
6. Add more documents with different timestamps and values

**Option B: Add via Code (create a test function)**

In your `main.dart` or a separate test file:
```dart
Future<void> _populateTestData() async {
  final db = FirebaseFirestore.instance;
  
  // Add current sensor data
  await db.collection('sensors').doc('current').set({
    'temperature': 25.5,
    'humidity': 72.0,
    'soil_moisture': 65.0,
    'light_intensity': 8500.0,
  });
  
  // Add historical temperature data
  for (int i = 0; i < 50; i++) {
    await db
        .collection('history')
        .doc('temperature')
        .collection('readings')
        .add({
          'timestamp': DateTime.now().subtract(Duration(minutes: i)).toIso8601String(),
          'value': 24.0 + (i * 0.1),
        });
  }
  
  print('Test data added successfully!');
}
```

### Step 5: Set Firestore Security Rules

Go to Firebase Console → Firestore Database → Rules

Replace with:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to all
    match /sensors/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /history/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Default deny for security
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

Click "Publish" to apply these rules.

## 📲 Running the App

### Android
```bash
flutter run
```

### Web
```bash
flutter run -d chrome
```

## ✅ Verification Checklist

After setting up:

- [ ] Created `sensors/current` document with all 4 sensor fields
- [ ] Created `history/temperature/readings` sub-collection with sample data
- [ ] Created `history/humidity/readings` sub-collection with sample data
- [ ] Created `history/soil_moisture/readings` sub-collection with sample data
- [ ] Created `history/light_intensity/readings` sub-collection with sample data
- [ ] Updated Firestore Security Rules
- [ ] Created composite indexes for timestamp queries
- [ ] App launches without initialization errors
- [ ] Dashboard shows sensor values from `sensors/current`
- [ ] Charts display historical data from `history/{sensorName}/readings`

## 🧪 Testing Real-Time Updates

To test real-time updates:

1. Launch the app on Android/Web
2. Open Firebase Console → Firestore Database in another window
3. Edit the `sensors/current` document
4. Change any sensor value (e.g., temperature: 25.5 → 30.0)
5. Watch the app update in real-time!

## 📊 Data Flow

```
Firestore Database
    ├── sensors/current
    │   ├── temperature ──→ Dashboard (real-time)
    │   ├── humidity ─────→ Dashboard (real-time)
    │   ├── soil_moisture → Dashboard (real-time)
    │   └── light_intensity → Dashboard (real-time)
    │
    └── history/
        ├── temperature/readings ──→ Temperature Graph
        ├── humidity/readings ─────→ Humidity Graph
        ├── soil_moisture/readings → Soil Moisture Graph
        └── light_intensity/readings → Light Graph
```

## 🐛 Debugging

If you still see errors:

1. **Check Firebase Console Logs**
   - Firebase Console → Project Settings → App Check (if enabled)
   - Verify project ID matches: `chrolo-1fec8`

2. **Check Logcat Output** (Android)
   - Look for Firebase initialization messages
   - Should see: `✅ Firestore initialized successfully`

3. **Verify Data Exists**
   - Firebase Console → Firestore → Collections
   - Confirm `sensors/current` document exists
   - Confirm at least one history sub-collection exists

4. **Reset & Rebuild**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## 📝 Important Notes

- **Timestamps** must be in ISO 8601 format: `YYYY-MM-DDTHH:MM:SS.fffZ`
- **Historical data** is limited to last 1440 data points (24 hours at 1-minute intervals)
- **Real-time updates** stream automatically when database changes
- **No fake data** - app only shows data from Firestore (or single current value as fallback)

## 🎯 Expected Result

After setup, you should see:
1. ✅ App launches without errors
2. ✅ Dashboard displays real sensor values from `sensors/current`
3. ✅ Each sensor card shows a mini chart from historical data
4. ✅ Clicking sensor cards opens detailed history modals
5. ✅ Graphs update in real-time as Firestore data changes
6. ✅ No more "LateInitializationError" or "Field '_firestore' has not been initialized"

---

If you need more sample data, you can use the script below to populate your Firestore with realistic historical data.
