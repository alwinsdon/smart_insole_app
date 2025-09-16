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
          : () => _openDevicePicker(context, service),
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

  Future<void> _openDevicePicker(BuildContext context, SmartInsoleBluetoothService service) async {
    await service.startScanning();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bluetooth_searching),
                    const SizedBox(width: 8),
                    const Text('Select Device', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () async {
                        await service.startScanning();
                      },
                    )
                  ],
                ),
                const SizedBox(height: 8),
                if (service.discoveredDevices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text('Scanning... If nothing appears, ensure the insole is powered on.')),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: service.discoveredDevices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final d = service.discoveredDevices[index];
                        return ListTile(
                          leading: const Icon(Icons.devices),
                          title: Text(d.name ?? 'Unknown'),
                          subtitle: Text(d.address),
                          onTap: () async {
                            Navigator.of(context).pop();
                            try {
                              await service.connectToDevice(d);
                            } catch (e) {
                              _showSnackBar(context, 'Failed to connect: $e', Colors.red);
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleConnect(BuildContext context, SmartInsoleBluetoothService service) async {
    // Simple connection approach
    try {
      await service.startScanning();
      
      // Find SmartInsole device
      final devices = service.discoveredDevices;
      final smartInsoleDevice = devices.firstWhere(
        (device) => device.name?.contains('SmartInsole') == true,
        orElse: () => throw Exception('SmartInsole device not found'),
      );
      
      // Connect directly to the device
      await service.connectToDevice(smartInsoleDevice);
      
    } catch (e) {
      _showSnackBar(
        context,
        'Failed to connect: $e',
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
