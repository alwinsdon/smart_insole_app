import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../models/sensor_data.dart';
import 'dart:math' as math;

class RealTimeCharts extends StatefulWidget {
  const RealTimeCharts({super.key});

  @override
  State<RealTimeCharts> createState() => _RealTimeChartsState();
}

class _RealTimeChartsState extends State<RealTimeCharts> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<FlSpot> _accelData = [];
  final List<FlSpot> _gyroData = [];
  final List<FlSpot> _pressureData = [];
  double _timeCounter = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateChartData(SensorData data) {
    setState(() {
      _timeCounter += 0.1;
      
      // Keep only last 50 points (5 seconds of data)
      if (_accelData.length > 50) {
        _accelData.removeAt(0);
        _gyroData.removeAt(0);
        _pressureData.removeAt(0);
      }
      
      // Add new data points
      _accelData.add(FlSpot(_timeCounter, data.imu.accel.magnitude));
      _gyroData.add(FlSpot(_timeCounter, data.imu.gyro.magnitude));
      
      // Calculate total pressure
      final totalPressure = data.pressure.heel + data.pressure.arch + 
                           data.pressure.ball + data.pressure.toe;
      _pressureData.add(FlSpot(_timeCounter, totalPressure));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartInsoleBluetoothService>(
      builder: (context, bluetoothService, child) {
        // Update chart data when new data arrives
        if (bluetoothService.latestData != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateChartData(bluetoothService.latestData!);
          });
        }

        return Column(
          children: [
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.primary,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                tabs: const [
                  Tab(text: 'Acceleration'),
                  Tab(text: 'Rotation'),
                  Tab(text: 'Pressure'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Chart Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAccelerationChart(),
                  _buildGyroscopeChart(),
                  _buildPressureChart(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccelerationChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Acceleration Magnitude (g)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.blue[100]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}s',
                          style: GoogleFonts.poppins(
                            color: Colors.blue[600],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.5,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            color: Colors.blue[600],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: _accelData.isNotEmpty ? _accelData.first.x : 0,
                maxX: _accelData.isNotEmpty ? _accelData.last.x : 5,
                minY: 0,
                maxY: 3,
                lineBarsData: [
                  LineChartBarData(
                    spots: _accelData,
                    isCurved: true,
                    color: Colors.blue[600],
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue[600]!.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGyroscopeChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rotate_right, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Rotation Rate (°/s)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.green[100]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}s',
                          style: GoogleFonts.poppins(
                            color: Colors.green[600],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 50,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.green[600],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: _gyroData.isNotEmpty ? _gyroData.first.x : 0,
                maxX: _gyroData.isNotEmpty ? _gyroData.last.x : 5,
                minY: 0,
                maxY: 200,
                lineBarsData: [
                  LineChartBarData(
                    spots: _gyroData,
                    isCurved: true,
                    color: Colors.green[600],
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green[600]!.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compress, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Total Pressure (%)',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.orange[100]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}s',
                          style: GoogleFonts.poppins(
                            color: Colors.orange[600],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: GoogleFonts.poppins(
                            color: Colors.orange[600],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: _pressureData.isNotEmpty ? _pressureData.first.x : 0,
                maxX: _pressureData.isNotEmpty ? _pressureData.last.x : 5,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _pressureData,
                    isCurved: true,
                    color: Colors.orange[600],
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange[600]!.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
