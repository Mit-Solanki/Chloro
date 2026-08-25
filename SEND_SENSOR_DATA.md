# 🔌 Sending Sensor Data to Firebase

## 📤 Overview

This guide shows how to send sensor data from your Arduino, Raspberry Pi, or server to Firebase so your Flutter app can display it.

## 🐍 Python Example (Recommended for IoT)

### Installation

```bash
pip install firebase-admin
```

### Complete Example

```python
import firebase_admin
from firebase_admin import credentials, db
from datetime import datetime, timezone
import time
import random  # For simulation - replace with actual sensor readings

# Initialize Firebase
# Download JSON key from Firebase Console → Project Settings → Service Accounts
cred = credentials.Certificate('path/to/serviceAccountKey.json')
firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://chrolo-1fec8.firebaseio.com'
})

def read_sensors():
    """
    Replace this with your actual sensor reading logic.
    For now, it returns mock data.
    """
    # Your actual sensor reading code here
    # Example: temp from DHT22, moisture from analog pin, etc.
    
    temperature = 20 + random.uniform(0, 10)  # 20-30°C
    humidity = 50 + random.uniform(0, 30)     # 50-80%
    soil_moisture = 40 + random.uniform(0, 40) # 40-80%
    light_intensity = 1000 + random.uniform(0, 8000) # 1000-9000 lux
    
    return {
        'temperature': round(temperature, 1),
        'humidity': round(humidity, 1),
        'soil_moisture': round(soil_moisture, 0),
        'light_intensity': round(light_intensity, 0)
    }

def update_current_sensors():
    """Update the current sensor values in Firebase."""
    sensors = read_sensors()
    ref = db.reference('sensors/current')
    ref.update(sensors)
    print(f"✅ Updated current sensors: {sensors}")

def save_to_history(sensor_name, value):
    """Save a sensor reading to history."""
    timestamp = datetime.now(timezone.utc).isoformat()
    history_ref = db.reference(f'history/{sensor_name}/readings')
    
    history_ref.push({
        'timestamp': timestamp,
        'value': value
    })
    print(f"✅ Saved {sensor_name}: {value} at {timestamp}")

def main_loop():
    """Main loop that updates data every minute."""
    update_interval = 60  # Update every 60 seconds
    
    while True:
        try:
            # Read all sensors
            sensors = read_sensors()
            
            # Update current values
            ref = db.reference('sensors/current')
            ref.update(sensors)
            print(f"✅ Updated at {datetime.now()}: {sensors}")
            
            # Save each to history
            for sensor_name, value in sensors.items():
                save_to_history(sensor_name, value)
            
            # Wait for next update
            time.sleep(update_interval)
            
        except Exception as e:
            print(f"❌ Error: {e}")
            print("Retrying in 10 seconds...")
            time.sleep(10)

if __name__ == "__main__":
    print("🌱 Chloro Sensor Data Publisher")
    print("Connecting to Firebase...")
    
    try:
        # Test connection
        test_ref = db.reference('sensors')
        print("✅ Connected to Firebase!")
        
        # Start main loop
        main_loop()
    except Exception as e:
        print(f"❌ Failed to connect: {e}")
```

## 🔧 Arduino/ESP32 Example

```cpp
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <time.h>
#include <DHT.h>

// Firebase configuration
#define FIREBASE_HOST "chrolo-1fec8.firebaseio.com"
#define FIREBASE_AUTH "YOUR_DATABASE_SECRET"  // Get from Firebase Console

// WiFi configuration
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// Sensor pins
#define DHT_PIN 4
#define SOIL_MOISTURE_PIN A0
#define LIGHT_PIN A1

// Create objects
DHT dht(DHT_PIN, DHT22);
FirebaseData firebaseData;

// Sensor reading interval (seconds)
const long UPDATE_INTERVAL = 60000; // 1 minute
unsigned long lastUpdate = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  // Initialize sensors
  dht.begin();
  
  // Connect to WiFi
  Serial.print("Connecting to WiFi: ");
  Serial.println(WIFI_SSID);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✓ WiFi connected");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n✗ WiFi failed");
    return;
  }
  
  // Connect to Firebase
  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  Firebase.reconnectWiFi(true);
  Serial.println("✓ Firebase initialized");
}

void loop() {
  // Check if it's time to update
  if (millis() - lastUpdate >= UPDATE_INTERVAL) {
    lastUpdate = millis();
    
    // Read sensors
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();
    int soilMoisture = analogRead(SOIL_MOISTURE_PIN);
    int lightIntensity = analogRead(LIGHT_PIN);
    
    // Check for DHT errors
    if (isnan(temperature) || isnan(humidity)) {
      Serial.println("✗ DHT sensor error");
      return;
    }
    
    // Update current sensors
    Firebase.setFloat(firebaseData, 
      "sensors/current/temperature", temperature);
    Firebase.setFloat(firebaseData, 
      "sensors/current/humidity", humidity);
    Firebase.setInt(firebaseData, 
      "sensors/current/soil_moisture", soilMoisture);
    Firebase.setInt(firebaseData, 
      "sensors/current/light_intensity", lightIntensity);
    
    // Save to history
    String timestamp = getISOTimestamp();
    
    Firebase.push(firebaseData, 
      "history/temperature/readings", 
      "{\"timestamp\":\"" + timestamp + "\",\"value\":" + temperature + "}");
    Firebase.push(firebaseData, 
      "history/humidity/readings", 
      "{\"timestamp\":\"" + timestamp + "\",\"value\":" + humidity + "}");
    Firebase.push(firebaseData, 
      "history/soil_moisture/readings", 
      "{\"timestamp\":\"" + timestamp + "\",\"value\":" + soilMoisture + "}");
    Firebase.push(firebaseData, 
      "history/light_intensity/readings", 
      "{\"timestamp\":\"" + timestamp + "\",\"value\":" + lightIntensity + "}");
    
    // Print to serial
    Serial.println("\n✓ Data updated:");
    Serial.print("  Temp: ");
    Serial.print(temperature);
    Serial.println("°C");
    Serial.print("  Humidity: ");
    Serial.print(humidity);
    Serial.println("%");
    Serial.print("  Moisture: ");
    Serial.println(soilMoisture);
    Serial.print("  Light: ");
    Serial.println(lightIntensity);
  }
}

String getISOTimestamp() {
  time_t now = time(nullptr);
  struct tm* timeinfo = gmtime(&now);
  char buffer[25];
  strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", timeinfo);
  return String(buffer);
}
```

