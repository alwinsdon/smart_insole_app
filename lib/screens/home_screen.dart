import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../models/sensor_data.dart';
import '../widgets/pressure_heatmap.dart';
import '../widgets/insole_3d_display.dart';
import '../widgets/connection_panel.dart';
import '../widgets/data_charts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SensorData? _latestData;
  final List<SensorData> _dataHistory = [];
  static const int maxHistoryLength = 100; // Keep last 100 samples

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Insole System'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<BluetoothService>(
        builder: (context, bluetoothService, child) {
          return StreamBuilder<SensorData>(
            stream: bluetoothService.dataStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _latestData = snapshot.data!;
                _dataHistory.add(_latestData!);
                
                // Keep history size manageable
                if (_dataHistory.length > maxHistoryLength) {
                  _dataHistory.removeAt(0);
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connection Status Panel
                    const ConnectionPanel(),
                    const SizedBox(height: 20),
                    
                    if (_latestData != null) ...[
                      // Real-time Data Display
                      _buildDataOverview(_latestData!),
                      const SizedBox(height: 20),
                      
                      // 3D Insole Display (main feature)
                      Insole3DDisplay(
                        imuData: _latestData!.imu,
                        pressureData: _latestData!.pressure,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Pressure Heatmap (secondary view)
                      PressureHeatmap(
                        pressureData: _latestData!.pressure,
                      ),
                      const SizedBox(height: 20),
                      
                      // Data Charts
                      if (_dataHistory.isNotEmpty)
                        DataCharts(dataHistory: _dataHistory),
                        
                    ] else if (bluetoothService.isConnected) ...[
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Waiting for sensor data...'),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.bluetooth_disabled,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Connect to Smart Insole to view data',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDataOverview(SensorData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-time Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // IMU Data
            _buildDataSection(
              'IMU Sensor',
              [
                'Acceleration: ${data.imu.accel.magnitude.toStringAsFixed(2)}g',
                'Gyroscope: ${data.imu.gyro.magnitude.toStringAsFixed(1)}°/s',
                'Pitch: ${data.imu.accel.pitch.toStringAsFixed(1)}°',
                'Roll: ${data.imu.accel.roll.toStringAsFixed(1)}°',
                if (data.imu.shake) 'Status: SHAKE DETECTED!' else 'Status: Stable',
              ],
              data.imu.shake ? Colors.orange : Colors.green,
            ),
            
            const SizedBox(height: 12),
            
            // Pressure Data
            _buildDataSection(
              'Pressure Sensors',
              [
                'Total Pressure: ${data.pressure.totalPressure.toStringAsFixed(1)}%',
                'Max Zone: ${data.pressure.maxPressureZone}',
                'Heel: ${data.pressure.heel.toStringAsFixed(1)}%',
                'Arch: ${data.pressure.arch.toStringAsFixed(1)}%',
                'Ball: ${data.pressure.ball.toStringAsFixed(1)}%',
                'Toe: ${data.pressure.toe.toStringAsFixed(1)}%',
              ],
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Text(
            item,
            style: const TextStyle(fontSize: 14),
          ),
        )),
      ],
    );
  }
}
