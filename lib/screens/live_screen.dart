import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../widgets/connection_panel.dart';
import '../widgets/insole_3d_vertical.dart';
import '../widgets/real_time_charts.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Consumer<SmartInsoleBluetoothService>(
          builder: (context, bluetoothService, child) {
            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Live Monitoring',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: () => _showInfoDialog(context),
                    ),
                  ],
                ),
                
                // Connection Status
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ConnectionPanel(),
                  ),
                ),
                
                // Live Data Section
                if (bluetoothService.isConnected && bluetoothService.latestData != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Indicators
                          _buildStatusIndicators(context, bluetoothService),
                          
                          const SizedBox(height: 20),
                          
                          // 3D Insole Display
                          _buildInsoleSection(context, bluetoothService),
                          
                          const SizedBox(height: 20),
                          
                          // Real-time Charts
                          _buildChartsSection(context),
                        ],
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: _buildWaitingState(context),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusIndicators(BuildContext context, SmartInsoleBluetoothService service) {
    final data = service.latestData!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              context,
              'Activity',
              _getActivityLevel(data.imu.accel.magnitude),
              Icons.directions_walk,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusCard(
              context,
              'Balance',
              _getBalanceStatus(data.pressure),
              Icons.balance,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusCard(
              context,
              'Pressure',
              '${_getTotalPressure(data.pressure).toInt()}%',
              Icons.speed,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsoleSection(BuildContext context, SmartInsoleBluetoothService service) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sensors,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Real-time Insole Data',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 400,
            child: Insole3DVertical(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Real-time Analytics',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: RealTimeCharts(),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.bluetooth_searching,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Waiting for device connection',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your Smart Insole to start monitoring',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Live Monitoring',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This screen shows real-time data from your Smart Insole including:\n\n'
          '• 3D pressure mapping\n'
          '• Movement tracking\n'
          '• Balance analysis\n'
          '• Live sensor charts\n\n'
          'Make sure your device is connected to see live data.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  String _getActivityLevel(double magnitude) {
    if (magnitude > 2.0) return 'High';
    if (magnitude > 1.0) return 'Medium';
    if (magnitude > 0.5) return 'Low';
    return 'Rest';
  }

  String _getBalanceStatus(dynamic pressure) {
    // Simple balance analysis based on pressure distribution
    if (pressure is List && pressure.length >= 4) {
      final leftSide = (pressure[0] + pressure[1]) / 2;
      final rightSide = (pressure[2] + pressure[3]) / 2;
      final diff = (leftSide - rightSide).abs();
      
      if (diff < 5) return 'Balanced';
      if (diff < 15) return 'Slight';
      return 'Unbalanced';
    }
    return 'Unknown';
  }

  double _getTotalPressure(dynamic pressure) {
    if (pressure is List) {
      return pressure.fold(0.0, (sum, p) => sum + (p as num).toDouble());
    }
    return 0.0;
  }
}
