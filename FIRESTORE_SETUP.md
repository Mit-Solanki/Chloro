# Firestore Database Setup Guide

## Project Information
- **Project ID**: chrolo-1fec8
- **Database Location**: US (recommended)

## Database Structure

### Collection 1: `sensors`

**Document**: `current` (stores current real-time sensor readings)

**Fields**:
```json
{
  "temperature": 25.5,          // number (°C)
  "humidity": 72.0,             // number (%)
  "soil_moisture": 65.0,        // number (%)
  "light_intensity": 8500.0     // number (lux)
}
```

---

### Collection 2: `history`

**Documents**: One for each sensor type
- `temperature`
- `humidity`
- `soil_moisture`
- `light_intensity`

Each sensor document contains a sub-collection:

**Sub-collection**: `readings` (contains historical data points)

**Document Fields** (in each reading):
```json
{
  "timestamp": "2026-04-07T14:30:00.000Z",  // ISO8601 string
  "value": 25.5                              // number
}
```

---

## Example Data Structure

```
Firestore Database
├── sensors/ (collection)
│   └── current/ (document)
│       ├── temperature: 25.5
│       ├── humidity: 72.0
│       ├── soil_moisture: 65.0
│       └── light_intensity: 8500.0
│
└── history/ (collection)
    ├── temperature/ (document)
    │   └── readings/ (sub-collection)
    │       ├── <docId>: {timestamp: "...", value: 25.5}
    │       ├── <docId>: {timestamp: "...", value: 26.1}
    │       └── ...
    │
    ├── humidity/ (document)
    │   └── readings/ (sub-collection)
    │       ├── <docId>: {timestamp: "...", value: 72.0}
    │       └── ...
    │
    ├── soil_moisture/ (document)
    │   └── readings/ (sub-collection)
    │       └── ...
    │
    └── light_intensity/ (document)
        └── readings/ (sub-collection)
            └── ...
```

---

## Steps to Set Up in Firebase Console

### 1. Create `sensors` Collection
- Go to [Firebase Console](https://console.firebase.google.com)
- Select project: **chrolo-1fec8**
- Click **Firestore Database** → **Create Database**
- Start in test mode (development)
- Click **Create Document** in `sensors` collection
- Document ID: `current`
- Add fields:
  - `temperature`: 25.5 (Number)
  - `humidity`: 72.0 (Number)
  - `soil_moisture`: 65.0 (Number)
  - `light_intensity`: 8500.0 (Number)

### 2. Create `history` Collection with Sub-collections
- Click **Add collection** → Name: `history`
- Create documents:
  - `temperature` (empty doc)
  - `humidity` (empty doc)
  - `soil_moisture` (empty doc)
  - `light_intensity` (empty doc)

### 3. Add Sub-collection `readings` to Each Sensor
For each sensor document (e.g., `temperature`):
- Click **Add subcollection** → Name: `readings`
- Add sample document with:
  - `timestamp`: "2026-04-07T14:30:00.000Z" (Timestamp)
  - `value`: 25.5 (Number)

---

## Firestore Security Rules (For Testing)

Use these rules for development:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write for testing
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **IMPORTANT**: For production, replace with secure rules!

---

## API Usage in Flutter

### Fetch Current Sensor Data
```dart
final data = await FirebaseService.instance.readData('sensors', 'current');
```

### Stream Current Sensor Data (Real-time)
```dart
FirebaseService.instance.getSensorReadings().listen((sensorData) {
  print('Temperature: ${sensorData?['temperature']}');
});
```

### Fetch History for a Sensor
```dart
final readings = await FirebaseService.instance.getHistoryReadings('temperature');
```

### Add a Reading to History
```dart
await FirebaseService.instance.addHistoryReading('temperature', {
  'timestamp': DateTime.now().toIso8601String(),
  'value': 25.5
});
```

### Stream History (Real-time)
```dart
FirebaseService.instance.streamReadings('temperature').listen((readings) {
  print('Latest 1440 readings: ${readings.length}');
});
```

---

## Data Validation

### Valid Ranges (Recommended)
- **Temperature**: -10 to 60°C
- **Humidity**: 0 to 100%
- **Soil Moisture**: 0 to 100%
- **Light Intensity**: 0 to 100000 lux

### Timestamp Format
All timestamps should be ISO8601 strings:
```
2026-04-07T14:30:00.000Z
```

---

## Next Steps

1. ✅ Firestore database created
2. ✅ Collections and structure set up
3. ✅ Dart service configured
4. **TODO**: Send sample data from IoT device or manually add test data
5. **TODO**: Verify data appears in app's home page
6. **TODO**: Check history displays on dashboard

---

## Troubleshooting

### Data Not Showing?
1. Check Firestore console for data
2. Verify security rules allow read access
3. Check app logs for errors (run: `flutter logs`)
4. Ensure you're connected to Firebase

### No History?
- History data is stored in `history/{sensorName}/readings`
- Each reading needs `timestamp` and `value` fields
- Timestamps must be ISO8601 format

### Offline Persistence Not Working?
- Works automatically on Android
- Web uses browser cache (limited)
