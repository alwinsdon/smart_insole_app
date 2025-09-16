# Smart Insole Mobile App

A Flutter mobile application for real-time visualization of Smart Insole System data, featuring 3D insole visualization with pressure mapping and IMU orientation tracking.

## 🚀 Features

### ✅ **Core Features**
- **🔗 Bluetooth Connectivity** - Auto-connects to "SmartInsole_PicoW"
- **🦶 3D Insole Visualization** - Real-time rotating 3D insole model
- **🌡️ Pressure Heatmap** - Color-coded pressure zones (Heel, Arch, Ball, Toe)
- **📱 Real-time Data** - Live IMU and pressure sensor readings
- **📊 Historical Charts** - Data trend visualization
- **🎮 Interactive Controls** - Drag to rotate 3D view

### 🎯 **Advanced Features**
- **Perspective 3D Rendering** - Realistic insole shape and rotation
- **Pressure Color Mapping** - Heat map visualization on 3D model
- **Shake Detection** - Visual feedback for movement events
- **Connection Management** - Auto-reconnect and status monitoring
- **Data Export** - JSON data streaming

## 📱 Screenshots

### Main Interface
- **3D Insole Display**: Interactive 3D model showing real-time orientation
- **Pressure Visualization**: Color-coded pressure zones on the insole
- **Connection Panel**: Bluetooth status and connection controls
- **Real-time Metrics**: Live IMU and pressure readings

## 🔧 Setup Instructions

### Prerequisites
- **Flutter SDK** 3.13.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Android device** with Bluetooth support (API level 21+)
- **Smart Insole Hardware** (Pi Pico W + MPU6050 + FSR sensors)

### Installation

1. **Clone and Setup**
   ```bash
   cd smart_insole_app
   flutter pub get
   ```

2. **Permissions Setup**
   The app automatically requests required permissions:
   - Bluetooth
   - Bluetooth Connect
   - Bluetooth Scan
   - Location (required for Bluetooth discovery)

3. **Build and Run**
   ```bash
   # Debug build
   flutter run
   
   # Release build
   flutter build apk --release
   ```

## 🏗️ Architecture

### **Project Structure**
```
lib/
├── main.dart                    # App entry point with permissions
├── models/
│   └── sensor_data.dart         # Data models for IMU and pressure
├── services/
│   └── bluetooth_service.dart   # Bluetooth communication service
├── screens/
│   └── home_screen.dart         # Main app interface
└── widgets/
    ├── insole_3d_display.dart   # 3D insole visualization
    ├── pressure_heatmap.dart    # 2D pressure heatmap
    ├── connection_panel.dart    # Bluetooth connection UI
    └── data_charts.dart         # Historical data charts
```

### **Key Components**

#### **1. Insole3DDisplay Widget**
- **Real-time 3D rendering** of insole shape
- **IMU-driven rotation** (pitch, roll, yaw)
- **Interactive user controls** (drag to rotate)
- **Pressure mapping** on 3D surface
- **Coordinate system visualization**

#### **2. BluetoothService**
- **Device discovery** and auto-connection
- **JSON data parsing** from Pi Pico W
- **Connection state management**
- **Real-time data streaming**

#### **3. Data Models**
- **SensorData**: Complete data packet
- **IMUData**: Accelerometer and gyroscope data
- **PressureData**: 4-zone pressure readings
- **Automatic JSON serialization**

## 📊 Data Protocol

### **Bluetooth Communication**
The app receives JSON data packets from the Pi Pico W:

```json
{
  "timestamp": 12345,
  "imu": {
    "accel": {"x": 0.123, "y": -0.456, "z": 0.987},
    "gyro": {"x": 1.23, "y": -4.56, "z": 9.87},
    "shake": false
  },
  "pressure": {
    "Heel": 25.5,
    "Arch": 12.3,
    "Ball": 45.7,
    "Toe": 8.9
  }
}
```

