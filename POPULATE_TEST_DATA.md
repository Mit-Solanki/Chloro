# Populating Firestore with Test Data

## Option 1: Firebase Console (Easiest)

### Step 1: Create Current Sensor Document
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select **chrolo-1fec8** project
3. Click **Firestore Database**
4. Create the document structure:

```
Collection: sensors
  ├─ Document ID: current
     ├─ temperature: 25.5 (Number)
     ├─ humidity: 72.0 (Number)
     ├─ soil_moisture: 65.0 (Number)
     └─ light_intensity: 8500.0 (Number)
```

### Step 2: Create History Collections
1. Create collection: `history`
2. Add documents with IDs: `temperature`, `humidity`, `soil_moisture`, `light_intensity`
3. For each document, add subcollection `readings` with sample data:

For example, in `history/temperature/readings`:
```
Document ID: 1
├─ timestamp: "2026-04-07T14:30:00.000Z" (Timestamp)
└─ value: 25.5 (Number)

Document ID: 2
├─ timestamp: "2026-04-07T14:31:00.000Z" (Timestamp)
└─ value: 25.6 (Number)
```

---

## Option 2: Node.js Script (Recommended for Bulk Data)

### Prerequisites
```bash
npm install firebase-admin
```

### Script: `populate_firestore.js`

```javascript
const admin = require('firebase-admin');

// Initialize Firebase (download JSON key from console)
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'chrolo-1fec8'
});

const db = admin.firestore();

async function populateFirestore() {
  try {
    console.log('📝 Starting Firestore population...');

    // 1. Set current sensor values
    await db.collection('sensors').doc('current').set({
      temperature: 25.5,
      humidity: 72.0,
      soil_moisture: 65.0,
      light_intensity: 8500.0,
      timestamp: new Date().toISOString()
    });
    console.log('✅ Current sensor values set');

    // 2. Populate history for each sensor
    const sensors = ['temperature', 'humidity', 'soil_moisture', 'light_intensity'];
    const sampleValues = {
      temperature: [23.0, 24.5, 25.0, 25.5, 26.0, 25.8, 25.2],
      humidity: [65.0, 68.0, 70.0, 72.0, 71.0, 70.5, 71.5],
      soil_moisture: [55.0, 58.0, 60.0, 62.0, 65.0, 64.0, 63.0],
      light_intensity: [7000, 7500, 8000, 8500, 8200, 8100, 8300]
    };

    for (const sensor of sensors) {
      // Create sensor document (if it doesn't exist)
      await db.collection('history').doc(sensor).set({
        createdAt: new Date().toISOString()
      });

      // Add readings
      const values = sampleValues[sensor];
      for (let i = 0; i < values.length; i++) {
        const minutesAgo = (values.length - 1 - i) * 60; // Space readings by 1 minute
        const timestamp = new Date(Date.now() - minutesAgo * 1000);

        await db
          .collection('history')
          .doc(sensor)
          .collection('readings')
          .add({
            timestamp: timestamp.toISOString(),
            value: values[i]
          });
      }
      console.log(`✅ Added ${values.length} readings for ${sensor}`);
    }

    console.log('✨ Firestore population complete!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

populateFirestore();
```

### Download Service Account Key
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Settings ⚙️ → Project Settings → Service Accounts
3. Click "Generate Private Key" → Save as `serviceAccountKey.json`
4. Run: `node populate_firestore.js`

---

## Option 3: Flutter App Method

Add this method to your app for testing:

```dart
// In services/firebase_service.dart or a test file
Future<void> populateTestData() async {
  try {
    print('📝 Populating test data...');

    // Set current values
    await writeData('sensors', 'current', {
      'temperature': 25.5,
      'humidity': 72.0,
      'soil_moisture': 65.0,
      'light_intensity': 8500.0,
    });

    // Add sample history
    final sensors = ['temperature', 'humidity', 'soil_moisture', 'light_intensity'];
    final values = {
      'temperature': [23.0, 24.5, 25.0, 25.5, 26.0, 25.8, 25.2],
      'humidity': [65.0, 68.0, 70.0, 72.0, 71.0, 70.5, 71.5],
      'soil_moisture': [55.0, 58.0, 60.0, 62.0, 65.0, 64.0, 63.0],
      'light_intensity': [7000, 7500, 8000, 8500, 8200, 8100, 8300]
    };

    for (final sensor in sensors) {
      final sensorValues = values[sensor] ?? [];
      for (int i = 0; i < sensorValues.length; i++) {
        final minutesAgo = (sensorValues.length - 1 - i);
        final timestamp = DateTime.now().subtract(Duration(minutes: minutesAgo));

        await addHistoryReading(sensor, {
          'timestamp': timestamp.toIso8601String(),
          'value': sensorValues[i],
        });
      }
      print('✅ Added ${sensorValues.length} readings for $sensor');
    }

    print('✨ Test data population complete!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

Then call it from `main()` or in a debug menu:
```dart
// During testing only
await FirebaseService.instance.populateTestData();
```

---

## Verify Data in App

After populating data:

1. **Compile and run**:
   ```bash
   flutter run
   ```

2. **Check home page**:
   - You should see sensor values displayed
   - Real-time updates when values change

3. **Check dashboard**:
   - Click on sensor cards
   - You should see history charts

4. **View logs**:
   ```bash
   flutter logs
   ```
   Look for:
   - `✅ Firestore initialized successfully`
   - `📖 Getting history for...`
   - `📡 Getting current sensor readings`

---

## Sample Data Constants

Use these values for consistent testing:

| Sensor | Unit | Min | Normal | Max |
|--------|------|-----|--------|-----|
| Temperature | °C | 15 | 25.5 | 35 |
| Humidity | % | 40 | 72 | 90 |
| Soil Moisture | % | 30 | 65 | 85 |
| Light Intensity | lux | 1000 | 8500 | 20000 |

---

## Troubleshooting

### "Permission denied" error?
- Check Firestore security rules (should allow test mode)
- Go to Firestore → Rules → Use test mode rules

### Data not appearing?
- Refresh the app
- Check browser console for errors
- Verify collection names match exactly (case-sensitive)

### Timestamps not showing correctly?
- Ensure format is ISO8601: `YYYY-MM-DDTHH:MM:SS.sssZ`
- Example: `2026-04-07T14:30:00.000Z`

---

## Next Steps

Once data is populated:
1. ✅ See sensor values on home page
2. ✅ See history charts on dashboard
3. ✅ Test real-time updates (manually change values in Firestore)
4. Test with real IoT device data
