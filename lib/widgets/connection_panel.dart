import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';

class ConnectionPanel extends StatelessWidget {
  const ConnectionPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartInsoleBluetoothService>(
      builder: (context, bluetoothService, child) {
        return Card(
          color: _getStatusColor(bluetoothService),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(bluetoothService),
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusTitle(bluetoothService),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            bluetoothService.connectionStatus,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildActionButton(context, bluetoothService),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(SmartInsoleBluetoothService service) {
    if (service.isConnected) {
      return Colors.green;
    } else if (service.isConnecting) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getStatusIcon(SmartInsoleBluetoothService service) {
    if (service.isConnected) {
      return Icons.bluetooth_connected;
    } else if (service.isConnecting) {
      return Icons.bluetooth_searching;
    } else {
      return Icons.bluetooth_disabled;
    }
  }

  String _getStatusTitle(SmartInsoleBluetoothService service) {
    if (service.isConnected) {
      return 'Connected to Smart Insole';
    } else if (service.isConnecting) {
      return 'Connecting...';
    } else {
      return 'Not Connected';
    }
  }

  Widget _buildActionButton(BuildContext context, SmartInsoleBluetoothService service) {
    if (service.isConnecting) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    return ElevatedButton(
      onPressed: service.isConnected
          ? () => _showDisconnectDialog(context, service)
          : () => _handleConnect(context, service),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _getStatusColor(service),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        service.isConnected ? 'Disconnect' : 'Connect',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _handleConnect(BuildContext context, SmartInsoleBluetoothService service) async {
    // Check if Bluetooth is enabled
    if (service.bluetoothState != 'STATE_ON') {
      final enabled = await service.enableBluetooth();
      if (!enabled) {
        _showSnackBar(context, 'Please enable Bluetooth to continue', Colors.red);
        return;
      }
    }

    // Attempt connection
    final connected = await service.connectToSmartInsole();
    if (!connected) {
      _showSnackBar(
        context,
        'Failed to connect. Make sure Smart Insole is powered on and nearby.',
        Colors.red,
      );
    }
  }

  void _showDisconnectDialog(BuildContext context, SmartInsoleBluetoothService service) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Disconnect Smart Insole'),
          content: const Text('Are you sure you want to disconnect from the Smart Insole?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                service.disconnect();
              },
              child: const Text('Disconnect'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
