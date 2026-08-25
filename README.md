# 🌱 Chloro - Smart Plant Pot

A comprehensive Flutter application for real-time plant monitoring with Firebase integration. Chloro connects to IoT sensors to track soil moisture, temperature, humidity, and light levels, providing plant care insights through an intuitive dashboard and detailed analytics.

## 📱 Features

### Core Functionality
- **Real-Time Sensor Monitoring** - Live tracking of soil moisture, temperature, humidity, and light levels
- **Plant Status Detection** - Automatic plant health status evaluation (Healthy, Thirsty, At Risk, etc.)
- **Interactive Dashboard** - Visual display of current sensor readings with status indicators
- **Historical Analytics** - Track sensor data trends over time with detailed charts and statistics
- **Multi-Platform Support** - Works on Android, iOS, Web, Windows, macOS, and Linux

### User-Friendly Design
- **Material Design 3** - Modern UI with smooth animations and responsive layouts
- **Real-Time Updates** - Firebase Realtime Database for instant data synchronization
- **Chart Visualizations** - Interactive line charts powered by `fl_chart` showing historical trends
- **Splash Screen** - Custom introduction screen with app branding

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.11.3)
- Dart SDK (^3.11.3)
- Firebase project configured
- Git for version control

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd Chloro
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
   - Download `google-services.json` from Firebase Console
   - Place it in `android/app/src/`
   - For iOS, download `GoogleService-Info.plist` and add to `ios/Runner/` folder
   - Update `lib/firebase_options.dart` with your Firebase credentials

4. **Run the app**
```bash
flutter run
```

## 📋 Project Structure

```
lib/
├── main.dart                      # App entry point with Firebase initialization
├── models.dart                    # Data models (SensorData, HistoryDataPoint, etc.)
├── firebase_options.dart          # Firebase configuration for all platforms
├── firebase_init_native.dart      # Native platform Firebase initialization
├── firebase_init_web.dart         # Web platform Firebase initialization
├── firebase_init_stub.dart        # Stub for build purposes
├── screens/                       # App screens
│   ├── dashboard.dart             # Main dashboard with sensor cards
│   ├── splash.dart                # Splash screen
│   └── ...
├── services/                      # Business logic services
│   ├── firebase_service.dart      # Firebase operations
│   └── ...
└── widgets/                       # Reusable UI components
    ├── sensor_card.dart           # Sensor data cards
    ├── history_modal.dart         # History detail modal
    └── ...
```

## 🔧 Key Technologies

- **Flutter** - Cross-platform UI framework
- **Firebase Core** - Backend services
- **Firebase Realtime Database** - Real-time data storage and synchronization
- **fl_chart** - Interactive charting library
- **intl** - Internationalization support

## 📊 Main Components

### Dashboard Tab
Displays the current plant status and live sensor readings:
- Plant Health Status with color-coded indicator
- Soil Moisture percentage
- Temperature in Celsius
- Humidity percentage
- Light level readings

### History Tab
Tracks sensor data over time with:
- Line charts showing historical trends
- Min, max, and average statistics
- Detailed data points with timestamps
- Interactive modal dialogs for in-depth analysis

### Sensor Card Widget
Reusable component featuring:
- Current sensor value
- Translucent background chart
- Click-to-expand functionality
- Customizable colors and icons

## 🔐 Firebase Setup

This project uses Firebase for real-time data synchronization. See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for:
- Complete Firebase configuration guide
- Platform-specific setup instructions
- Firestore/Realtime Database setup

## 📚 Documentation

- [Firebase Setup Guide](FIREBASE_SETUP.md) - Firebase integration instructions
- [Firebase Database Guide](FIREBASE_DATABASE_SETUP.md) - Database configuration
- [History Feature Guide](HISTORY_FEATURE_GUIDE.md) - Implementing data history views
- [Send Sensor Data Guide](SEND_SENSOR_DATA.md) - Guide for IoT device data transmission

## 🐛 Troubleshooting

### Common Issues
- **Firebase initialization errors** - Ensure `google-services.json` is in the correct location
- **iOS build failures** - Run `flutter clean` and `flutter pub get`
- **Database connection timeouts** - Verify Firebase Realtime Database rules allow read/write access

## 📝 Development Notes

- **Platforms Supported**: Android, iOS, Web, Windows, macOS, Linux
- **Material Design**: Uses ColorScheme derived from green seed color
- **State Management**: Widget-based state management with `StatefulWidget`

## 🤝 Contributing

Feel free to fork, enhance, and submit pull requests for improvements.

## 📄 License

This project is private and not for public distribution.

---

**Happy Gardening! 🌿**
