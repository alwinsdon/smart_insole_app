import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/sensor_data.dart';

class IMU3DDisplay extends StatelessWidget {
  final IMUData imuData;
  
  const IMU3DDisplay({
    Key? key,
    required this.imuData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shoe Orientation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 3D Shoe visualization
            AspectRatio(
              aspectRatio: 1.0,
              child: CustomPaint(
                painter: Shoe3DPainter(imuData),
                child: Container(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Orientation data
            _buildOrientationData(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrientationData() {
    final pitch = imuData.accel.pitch;
    final roll = imuData.accel.roll;
    final shakeStatus = imuData.shake;
    
    return Column(
      children: [
        _buildOrientationRow('Pitch', pitch, Icons.rotate_right),
        const SizedBox(height: 8),
        _buildOrientationRow('Roll', roll, Icons.screen_rotation),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              shakeStatus ? Icons.vibration : Icons.check_circle,
              color: shakeStatus ? Colors.orange : Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              shakeStatus ? 'Movement Detected' : 'Stable',
              style: TextStyle(
                color: shakeStatus ? Colors.orange : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrientationRow(String label, double value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ${value.toStringAsFixed(1)}°',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

class Shoe3DPainter extends CustomPainter {
  final IMUData imuData;
  
  Shoe3DPainter(this.imuData);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Get rotation angles from accelerometer
    final pitch = imuData.accel.pitch * math.pi / 180; // Convert to radians
    final roll = imuData.accel.roll * math.pi / 180;
    
    // Draw reference grid
    _drawGrid(canvas, size, Colors.grey.shade300);
    
    // Draw 3D shoe representation
    _drawShoe3D(canvas, center, pitch, roll, paint, strokePaint);
    
    // Draw orientation indicators
    _drawOrientationIndicators(canvas, size, pitch, roll);
  }

  void _drawGrid(Canvas canvas, Size size, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    
    // Draw grid lines
    for (int i = 0; i <= 4; i++) {
      final x = (size.width / 4) * i;
      final y = (size.height / 4) * i;
      
      // Vertical lines
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
      
      // Horizontal lines
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawShoe3D(Canvas canvas, Offset center, double pitch, double roll,
      Paint fillPaint, Paint strokePaint) {
    
    // Define shoe dimensions
    const shoeLength = 80.0;
    const shoeWidth = 30.0;
    const shoeHeight = 10.0;
    
    // Create transformation matrix for 3D rotation
    final cosRoll = math.cos(roll);
    final sinRoll = math.sin(roll);
    final cosPitch = math.cos(pitch);
    final sinPitch = math.sin(pitch);
    
    // Define shoe vertices (simplified shoe shape)
    final vertices = [
      // Top face
      [-shoeLength/2, -shoeWidth/2, shoeHeight/2],
      [shoeLength/2, -shoeWidth/2, shoeHeight/2],
      [shoeLength/2, shoeWidth/2, shoeHeight/2],
      [-shoeLength/2, shoeWidth/2, shoeHeight/2],
      // Bottom face
      [-shoeLength/2, -shoeWidth/2, -shoeHeight/2],
      [shoeLength/2, -shoeWidth/2, -shoeHeight/2],
      [shoeLength/2, shoeWidth/2, -shoeHeight/2],
      [-shoeLength/2, shoeWidth/2, -shoeHeight/2],
    ];
    
    // Transform vertices
    final transformedVertices = vertices.map((vertex) {
      final x = vertex[0];
      final y = vertex[1];
      final z = vertex[2];
      
      // Apply pitch rotation (around Y axis)
      final x1 = x * cosPitch - z * sinPitch;
      final z1 = x * sinPitch + z * cosPitch;
      
      // Apply roll rotation (around X axis)
      final y2 = y * cosRoll - z1 * sinRoll;
      final z2 = y * sinRoll + z1 * cosRoll;
      
      // Project to 2D (simple orthographic projection)
      return Offset(
        center.dx + x1,
        center.dy + y2,
      );
    }).toList();
    
    // Draw shoe faces
    
    // Top face (shoe sole)
    fillPaint.color = imuData.shake ? Colors.orange.shade200 : Colors.blue.shade200;
    strokePaint.color = imuData.shake ? Colors.orange : Colors.blue;
    
    final topFace = Path()
      ..moveTo(transformedVertices[0].dx, transformedVertices[0].dy)
      ..lineTo(transformedVertices[1].dx, transformedVertices[1].dy)
      ..lineTo(transformedVertices[2].dx, transformedVertices[2].dy)
      ..lineTo(transformedVertices[3].dx, transformedVertices[3].dy)
      ..close();
    
    canvas.drawPath(topFace, fillPaint);
    canvas.drawPath(topFace, strokePaint);
    
    // Side faces (for 3D effect)
    fillPaint.color = imuData.shake ? Colors.orange.shade100 : Colors.blue.shade100;
    
    // Right side
    final rightFace = Path()
      ..moveTo(transformedVertices[1].dx, transformedVertices[1].dy)
      ..lineTo(transformedVertices[2].dx, transformedVertices[2].dy)
      ..lineTo(transformedVertices[6].dx, transformedVertices[6].dy)
      ..lineTo(transformedVertices[5].dx, transformedVertices[5].dy)
      ..close();
    
    canvas.drawPath(rightFace, fillPaint);
    canvas.drawPath(rightFace, strokePaint);
    
    // Front face
    final frontFace = Path()
      ..moveTo(transformedVertices[2].dx, transformedVertices[2].dy)
      ..lineTo(transformedVertices[3].dx, transformedVertices[3].dy)
      ..lineTo(transformedVertices[7].dx, transformedVertices[7].dy)
      ..lineTo(transformedVertices[6].dx, transformedVertices[6].dy)
      ..close();
    
    canvas.drawPath(frontFace, fillPaint);
    canvas.drawPath(frontFace, strokePaint);
    
    // Draw coordinate axes
    _drawAxes(canvas, center, pitch, roll);
  }

  void _drawAxes(Canvas canvas, Offset center, double pitch, double roll) {
    final axisLength = 40.0;
    final axisPaint = Paint()..strokeWidth = 3;
    
    // Define axis directions
    final axes = [
      {'color': Colors.red, 'vector': [1, 0, 0]}, // X-axis (red)
      {'color': Colors.green, 'vector': [0, 1, 0]}, // Y-axis (green)
      {'color': Colors.blue, 'vector': [0, 0, 1]}, // Z-axis (blue)
    ];
    
    for (final axis in axes) {
      final color = axis['color'] as Color;
      final vector = axis['vector'] as List<double>;
      
      final x = vector[0] * axisLength;
      final y = vector[1] * axisLength;
      final z = vector[2] * axisLength;
      
      // Apply rotations
      final cosRoll = math.cos(roll);
      final sinRoll = math.sin(roll);
      final cosPitch = math.cos(pitch);
      final sinPitch = math.sin(pitch);
      
      final x1 = x * cosPitch - z * sinPitch;
      final z1 = x * sinPitch + z * cosPitch;
      final y2 = y * cosRoll - z1 * sinRoll;
      
      axisPaint.color = color;
      canvas.drawLine(
        center,
        Offset(center.dx + x1, center.dy + y2),
        axisPaint,
      );
    }
  }

  void _drawOrientationIndicators(Canvas canvas, Size size, double pitch, double roll) {
    final paint = Paint()..strokeWidth = 2;
    
    // Draw pitch indicator (top)
    final pitchX = size.width / 2 + (pitch / (math.pi / 2)) * (size.width / 4);
    paint.color = Colors.red;
    canvas.drawLine(
      Offset(pitchX - 10, 10),
      Offset(pitchX + 10, 10),
      paint,
    );
    
    // Draw roll indicator (right)
    final rollY = size.height / 2 + (roll / (math.pi / 2)) * (size.height / 4);
    paint.color = Colors.green;
    canvas.drawLine(
      Offset(size.width - 10, rollY - 10),
      Offset(size.width - 10, rollY + 10),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