### **Data Processing**
- **20Hz sampling rate** for smooth visualization
- **Real-time calculation** of tilt angles (pitch/roll)
- **Pressure percentage mapping** (0-100%)
- **Shake detection** based on acceleration threshold

## 🎨 3D Visualization Details

### **Insole 3D Model**
- **Realistic insole shape** with heel-to-toe tapering
- **Segmented pressure zones** (20 segments)
- **Dynamic color mapping** based on pressure intensity
- **Perspective projection** with depth shading

### **Color Mapping**
- **Blue → Cyan → Green → Yellow → Red** (low to high pressure)
- **Depth-based shading** for 3D effect
- **Real-time color updates** based on sensor data

### **Interactive Controls**
- **Drag to rotate**: Manual rotation for better viewing angles
- **Reset button**: Return to default orientation
- **Coordinate axes**: X (red), Y (green), Z (blue)

## 🔄 Real-time Features

### **Live Data Updates**
- **50ms refresh rate** (20 FPS)
- **Smooth animations** with interpolation
- **Connection status monitoring**
- **Automatic reconnection**

### **Visual Feedback**
- **Shake detection**: Orange highlighting when movement detected
- **Connection status**: Color-coded connection panel
- **Pressure thresholds**: Visual indicators for high pressure
- **Data quality**: Real-time validation and error handling

## 🛠️ Customization

### **Adjustable Parameters**
```dart
// In insole_3d_display.dart
const insoleLength = 120.0;     // 3D model size
const insoleWidth = 50.0;       // 3D model width
const focalLength = 300.0;      // Perspective projection
const viewDistance = 200.0;     // Camera distance

// In bluetooth_service.dart
const TARGET_DEVICE_NAME = "SmartInsole_PicoW";  // Device name
const maxHistoryLength = 100;   // Data history buffer
```

### **Color Themes**
- Modify pressure color mapping in `_getPressureColor()`
- Adjust UI theme in `main.dart`
- Customize 3D model appearance in `Insole3DPainter`

## 📱 Supported Platforms

- **✅ Android** (Primary platform)
- **⚠️ iOS** (Requires additional Bluetooth permissions setup)
- **❌ Web** (Bluetooth Serial not supported)
- **❌ Desktop** (Limited Bluetooth support)

## 🐛 Troubleshooting

### **Common Issues**

1. **Bluetooth Not Connecting**
   - Ensure Smart Insole is powered on
   - Check device is broadcasting "SmartInsole_PicoW"
   - Verify Bluetooth permissions granted
   - Try restarting Bluetooth on phone

2. **No Data Received**
   - Check JSON format from Pi Pico W
   - Verify baud rate (115200)
   - Monitor serial output for errors
   - Ensure stable power to Pi Pico W

3. **3D Visualization Issues**
   - Check IMU calibration
   - Verify accelerometer data range (±2g)
   - Monitor for data corruption
   - Restart app if rendering freezes

4. **Performance Issues**
   - Reduce data sampling rate
   - Limit history buffer size
   - Disable background apps
   - Use release build for better performance

## 🚀 Future Enhancements

### **Planned Features**
- **📊 Gait Analysis** - Step detection and analysis
- **💾 Data Export** - CSV/JSON export functionality
- **⚙️ Calibration Tools** - IMU and pressure calibration
- **📈 Advanced Analytics** - ML-based pattern recognition
- **🔊 Audio Feedback** - Voice guidance and alerts
- **☁️ Cloud Sync** - Data backup and sharing

### **Technical Improvements**
- **WebGL 3D Rendering** - Hardware-accelerated graphics
- **Multi-device Support** - Left/right foot comparison
- **Haptic Feedback** - Phone vibration for alerts
- **Offline Mode** - Local data storage and analysis

## 📄 License

MIT License - See LICENSE file for details

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/NewFeature`)
3. Commit changes (`git commit -m 'Add NewFeature'`)
4. Push to branch (`git push origin feature/NewFeature`)
5. Open Pull Request

---

**Note**: This app is designed for research and fitness applications. For medical use, consult healthcare professionals and follow appropriate regulatory guidelines.
