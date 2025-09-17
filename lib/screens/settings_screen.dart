import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/bluetooth_service.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Smart Insole User',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Device Settings
            _buildSectionHeader('Device'),
            const SizedBox(height: 12),
            
            Consumer<SmartInsoleBluetoothService>(
              builder: (context, bluetoothService, child) {
                return Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      'Bluetooth Connection',
                      bluetoothService.isConnected ? 'Connected' : 'Disconnected',
                      Icons.bluetooth,
                      bluetoothService.isConnected ? Colors.green : Colors.red,
                      onTap: () {
                        if (bluetoothService.isConnected) {
                          bluetoothService.disconnect();
                        } else {
                          bluetoothService.startScanning();
                        }
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      'Device Information',
                      'View device details',
                      Icons.info_outline,
                      Colors.blue,
                    ),
                    _buildSettingsTile(
                      context,
                      'Firmware Update',
                      'Check for updates',
                      Icons.system_update,
                      Colors.orange,
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Data Settings
            _buildSectionHeader('Data & Privacy'),
            const SizedBox(height: 12),
            
            _buildSettingsTile(
              context,
              'Data Export',
              'Export your data',
              Icons.download,
              Colors.teal,
            ),
            _buildSettingsTile(
              context,
              'Data Backup',
              'Backup to cloud',
              Icons.cloud_upload,
              Colors.purple,
            ),
            _buildSettingsTile(
              context,
              'Privacy Settings',
              'Manage your privacy',
              Icons.privacy_tip,
              Colors.indigo,
            ),
            
            const SizedBox(height: 24),
            
            // App Settings
            _buildSectionHeader('App Preferences'),
            const SizedBox(height: 12),
            
            _buildSettingsTile(
              context,
              'Notifications',
              'Manage notifications',
              Icons.notifications_outlined,
              Colors.amber,
            ),
            _buildSettingsTile(
              context,
              'Units',
              'Metric / Imperial',
              Icons.straighten,
              Colors.green,
            ),
            _buildSettingsTile(
              context,
              'Theme',
              'Light / Dark / Auto',
              Icons.palette,
              Colors.pink,
            ),
            
            const SizedBox(height: 24),
            
            // Support
            _buildSectionHeader('Support'),
            const SizedBox(height: 12),
            
            _buildSettingsTile(
              context,
              'Help & FAQ',
              'Get help and support',
              Icons.help_outline,
              Colors.cyan,
            ),
            _buildSettingsTile(
              context,
              'Contact Us',
              'Send feedback',
              Icons.email_outlined,
              Colors.deepOrange,
            ),
            _buildSettingsTile(
              context,
              'About',
              'App version and info',
              Icons.info,
              Colors.grey,
            ),
            
            const SizedBox(height: 32),
            
            // Sign Out Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout, color: Colors.red, size: 20),
                ),
                title: Text(
                  'Sign Out',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                subtitle: Text(
                  'Sign out of your account',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.red.withOpacity(0.7),
                  ),
                ),
                onTap: () => _showSignOutDialog(),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title - Coming Soon!'),
              backgroundColor: color,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Sign Out',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to sign out of your account?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }
}
