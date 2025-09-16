# 🦶 Smart Insole System - Mobile App

A Flutter mobile application for real-time visualization of Smart Insole System data featuring **3D insole visualization** with pressure mapping and IMU orientation tracking.

## 📱 Quick Start - Get APK on Your Phone

### **Method 1: Automatic Build (Recommended)**
1. **Fork this repository**
2. **Go to Actions tab** → **Build APK**
3. **Download the APK** from artifacts
4. **Install on your phone**

### **Method 2: GitHub Codespaces**
1. **Click "Code" → "Codespaces" → "Create codespace"**
2. **Wait for environment to load**
3. **Run in terminal:**
   ```bash
   flutter pub get
   flutter build apk --release
   ```
4. **Download APK** from `build/app/outputs/flutter-apk/`

## 🚀 Features

- **🦶 3D Insole Display** - Real-time rotating 3D insole model
- **🌡️ Pressure Heatmap** - Color-coded pressure zones
- **🔗 Bluetooth Connectivity** - Auto-connects to Pi Pico W
- **📊 Live Data Charts** - Historical IMU and pressure data
- **🎮 Interactive Controls** - Drag to rotate 3D view

## 🔌 Hardware Required

- **Raspberry Pi Pico W** with Smart Insole firmware
- **MPU6050 IMU** sensor
- **4x FSR sensors** (pressure zones)
- **Android phone** with Bluetooth

## 📱 Installation

1. **Enable "Install unknown apps"** in Android settings
2. **Download APK** (from GitHub Actions or Codespaces)
3. **Install on your phone**
4. **Grant Bluetooth permissions**
5. **Connect to your Smart Insole hardware**

## 🛠️ Development Setup

### Prerequisites
- Flutter 3.24.3+
- Android SDK
- Git

### Local Development
```bash
git clone https://github.com/YOUR_USERNAME/smart-insole-app.git
cd smart-insole-app
flutter pub get
flutter run
```

## 📊 Data Protocol

The app receives JSON data from Pi Pico W via Bluetooth:

```json
{
  "timestamp": 12345,
  "imu": {
    "accel": {"x": 0.123, "y": -0.456, "z": 0.987},
    "gyro": {"x": 1.23, "y": -4.56, "z": 9.87},
    "shake": false
  },
  "pressure": {
    "Heel": 25.5, "Arch": 12.3, "Ball": 45.7, "Toe": 8.9
  }
}
```

## 🎯 App Features

### 3D Visualization
- Real-time insole rotation based on IMU data
- Pressure color mapping on 3D surface
- Interactive rotation controls
- Coordinate system display

### Data Monitoring
- Live pressure readings (4 zones)
- IMU data (accelerometer + gyroscope) 
- Shake detection
- Historical data charts

### Connectivity
- Auto-discover "SmartInsole_PicoW" device
- Real-time Bluetooth data streaming
- Connection status monitoring
- Auto-reconnection

## 🔧 Configuration

### Bluetooth Device Name
Change in `bluetooth_service.dart`:
```dart
static const String TARGET_DEVICE_NAME = "SmartInsole_PicoW";
```

### 3D Model Settings
Adjust in `insole_3d_display.dart`:
```dart
const length = 120.0;     // Insole length
const width = 50.0;       // Insole width
const focalLength = 300.0; // Perspective
```

## 📄 License

MIT License - See LICENSE file for details

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## 📞 Support

For issues or questions, please create a GitHub issue.

---

**Ready to test your Smart Insole System? Build the APK and start monitoring your gait in real-time!** 🚀
