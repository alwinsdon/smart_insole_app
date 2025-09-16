import 'dart:convert';
import 'dart:math';

class SensorData {
  final int timestamp;
  final IMUData imu;
  final PressureData pressure;

  SensorData({
    required this.timestamp,
    required this.imu,
    required this.pressure,
  });

  factory SensorData.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return SensorData(
      timestamp: json['timestamp'] ?? 0,
      imu: IMUData.fromJson(json['imu'] ?? {}),
      pressure: PressureData.fromJson(json['pressure'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'imu': imu.toJson(),
      'pressure': pressure.toJson(),
    };
  }
}

class IMUData {
  final AccelerometerData accel;
  final GyroscopeData gyro;
  final bool shake;

  IMUData({
    required this.accel,
    required this.gyro,
    required this.shake,
  });

  factory IMUData.fromJson(Map<String, dynamic> json) {
    return IMUData(
      accel: AccelerometerData.fromJson(json['accelerometer'] ?? {}),
      gyro: GyroscopeData.fromJson(json['gyroscope'] ?? {}),
      shake: json['shake'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accel': accel.toJson(),
      'gyro': gyro.toJson(),
      'shake': shake,
    };
  }
}

class AccelerometerData {
  final double x;
  final double y;
  final double z;

  AccelerometerData({
    required this.x,
    required this.y,
    required this.z,
  });

  factory AccelerometerData.fromJson(Map<String, dynamic> json) {
    return AccelerometerData(
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      z: (json['z'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z};
  }

  // Calculate total acceleration magnitude
  double get magnitude => sqrt(x * x + y * y + z * z);

  // Get tilt angles in degrees
  double get pitch => (atan2(x, sqrt(y * y + z * z)) * 180 / pi);
  double get roll => (atan2(y, sqrt(x * x + z * z)) * 180 / pi);
}

class GyroscopeData {
  final double x;
  final double y;
  final double z;

  GyroscopeData({
    required this.x,
    required this.y,
    required this.z,
  });

  factory GyroscopeData.fromJson(Map<String, dynamic> json) {
    return GyroscopeData(
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      z: (json['z'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z};
  }

  // Calculate total rotation magnitude
  double get magnitude => sqrt(x * x + y * y + z * z);
}

class PressureData {
  final double heel;
  final double arch;
  final double ball;
  final double toe;

  PressureData({
    required this.heel,
    required this.arch,
    required this.ball,
    required this.toe,
  });

  factory PressureData.fromJson(dynamic json) {
    if (json is List) {
      // Handle array format from ESP32: [heel, arch, ball, toe]
      return PressureData(
        heel: json.length > 0 ? (json[0] ?? 0.0).toDouble() : 0.0,
        arch: json.length > 1 ? (json[1] ?? 0.0).toDouble() : 0.0,
        ball: json.length > 2 ? (json[2] ?? 0.0).toDouble() : 0.0,
        toe: json.length > 3 ? (json[3] ?? 0.0).toDouble() : 0.0,
      );
    } else if (json is Map<String, dynamic>) {
      // Handle object format
      return PressureData(
        heel: (json['Heel'] ?? 0.0).toDouble(),
        arch: (json['Arch'] ?? 0.0).toDouble(),
        ball: (json['Ball'] ?? 0.0).toDouble(),
        toe: (json['Toe'] ?? 0.0).toDouble(),
      );
    } else {
      // Default values
      return PressureData(heel: 0.0, arch: 0.0, ball: 0.0, toe: 0.0);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'Heel': heel,
      'Arch': arch,
      'Ball': ball,
      'Toe': toe,
    };
  }

  // Get total pressure
  double get totalPressure => heel + arch + ball + toe;

  // Get maximum pressure point
  String get maxPressureZone {
    final pressures = {'Heel': heel, 'Arch': arch, 'Ball': ball, 'Toe': toe};
    return pressures.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Get pressure as list for easy iteration
  List<double> get asList => [heel, arch, ball, toe];
  
  // Get pressure zones with names
  Map<String, double> get asMap => {
    'Heel': heel,
    'Arch': arch,
    'Ball': ball,
    'Toe': toe,
  };
}
