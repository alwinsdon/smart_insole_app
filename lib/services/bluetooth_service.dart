import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/sensor_data.dart';

class BluetoothService extends ChangeNotifier {
  static const String serviceUUID = "12345678-1234-1234-1234-123456789abc";
  static const String characteristicUUID = "87654321-4321-4321-4321-cba987654321";
  
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _dataCharacteristic;
  StreamSubscription<List<int>>? _dataSubscription;
  
  bool _isScanning = false;
  bool _isConnected = false;
  List<BluetoothDevice> _discoveredDevices = [];
  SensorData? _latestData;
  String _connectionStatus = 'Disconnected';
  
  // Getters
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;
  SensorData? get latestData => _latestData;
  String get connectionStatus => _connectionStatus;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  BluetoothService() {
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    // Check if Bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      _updateConnectionStatus('Bluetooth not supported');
      return;
    }

    // Listen to Bluetooth adapter state
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        _updateConnectionStatus('Bluetooth ready');
      } else {
        _updateConnectionStatus('Bluetooth ${state.name}');
        if (_isConnected) {
          disconnect();
        }
      }
    });
  }

  Future<void> startScanning() async {
    if (_isScanning) return;
    
    _discoveredDevices.clear();
    _isScanning = true;
    _updateConnectionStatus('Scanning for devices...');
    notifyListeners();

    try {
      // Start scanning for devices with our service UUID
      await FlutterBluePlus.startScan(
        withServices: [Guid(serviceUUID)],
        timeout: const Duration(seconds: 10),
      );

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (!_discoveredDevices.contains(result.device)) {
            // Only add devices that advertise our service or have recognizable name
            if (result.advertisementData.serviceUuids.contains(Guid(serviceUUID)) ||
                result.device.platformName.toLowerCase().contains('smartinsole') ||
                result.device.platformName.toLowerCase().contains('pico')) {
              _discoveredDevices.add(result.device);
              notifyListeners();
            }
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 10));
      await stopScanning();
      
    } catch (e) {
      _updateConnectionStatus('Scan error: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScanning() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    if (_discoveredDevices.isEmpty) {
      _updateConnectionStatus('No devices found');
    } else {
      _updateConnectionStatus('Found ${_discoveredDevices.length} device(s)');
    }
    notifyListeners();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnected || _connectedDevice != null) {
      await disconnect();
    }

    try {
      _updateConnectionStatus('Connecting to ${device.platformName}...');
      
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      _isConnected = true;
      
      _updateConnectionStatus('Connected! Discovering services...');
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      // Find our service and characteristic
      for (BluetoothService service in services) {
        if (service.uuid == Guid(serviceUUID)) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid == Guid(characteristicUUID)) {
              _dataCharacteristic = characteristic;
              
              // Subscribe to notifications
              await characteristic.setNotifyValue(true);
              _dataSubscription = characteristic.lastValueStream.listen(
                _onDataReceived,
                onError: (error) {
                  debugPrint('Characteristic stream error: $error');
                  _updateConnectionStatus('Data stream error');
                },
              );
              
              _updateConnectionStatus('Connected and receiving data');
              notifyListeners();
              return;
            }
          }
        }
      }
      
      _updateConnectionStatus('Service/characteristic not found');
      await disconnect();
      
    } catch (e) {
      debugPrint('Connection error: $e');
      _updateConnectionStatus('Connection failed: $e');
      _isConnected = false;
      _connectedDevice = null;
      notifyListeners();
    }
  }

  void _onDataReceived(List<int> data) {
    try {
      String jsonString = utf8.decode(data);
      debugPrint('Received data: $jsonString');
      
      _latestData = SensorData.fromJson(jsonString);
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error parsing received data: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await _dataSubscription?.cancel();
      _dataSubscription = null;
      
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
      
    } catch (e) {
      debugPrint('Disconnect error: $e');
    } finally {
      _connectedDevice = null;
      _dataCharacteristic = null;
      _isConnected = false;
      _latestData = null;
      _updateConnectionStatus('Disconnected');
      notifyListeners();
    }
  }

  void _updateConnectionStatus(String status) {
    _connectionStatus = status;
    debugPrint('Bluetooth status: $status');
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}