import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/sensor_data.dart';

class SmartInsoleBluetoothService extends ChangeNotifier {
  static const String targetDeviceName = "SmartInsole_ESP32";
  
  BluetoothDevice? _connectedDevice;
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _dataSubscription;
  
  bool _isScanning = false;
  bool _isConnected = false;
  bool _isConnecting = false;
  List<BluetoothDevice> _discoveredDevices = [];
  SensorData? _latestData;
  String _connectionStatus = 'Disconnected';
  final StreamController<SensorData> _dataStreamController = StreamController<SensorData>.broadcast();

  // Getters
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;
  SensorData? get latestData => _latestData;
  String get connectionStatus => _connectionStatus;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  Stream<SensorData> get dataStream => _dataStreamController.stream;

  // For UI compatibility
  BluetoothState get bluetoothState => _isConnected ? BluetoothState.on : BluetoothState.off;

  SmartInsoleBluetoothService() {
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    try {
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled != true) {
        _updateConnectionStatus('Bluetooth disabled');
      } else {
        _updateConnectionStatus('Bluetooth ready');
      }
    } catch (e) {
      print('Error initializing Bluetooth: $e');
      _updateConnectionStatus('Bluetooth error');
    }
  }

  Future<void> enableBluetooth() async {
    try {
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled != true) {
        await FlutterBluetoothSerial.instance.requestEnable();
        _updateConnectionStatus('Bluetooth enabled');
      }
    } catch (e) {
      print('Error enabling Bluetooth: $e');
      _updateConnectionStatus('Failed to enable Bluetooth');
    }
  }

  Future<void> startScanning() async {
    if (_isScanning) return;
    
    try {
      _isScanning = true;
      _discoveredDevices.clear();
      _updateConnectionStatus('Scanning for devices...');
      notifyListeners();

      // Get bonded devices first
      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      
      for (BluetoothDevice device in bondedDevices) {
        if (device.name != null && device.name!.contains('SmartInsole')) {
          _discoveredDevices.add(device);
          notifyListeners();
        }
      }
      
      // Start discovery for new devices
      _updateConnectionStatus('Discovering devices...');
      
      await for (BluetoothDiscoveryResult result in FlutterBluetoothSerial.instance.startDiscovery()) {
        if (result.device.name != null && result.device.name!.contains('SmartInsole')) {
          if (!_discoveredDevices.any((d) => d.address == result.device.address)) {
            _discoveredDevices.add(result.device);
            notifyListeners();
          }
        }
      }
      
      _isScanning = false;
      _updateConnectionStatus(_discoveredDevices.isEmpty ? 'No devices found' : 'Scan complete');
      notifyListeners();
    } catch (e) {
      print('Error during scanning: $e');
      _isScanning = false;
      _updateConnectionStatus('Scan failed');
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnecting || _isConnected) return;
    
    try {
      _isConnecting = true;
      _connectedDevice = device;
      _updateConnectionStatus('Connecting to ${device.name}...');
      notifyListeners();

      // Simple connection without timeout - let it take time if needed
      _connection = await BluetoothConnection.toAddress(device.address);
      
      _isConnecting = false;
      _isConnected = true;
      _updateConnectionStatus('Connected to ${device.name}');
      notifyListeners();

      // Start listening to data - simple approach
      _dataSubscription = _connection!.input!.listen(
        _onDataReceived,
        onError: (error) {
          print('Connection error: $error');
          disconnect();
        },
        onDone: () {
          print('Connection closed');
          disconnect();
        },
      );

      print('Successfully connected to ${device.name}');

    } catch (e) {
      print('Error connecting to device: $e');
      _isConnecting = false;
      _isConnected = false;
      _connection = null;
      _connectedDevice = null;
      _updateConnectionStatus('Connection failed: $e');
      notifyListeners();
    }
  }

  Future<void> connectToSmartInsole() async {
    // Find and connect to SmartInsole device
    await startScanning();
    
    BluetoothDevice? targetDevice = _discoveredDevices.firstWhere(
      (device) => device.name?.contains('SmartInsole') == true,
      orElse: () => throw Exception('SmartInsole device not found'),
    );
    
    await connectToDevice(targetDevice);
  }

  void _onDataReceived(Uint8List data) {
    try {
      String jsonString = String.fromCharCodes(data).trim();
      
      // Handle multiple JSON objects in one packet
      List<String> lines = jsonString.split('\n');
      
      for (String line in lines) {
        line = line.trim();
        if (line.isNotEmpty && line.startsWith('{') && line.endsWith('}')) {
          try {
            Map<String, dynamic> jsonData = json.decode(line);
            
            // Only process sensor_data type messages
            if (jsonData['type'] == 'sensor_data') {
              SensorData sensorData = SensorData.fromJson(line);
              _latestData = sensorData;
              _dataStreamController.add(sensorData);
              notifyListeners();
              print('Sensor data received and parsed successfully');
            }
          } catch (e) {
            print('Error parsing JSON line: $line, Error: $e');
          }
        }
      }
    } catch (e) {
      print('Error processing received data: $e');
    }
  }

  // Removed auto-reconnection to prevent connection loops

  Future<void> disconnect() async {
    try {
      await _dataSubscription?.cancel();
      _dataSubscription = null;
      
      await _connection?.close();
      _connection = null;
      
      _isConnected = false;
      _isConnecting = false;
      _connectedDevice = null;
      _latestData = null;
      
      _updateConnectionStatus('Disconnected');
      notifyListeners();
    } catch (e) {
      print('Error during disconnect: $e');
    }
  }

  void _updateConnectionStatus(String status) {
    _connectionStatus = status;
    print('Bluetooth Status: $status');
  }

  @override
  void dispose() {
    disconnect();
    _dataStreamController.close();
    super.dispose();
  }
}

// Enum for compatibility with old code
enum BluetoothState {
  on,
  off,
  unknown,
}