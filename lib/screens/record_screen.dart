import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> with TickerProviderStateMixin {
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  Duration _recordingDuration = Duration.zero;
  late AnimationController _pulseController;
  
  final List<String> _recordingTypes = [
    'Walking Analysis',
    'Running Gait',
    'Balance Test',
    'Custom Session',
  ];
  
  String _selectedType = 'Walking Analysis';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      if (_isRecording) {
        // Stop recording
        _isRecording = false;
        _pulseController.stop();
        _recordingStartTime = null;
        _recordingDuration = Duration.zero;
      } else {
        // Start recording
        _isRecording = true;
        _recordingStartTime = DateTime.now();
        _pulseController.repeat();
        _startTimer();
      }
    });
  }

  void _startTimer() {
    if (_isRecording && _recordingStartTime != null) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isRecording && mounted) {
          setState(() {
            _recordingDuration = DateTime.now().difference(_recordingStartTime!);
          });
          _startTimer();
        }
      });
    }
  }

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
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Recording Studio',
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
                            Theme.of(context).colorScheme.secondary,
                            Theme.of(context).colorScheme.tertiary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Recording Type Selection
                        _buildRecordingTypeSelector(),
                        
                        const SizedBox(height: 24),
                        
                        // Recording Controls
                        _buildRecordingControls(bluetoothService),
                        
                        const SizedBox(height: 24),
                        
                        // Recording Status
                        if (_isRecording) _buildRecordingStatus(),
                        
                        const SizedBox(height: 24),
                        
                        // Recent Recordings
                        _buildRecentRecordings(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecordingTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Recording Type',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _recordingTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type,
                  style: GoogleFonts.poppins(),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls(SmartInsoleBluetoothService bluetoothService) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          // Connection Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bluetoothService.isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  bluetoothService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: bluetoothService.isConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  bluetoothService.isConnected ? 'Device Connected' : 'Device Disconnected',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: bluetoothService.isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Record Button
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _isRecording
                      ? [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3 * _pulseController.value),
                            blurRadius: 20,
                            spreadRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: _isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: bluetoothService.isConnected ? _toggleRecording : null,
                    child: Center(
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.fiber_manual_record,
                        color: Colors.white,
                        size: _isRecording ? 40 : 50,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          Text(
            _isRecording ? 'Recording...' : 'Tap to Record',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
            ),
          ),
          
          if (!bluetoothService.isConnected)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Connect your device to start recording',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fiber_manual_record, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recording in Progress',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatDuration(_recordingDuration),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type: $_selectedType',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecordings() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Recent Recordings',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Placeholder for recent recordings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No recordings yet',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start your first recording to see it here',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds % 60);
    return '$minutes:$seconds';
  }
}