## 🛠️ Node.js Example

```javascript
const admin = require('firebase-admin');
const cron = require('node-cron');

// Initialize Firebase
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: 'https://chrolo-1fec8.firebaseio.com'
});

const db = admin.database();

// Function to simulate or read sensors
async function readSensors() {
    // Replace with actual sensor reading logic
    return {
        temperature: 20 + Math.random() * 10,
        humidity: 50 + Math.random() * 30,
        soil_moisture: 40 + Math.random() * 40,
        light_intensity: 1000 + Math.random() * 8000
    };
}

// Update current sensor values
async function updateCurrentSensors() {
    const sensors = await readSensors();
    
    await db.ref('sensors/current').update({
        temperature: Math.round(sensors.temperature * 10) / 10,
        humidity: Math.round(sensors.humidity * 10) / 10,
        soil_moisture: Math.round(sensors.soil_moisture),
        light_intensity: Math.round(sensors.light_intensity)
    });
    
    console.log('✓ Updated sensors:', sensors);
}

// Save reading to history
async function saveToHistory(sensorName, value) {
    const timestamp = new Date().toISOString();
    
    await db.ref(`history/${sensorName}/readings`).push({
        timestamp: timestamp,
        value: value
    });
    
    console.log(`✓ Saved ${sensorName}: ${value}`);
}

// Main function
async function main() {
    console.log('🌱 Chloro Sensor Data Publisher');
    console.log('Connected to Firebase');
    
    // Update every minute
    cron.schedule('* * * * *', async () => {
        try {
            const sensors = await readSensors();
            
            // Update current
            await db.ref('sensors/current').update({
                temperature: Math.round(sensors.temperature * 10) / 10,
                humidity: Math.round(sensors.humidity * 10) / 10,
                soil_moisture: Math.round(sensors.soil_moisture),
                light_intensity: Math.round(sensors.light_intensity)
            });
            
            // Save to history
            for (const [key, value] of Object.entries(sensors)) {
                await saveToHistory(key, Math.round(value * 100) / 100);
            }
            
            console.log('✓ Update complete at', new Date().toLocaleTimeString());
        } catch (error) {
            console.error('✗ Error:', error);
        }
    });
}

main();
```

## 🌐 REST API (cURL)

### Update Current Values

```bash
# Update temperature
curl -X PUT \
  https://chrolo-1fec8.firebaseio.com/sensors/current/temperature.json \
  -H "Content-Type: application/json" \
  -d '25.5'

# Update humidity
curl -X PUT \
  https://chrolo-1fec8.firebaseio.com/sensors/current/humidity.json \
  -H "Content-Type: application/json" \
  -d '72.0'
```

### Save to History

```bash
curl -X POST \
  https://chrolo-1fec8.firebaseio.com/history/temperature/readings.json \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "2026-04-01T14:30:00Z",
    "value": 25.5
  }'
```

## 📊 Data Format Requirements

### Current Values (Must be Numbers)
```json
{
  "temperature": 25.5,
  "humidity": 72.0,
  "soil_moisture": 65.0,
  "light_intensity": 8500.0
}
```

### History (Must be ISO 8601 + Number)
```json
{
  "readings": [
    {
      "timestamp": "2026-04-01T14:30:00Z",
      "value": 25.5
    }
  ]
}
```

## ✅ Testing

1. **Start your data publisher** (Python/Node/Arduino)
2. **Watch Firebase Console**
3. **Open Flutter app**
4. **See data update in real-time!**

## 🐛 Troubleshooting

### Data not appearing?
- Check Firebase authentication
- Verify database paths match exactly
- Check internet connection
- Review Error logs

### Old data not showing?
- Firebase may have old data
- Clear history and restart: `db.ref('history').remove()`

### App not updating?
- Check real-time listeners in `dashboard_with_history.dart`
- Verify Firebase rules allow read/write

---

**Firebase Project ID**: `chrolo-1fec8`
**Database URL**: `https://chrolo-1fec8.firebaseio.com`

Choose the example that matches your hardware!
