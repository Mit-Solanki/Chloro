# Firebase Database Setup Guide

## 📊 Database Structure

Your Firebase Realtime Database should have this structure:

```
chrolo-1fec8 (root)
├── sensors/
│   ├── current/
│   │   ├── temperature: 25.5
│   │   ├── humidity: 72.0
│   │   ├── soil_moisture: 65.0
│   │   └── light_intensity: 8500.0
│   └── settings/
│       ├── update_interval: 60
│       └── enabled: true
└── history/
    ├── temperature/
    │   └── readings: [
    │       { timestamp: "2026-04-01T10:30:00.000Z", value: 25.5 },
    │       { timestamp: "2026-04-01T10:31:00.000Z", value: 25.6 },
    │       ...
    │     ]
    ├── humidity/
    │   └── readings: [ ... ]
    ├── soil_moisture/
    │   └── readings: [ ... ]
    └── light_intensity/
        └── readings: [ ... ]
```

## 🔧 Firebase Console Setup

### Step 1: Create Database Paths

1. Go to [Firebase Console](https://console.firebase.google.com/project/chrolo-1fec8/database)
2. Click on **Realtime Database**
3. Click **Create Database** (if not created)
4. Start with `locked mode`, then add rules below

### Step 2: Add Security Rules

In Firebase Console → Realtime Database → Rules, paste:

```json
{
  "rules": {
    "sensors": {
      "current": {
        ".read": true,
        ".write": "auth != null || root.child('allow_anonymous').val() == true",
        ".validate": "newData.hasChildren(['temperature', 'humidity', 'soil_moisture', 'light_intensity'])"
      },
      "settings": {
        ".read": true,
        ".write": "auth != null"
      }
    },
    "history": {
      ".read": true,
      "temperature": {
        "readings": {
          ".write": "auth != null || root.child('allow_anonymous').val() == true"
        }
      },
      "humidity": {
        "readings": {
          ".write": "auth != null || root.child('allow_anonymous').val() == true"
        }
      },
      "soil_moisture": {
        "readings": {
          ".write": "auth != null || root.child('allow_anonymous').val() == true"
        }
      },
      "light_intensity": {
        "readings": {
          ".write": "auth != null || root.child('allow_anonymous').val() == true"
        }
      }
    }
  }
}
```

### Step 3: Seed Initial Data

In Firebase Console, click the **+** button next to `chrolo-1fec8` root and add:

```
Path: sensors/current

{
  "temperature": 25.5,
  "humidity": 72.0,
  "soil_moisture": 65.0,
  "light_intensity": 8500.0
}
```

## 📱 How the App Fetches Data

### Real-time Streams

The app listens to these paths:
- `sensors/current/temperature` → Updates temperature in real-time
- `sensors/current/humidity` → Updates humidity in real-time
- `sensors/current/soil_moisture` → Updates soil moisture in real-time
- `sensors/current/light_intensity` → Updates light in real-time

### History Data

The app reads historical data from:
- `history/temperature/readings` → Array of historical temperature readings
- `history/humidity/readings` → Array of historical humidity readings
- `history/soil_moisture/readings` → Array of historical soil moisture readings
- `history/light_intensity/readings` → Array of historical light readings

## 📤 Sending Data from Your Arduino/Sensor

### Update Current Values

```python
# Example Python code for your IoT device
import firebase_admin
from firebase_admin import db

# Initialize Firebase (setup credentials first)
firebase_admin.initialize_app(options={
    'databaseURL': 'https://chrolo-1fec8.firebaseio.com'
})

# Update current sensor values
ref = db.reference('sensors/current')
ref.update({
    'temperature': 25.5,
    'humidity': 72.0,
    'soil_moisture': 65.0,
    'light_intensity': 8500.0
})
```

### Save to History

```python
from datetime import datetime, timezone

# Save current reading to history
timestamp = datetime.now(timezone.utc).isoformat()

# For temperature
temp_ref = db.reference('history/temperature/readings')
temp_ref.push({
    'timestamp': timestamp,
    'value': 25.5
})

# For humidity
humidity_ref = db.reference('history/humidity/readings')
humidity_ref.push({
    'timestamp': timestamp,
    'value': 72.0
})

# Repeat for soil_moisture and light_intensity...
```

### Or Use cURL

```bash
# Update current temperature
curl -X PUT https://chrolo-1fec8.firebaseio.com/sensors/current/temperature.json?auth=YOUR_AUTH_TOKEN -d '25.5'

# Add to history
curl -X POST https://chrolo-1fec8.firebaseio.com/history/temperature/readings.json?auth=YOUR_AUTH_TOKEN \
  -H "Content-Type: application/json" \
  -d '{"timestamp":"2026-04-01T10:30:00Z","value":25.5}'
```

## ⚙️ Configuration in App

The app automatically:
1. **Fetches** historical data when the app starts
2. **Listens** for real-time changes to current sensor values
3. **Updates** history list as new readings come in
4. **Maintains** last 1440 readings (24 hours) in memory

## 🔄 Data Format Requirements

### Current Values

Must be numbers:
```json
{
  "temperature": 25.5,
  "humidity": 72.0,
  "soil_moisture": 65.0,
  "light_intensity": 8500.0
}
```

### History Readings

Array of objects with `timestamp` and `value`:
```json
{
  "readings": [
    {
      "timestamp": "2026-04-01T10:00:00.000Z",
      "value": 25.5
    },
    {
      "timestamp": "2026-04-01T10:01:00.000Z",
      "value": 25.6
    }
  ]
}
```

## 🧪 Test Data

### Generate Test History (via Firebase Console)

```json
history/temperature/readings:
[
  {"timestamp":"2026-04-01T08:00:00Z","value":20.0},
  {"timestamp":"2026-04-01T09:00:00Z","value":21.5},
  {"timestamp":"2026-04-01T10:00:00Z","value":23.0},
  {"timestamp":"2026-04-01T11:00:00Z","value":24.5},
  {"timestamp":"2026-04-01T12:00:00Z","value":26.0},
  {"timestamp":"2026-04-01T13:00:00Z","value":27.5},
  {"timestamp":"2026-04-01T14:00:00Z","value":28.0},
  {"timestamp":"2026-04-01T15:00:00Z","value":27.0}
]
```

## ✅ Verification

To verify your database is set up correctly:

1. Go to Firebase Console → Database
2. You should see:
   - ✅ `sensors/current/` with temperature, humidity, etc.
   - ✅ `history/*/readings` with array of data points
3. Run the app and check:
   - ✅ Values appear on home page
   - ✅ Clicking a card opens the history modal
   - ✅ Chart displays with historical data

## 🐛 Debugging

### No data showing?

1. Check Firebase rules allow read access
2. Verify data path matches exactly: `sensors/current/temperature`
3. Check console for errors: `Flutter: readData from...`

### Chart is empty?

1. Ensure `history/*/readings` exists
2. Data points must have `timestamp` (ISO 8601) and `value` (number)
3. Check data format in Firebase Console

### Not updating in real-time?

1. Verify Firebase write rules are correct
2. Check `streamData()` is working in console logs
3. Ensure device has internet connection

## 📚 Resources

- [Firebase Realtime Database Docs](https://firebase.google.com/docs/database)
- [Firebase REST API](https://firebase.google.com/docs/reference/rest/database)
- [ISO 8601 Timestamp Format](https://en.wikipedia.org/wiki/ISO_8601)

---

**Your Project ID**: `chrolo-1fec8`
**Database URL**: `https://chrolo-1fec8.firebaseio.com`
