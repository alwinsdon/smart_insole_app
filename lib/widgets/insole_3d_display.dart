import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/sensor_data.dart';

class Insole3DDisplay extends StatefulWidget {
  final IMUData imuData;
  final PressureData pressureData;
  
  const Insole3DDisplay({
    Key? key,
    required this.imuData,
    required this.pressureData,
  }) : super(key: key);

  @override
  State<Insole3DDisplay> createState() => _Insole3DDisplayState();
}

class _Insole3DDisplayState extends State<Insole3DDisplay>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  double _userRotationX = 0;
  double _userRotationY = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '3D Smart Insole',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _userRotationX = 0;
                      _userRotationY = 0;
                    });
                  },
                  tooltip: 'Reset View',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pitch: ${widget.imuData.accel.pitch.toStringAsFixed(1)}° | Roll: ${widget.imuData.accel.roll.toStringAsFixed(1)}°',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            
            // 3D Insole visualization
            AspectRatio(
              aspectRatio: 1.2,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _userRotationY += details.delta.dx * 0.01;
                    _userRotationX -= details.delta.dy * 0.01;
                    _userRotationX = _userRotationX.clamp(-math.pi / 2, math.pi / 2);
                  });
                },
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: Insole3DPainter(
                        widget.imuData,
                        widget.pressureData,
                        _userRotationX,
                        _userRotationY,
                      ),
                      child: Container(),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Status and instructions
            Row(
              children: [
                Icon(
                  widget.imuData.shake ? Icons.vibration : Icons.check_circle,
                  color: widget.imuData.shake ? Colors.orange : Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.imuData.shake ? 'Movement Detected' : 'Stable',
                  style: TextStyle(
                    color: widget.imuData.shake ? Colors.orange : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Drag to rotate',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Insole3DPainter extends CustomPainter {
  final IMUData imuData;
  final PressureData pressureData;
  final double userRotationX;
  final double userRotationY;

  Insole3DPainter(
    this.imuData,
    this.pressureData,
    this.userRotationX,
    this.userRotationY,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw background and reference
    _drawBackground(canvas, size);
    
    // Calculate combined rotations
    final pitchRad = imuData.accel.pitch * math.pi / 180;
    final rollRad = imuData.accel.roll * math.pi / 180;
    
    // Draw 3D insole
    _drawInsole3D(canvas, center, pitchRad, rollRad);
    
    // Draw coordinate system
    _drawCoordinateSystem(canvas, center, pitchRad, rollRad);
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Draw subtle grid background
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 0.5;
    
    const gridSpacing = 20.0;
    for (double x = 0; x <= size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    // Draw center point
    final centerPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      2,
      centerPaint,
    );
  }

  void _drawInsole3D(Canvas canvas, Offset center, double pitch, double roll) {
    // Insole dimensions (scaled for display)
    const length = 120.0;
    const width = 50.0;
    const thickness = 8.0;
    
    // Create insole shape vertices (realistic insole outline)
    final insoleVertices = _createInsoleVertices(length, width, thickness);
    
    // Transform vertices with IMU rotations and user rotation
    final transformedVertices = insoleVertices.map((vertex) {
      return _transformVertex(vertex, pitch, roll, userRotationX, userRotationY);
    }).toList();
    
    // Project 3D vertices to 2D screen coordinates
    final projectedVertices = transformedVertices.map((vertex) {
      return _projectTo2D(vertex, center);
    }).toList();
    
    // Draw insole faces with depth sorting
    _drawInsoleWithPressure(canvas, projectedVertices, transformedVertices);
  }

  List<List<double>> _createInsoleVertices(double length, double width, double thickness) {
    final vertices = <List<double>>[];
    
    // Create realistic insole shape (heel narrower, toe wider)
    const segments = 20;
    
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final x = (t - 0.5) * length;
      
      // Varying width along the insole (wider at toe, narrower at heel)
      double widthFactor;
      if (t < 0.7) {
        // Heel to arch - gradually widening
        widthFactor = 0.6 + (t / 0.7) * 0.4;
      } else {
        // Arch to toe - wider
        widthFactor = 1.0;
      }
      
      final currentWidth = width * widthFactor;
      
      // Top surface vertices
      vertices.add([x, -currentWidth / 2, thickness / 2]);
      vertices.add([x, currentWidth / 2, thickness / 2]);
      
      // Bottom surface vertices
      vertices.add([x, -currentWidth / 2, -thickness / 2]);
      vertices.add([x, currentWidth / 2, -thickness / 2]);
    }
    
    return vertices;
  }

  List<double> _transformVertex(List<double> vertex, double pitch, double roll, 
                               double userRotX, double userRotY) {
    double x = vertex[0];
    double y = vertex[1];
    double z = vertex[2];
    
    // Apply IMU rotations first (actual sensor data)
    // Pitch rotation (around Y axis)
    final cosPitch = math.cos(pitch);
    final sinPitch = math.sin(pitch);
    final x1 = x * cosPitch - z * sinPitch;
    final z1 = x * sinPitch + z * cosPitch;
    
    // Roll rotation (around X axis)
    final cosRoll = math.cos(roll);
    final sinRoll = math.sin(roll);
    final y2 = y * cosRoll - z1 * sinRoll;
    final z2 = y * sinRoll + z1 * cosRoll;
    
    // Apply user rotation for better viewing
    // User X rotation (around X axis)
    final cosUserX = math.cos(userRotX);
    final sinUserX = math.sin(userRotX);
    final y3 = y2 * cosUserX - z2 * sinUserX;
    final z3 = y2 * sinUserX + z2 * cosUserX;
    
    // User Y rotation (around Y axis)
    final cosUserY = math.cos(userRotY);
    final sinUserY = math.sin(userRotY);
    final x4 = x1 * cosUserY - z3 * sinUserY;
    final z4 = x1 * sinUserY + z3 * cosUserY;
    
    return [x4, y3, z4];
  }

  Offset _projectTo2D(List<double> vertex, Offset center) {
    // Simple perspective projection
    const focalLength = 300.0;
    const viewDistance = 200.0;
    
    final x = vertex[0];
    final y = vertex[1];
    final z = vertex[2] + viewDistance;
    
    if (z <= 0) return center; // Avoid division by zero
    
    final projectedX = (x * focalLength / z) + center.dx;
    final projectedY = (y * focalLength / z) + center.dy;
    
    return Offset(projectedX, projectedY);
  }

  void _drawInsoleWithPressure(Canvas canvas, List<Offset> projectedVertices, 
                              List<List<double>> transformedVertices) {
    if (projectedVertices.length < 8) return;
    
    // Define pressure zones and their colors
    final pressureZones = [
      {'name': 'heel', 'pressure': pressureData.heel, 'range': [0, 5]},
      {'name': 'arch', 'pressure': pressureData.arch, 'range': [6, 11]},
      {'name': 'ball', 'pressure': pressureData.ball, 'range': [12, 17]},
      {'name': 'toe', 'pressure': pressureData.toe, 'range': [18, 20]},
    ];
    
    // Draw insole surface with pressure mapping
    for (int i = 0; i < projectedVertices.length - 4; i += 4) {
      // Determine which pressure zone this segment belongs to
      final segmentIndex = i ~/ 4;
      var pressure = 0.0;
      
      for (final zone in pressureZones) {
        final range = zone['range'] as List<int>;
        if (segmentIndex >= range[0] && segmentIndex <= range[1]) {
          pressure = zone['pressure'] as double;
          break;
        }
      }
      
      // Create quadrilateral for this segment
      final quad = [
        projectedVertices[i],     // Top left
        projectedVertices[i + 1], // Top right
        projectedVertices[i + 5], // Bottom right
        projectedVertices[i + 4], // Bottom left
      ];
      
      // Draw the segment with pressure color
      _drawPressureQuad(canvas, quad, pressure, transformedVertices[i][2]);
    }
    
    // Draw insole outline
    _drawInsoleOutline(canvas, projectedVertices);
  }

  void _drawPressureQuad(Canvas canvas, List<Offset> quad, double pressure, double depth) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.grey.shade600;
    
    // Calculate pressure color
    paint.color = _getPressureColor(pressure, depth);
    
    // Create path for the quad
    final path = Path()
      ..moveTo(quad[0].dx, quad[0].dy)
      ..lineTo(quad[1].dx, quad[1].dy)
      ..lineTo(quad[2].dx, quad[2].dy)
      ..lineTo(quad[3].dx, quad[3].dy)
      ..close();
    
    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawInsoleOutline(Canvas canvas, List<Offset> vertices) {
    if (vertices.length < 4) return;
    
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = imuData.shake ? Colors.orange : Colors.blue.shade700;
    
    // Draw top outline
    final topPath = Path();
    for (int i = 0; i < vertices.length; i += 4) {
      if (i == 0) {
        topPath.moveTo(vertices[i].dx, vertices[i].dy);
      } else {
        topPath.lineTo(vertices[i].dx, vertices[i].dy);
      }
    }
    canvas.drawPath(topPath, outlinePaint);
    
    // Draw bottom outline
    final bottomPath = Path();
    for (int i = 1; i < vertices.length; i += 4) {
      if (i == 1) {
        bottomPath.moveTo(vertices[i].dx, vertices[i].dy);
      } else {
        bottomPath.lineTo(vertices[i].dx, vertices[i].dy);
      }
    }
    canvas.drawPath(bottomPath, outlinePaint);
  }

  Color _getPressureColor(double pressure, double depth) {
    // Base color based on pressure
    Color baseColor;
    if (pressure <= 0) {
      baseColor = Colors.grey.shade300;
    } else {
      final intensity = math.min(pressure / 100.0, 1.0);
      if (intensity < 0.25) {
        baseColor = Color.lerp(Colors.blue.shade200, Colors.cyan, intensity * 4)!;
      } else if (intensity < 0.5) {
        baseColor = Color.lerp(Colors.cyan, Colors.green, (intensity - 0.25) * 4)!;
      } else if (intensity < 0.75) {
        baseColor = Color.lerp(Colors.green, Colors.yellow, (intensity - 0.5) * 4)!;
      } else {
        baseColor = Color.lerp(Colors.yellow, Colors.red, (intensity - 0.75) * 4)!;
      }
    }
    
    // Apply depth shading for 3D effect
    final depthFactor = math.max(0.3, 1.0 - (depth / 100.0).abs());
    return Color.fromRGBO(
      (baseColor.red * depthFactor).round(),
      (baseColor.green * depthFactor).round(),
      (baseColor.blue * depthFactor).round(),
      1.0,
    );
  }

  void _drawCoordinateSystem(Canvas canvas, Offset center, double pitch, double roll) {
    const axisLength = 60.0;
    final axisPaint = Paint()..strokeWidth = 3;
    
    // Define coordinate axes
    final axes = [
      {'color': Colors.red, 'vector': [axisLength, 0, 0], 'label': 'X'},
      {'color': Colors.green, 'vector': [0, axisLength, 0], 'label': 'Y'},
      {'color': Colors.blue, 'vector': [0, 0, axisLength], 'label': 'Z'},
    ];
    
    for (final axis in axes) {
      final color = axis['color'] as Color;
      final vector = axis['vector'] as List<double>;
      final label = axis['label'] as String;
      
      // Transform the axis vector
      final transformed = _transformVertex(vector, pitch, roll, userRotationX, userRotationY);
      final projected = _projectTo2D(transformed, center);
      
      // Draw axis line
      axisPaint.color = color;
      canvas.drawLine(center, projected, axisPaint);
      
      // Draw axis label
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          projected.dx - textPainter.width / 2,
          projected.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
