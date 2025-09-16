import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/sensor_data.dart';

class BluetoothService extends ChangeNotifier {
  static const String TARGET_DEVICE_NAME = "SmartInsole_PicoW";
  
  BluetoothConnection? _connection;
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  bool _isConnecting = false;
  bool _isConnected = false;
  String _connectionStatus = "Disconnected";
  
  // Data stream
  final StreamController<SensorData> _dataStreamController = 
      StreamController<SensorData>.broadcast();
  
  // Connection status getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get connectionStatus => _connectionStatus;
  BluetoothState get bluetoothState => _bluetoothState;
  Stream<SensorData> get dataStream => _dataStreamController.stream;
  
  BluetoothService() {
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    try {
      _bluetoothState = await FlutterBluetoothSerial.instance.state;
      
      // Listen to Bluetooth state changes
      FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
        _bluetoothState = state;
        notifyListeners();
        
        if (state == BluetoothState.STATE_OFF) {
          _disconnect();
        }
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing Bluetooth: $e');
    }
  }

  Future<bool> enableBluetooth() async {
    if (_bluetoothState != BluetoothState.STATE_ON) {
      try {
        await FlutterBluetoothSerial.instance.requestEnable();
        return true;
      } catch (e) {
        debugPrint('Error enabling Bluetooth: $e');
        return false;
      }
    }
    return true;
  }

  Future<List<BluetoothDevice>> getAvailableDevices() async {
    try {
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      debugPrint('Error getting bonded devices: $e');
      return [];
    }
  }

  Future<BluetoothDevice?> findSmartInsoleDevice() async {
    try {
      final devices = await getAvailableDevices();
      
      for (var device in devices) {
        if (device.name?.contains(TARGET_DEVICE_NAME) == true) {
          return device;
        }
      }
      
      // If not found in bonded devices, try discovery
      return await _discoverSmartInsoleDevice();
    } catch (e) {
      debugPrint('Error finding Smart Insole device: $e');
      return null;
    }
  }

  Future<BluetoothDevice?> _discoverSmartInsoleDevice() async {
    try {
      _updateConnectionStatus("Scanning for devices...");
      
      final discovery = FlutterBluetoothSerial.instance.startDiscovery();
      
      await for (BluetoothDiscoveryResult result in discovery) {
        if (result.device.name?.contains(TARGET_DEVICE_NAME) == true) {
          FlutterBluetoothSerial.instance.cancelDiscovery();
          return result.device;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error during device discovery: $e');
      return null;
    }
  }

  Future<bool> connectToSmartInsole() async {
    if (_isConnecting || _isConnected) return false;
    
    try {
      _isConnecting = true;
      _updateConnectionStatus("Searching for Smart Insole...");
      notifyListeners();
      
      final device = await findSmartInsoleDevice();
      if (device == null) {
        _updateConnectionStatus("Smart Insole not found");
        _isConnecting = false;
        notifyListeners();
        return false;
      }
      
      return await connectToDevice(device);
    } catch (e) {
      debugPrint('Error connecting to Smart Insole: $e');
      _updateConnectionStatus("Connection failed: $e");
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _updateConnectionStatus("Connecting to ${device.name}...");
      
      _connection = await BluetoothConnection.toAddress(device.address);
      
      if (_connection?.isConnected == true) {
        _isConnected = true;
        _isConnecting = false;
        _updateConnectionStatus("Connected to ${device.name}");
        
        // Start listening to data
        _startDataListener();
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      _updateConnectionStatus("Connection failed");
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  void _startDataListener() {
    if (_connection == null) return;
    
    String buffer = '';
    
    _connection!.input!.listen(
      (Uint8List data) {
        try {
          String received = utf8.decode(data);
          buffer += received;
          
          // Process complete JSON lines
          while (buffer.contains('\n')) {
            int lineEnd = buffer.indexOf('\n');
            String line = buffer.substring(0, lineEnd).trim();
            buffer = buffer.substring(lineEnd + 1);
            
            if (line.isNotEmpty) {
              _processDataLine(line);
            }
          }
        } catch (e) {
          debugPrint('Error processing received data: $e');
        }
      },
      onError: (error) {
        debugPrint('Connection error: $error');
        _disconnect();
      },
      onDone: () {
        debugPrint('Connection closed by remote device');
        _disconnect();
      },
    );
  }

  void _processDataLine(String line) {
    try {
      final sensorData = SensorData.fromJson(line);
      _dataStreamController.add(sensorData);
    } catch (e) {
      debugPrint('Error parsing sensor data: $e');
      debugPrint('Raw data: $line');
    }
  }

  Future<void> disconnect() async {
    await _disconnect();
  }

  Future<void> _disconnect() async {
    try {
      _isConnected = false;
      _isConnecting = false;
      _updateConnectionStatus("Disconnected");
      
      await _connection?.close();
      _connection = null;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  void _updateConnectionStatus(String status) {
    _connectionStatus = status;
    debugPrint('Bluetooth: $status');
  }

  @override
  void dispose() {
    _disconnect();
    _dataStreamController.close();
    super.dispose();
  }
}
