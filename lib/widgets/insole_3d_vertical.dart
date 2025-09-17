import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../models/sensor_data.dart';

class Insole3DVertical extends StatefulWidget {
  const Insole3DVertical({super.key});

  @override
  State<Insole3DVertical> createState() => _Insole3DVerticalState();
}

class _Insole3DVerticalState extends State<Insole3DVertical> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;
  
  double _userRotationX = 0.0;
  double _userRotationY = 0.0;
  
  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    // Start auto-rotation
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartInsoleBluetoothService>(
      builder: (context, bluetoothService, child) {
        return Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[900]!,
                Colors.grey[800]!,
                Colors.grey[700]!,
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _userRotationY += details.delta.dx * 0.01;
                      _userRotationX += details.delta.dy * 0.01;
                      _userRotationX = _userRotationX.clamp(-math.pi / 3, math.pi / 3);
                    });
                  },
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: Insole3DPainter(
                      rotationY: _rotationAnimation.value + _userRotationY,
                      rotationX: _userRotationX,
                      pressureData: bluetoothService.latestData?.pressure,
                      imuData: bluetoothService.latestData?.imu,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class Insole3DPainter extends CustomPainter {
  final double rotationY;
  final double rotationX;
  final PressureData? pressureData;
  final IMUData? imuData;

  Insole3DPainter({
    required this.rotationY,
    required this.rotationX,
    this.pressureData,
    this.imuData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Create transformation matrix
    final matrix = vm.Matrix4.identity()
      ..translate(center.dx, center.dy, 0)
      ..rotateY(rotationY)
      ..rotateX(rotationX)
      ..scale(2.0);

    // Draw 3D insole
    _draw3DInsole(canvas, size, matrix);
    
    // Draw pressure points
    if (pressureData != null) {
      _drawPressureMapping(canvas, size, matrix);
    }
    
    // Draw orientation indicator
    _drawOrientationIndicator(canvas, size);
  }

  void _draw3DInsole(Canvas canvas, Size size, vm.Matrix4 matrix) {
    // Define insole shape points (realistic foot shape)
    final insolePoints = _generateInsoleShape();
    
    // Create 3D insole with thickness
    final topSurface = <vm.Vector3>[];
    final bottomSurface = <vm.Vector3>[];
    
    for (final point in insolePoints) {
      topSurface.add(vm.Vector3(point.dx, point.dy, 10)); // Top surface
      bottomSurface.add(vm.Vector3(point.dx, point.dy, -10)); // Bottom surface
    }
    
    // Draw bottom surface (darker)
    final bottomPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    _drawSurface(canvas, bottomSurface, matrix, bottomPaint);
    
    // Draw top surface (lighter)
    final topPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;
    _drawSurface(canvas, topSurface, matrix, topPaint);
    
    // Draw sides for 3D effect
    _drawSides(canvas, topSurface, bottomSurface, matrix);
    
    // Draw outline
    final outlinePaint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    _drawSurface(canvas, topSurface, matrix, outlinePaint);
  }

  List<Offset> _generateInsoleShape() {
    // Generate realistic foot/insole shape
    final points = <Offset>[];
    
    // Heel area (wider, rounded)
    for (int i = 0; i <= 20; i++) {
      final angle = math.pi + (i / 20) * math.pi;
      final x = math.cos(angle) * 60;
      final y = -100 + math.sin(angle) * 30;
      points.add(Offset(x, y));
    }
    
    // Arch area (narrower)
    for (int i = 0; i <= 15; i++) {
      final t = i / 15;
      final x = math.sin(t * math.pi) * 45;
      final y = -70 + t * 80;
      if (i % 2 == 0) points.add(Offset(x, y));
      if (i % 2 == 1) points.add(Offset(-x, y));
    }
    
    // Forefoot area (wider)
    for (int i = 0; i <= 25; i++) {
      final t = i / 25;
      final angle = t * math.pi;
      final x = math.sin(angle) * (55 + t * 20);
      final y = 10 + t * 80;
      points.add(Offset(math.cos(angle) >= 0 ? x : -x, y));
    }
    
    // Toe area (rounded)
    for (int i = 0; i <= 15; i++) {
      final angle = (i / 15) * math.pi;
      final x = math.cos(angle) * 35;
      final y = 90 + math.sin(angle) * 25;
      points.add(Offset(x, y));
    }
    
    return points;
  }

  void _drawSurface(Canvas canvas, List<vm.Vector3> points, vm.Matrix4 matrix, Paint paint) {
    if (points.isEmpty) return;
    
    final path = Path();
    bool first = true;
    
    for (final point in points) {
      final transformed = matrix.transform3(point);
      final screenPoint = Offset(transformed.x, transformed.y);
      
      if (first) {
        path.moveTo(screenPoint.dx, screenPoint.dy);
        first = false;
      } else {
        path.lineTo(screenPoint.dx, screenPoint.dy);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawSides(Canvas canvas, List<vm.Vector3> top, List<vm.Vector3> bottom, vm.Matrix4 matrix) {
    final sidePaint = Paint()
      ..color = Colors.grey[500]!
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < top.length - 1; i++) {
      final path = Path();
      
      // Create side quad
      final t1 = matrix.transform3(top[i]);
      final t2 = matrix.transform3(top[i + 1]);
      final b1 = matrix.transform3(bottom[i]);
      final b2 = matrix.transform3(bottom[i + 1]);
      
      path.moveTo(t1.x, t1.y);
      path.lineTo(t2.x, t2.y);
      path.lineTo(b2.x, b2.y);
      path.lineTo(b1.x, b1.y);
      path.close();
      
      canvas.drawPath(path, sidePaint);
    }
  }

  void _drawPressureMapping(Canvas canvas, Size size, vm.Matrix4 matrix) {
    if (pressureData == null) return;
    
    // Define pressure sensor positions on the insole
    final sensorPositions = [
      vm.Vector3(-30, -80, 12), // Heel left
      vm.Vector3(30, -80, 12),  // Heel right  
      vm.Vector3(-25, 0, 12),   // Arch left
      vm.Vector3(25, 0, 12),    // Arch right
      vm.Vector3(-35, 60, 12),  // Ball left
      vm.Vector3(35, 60, 12),   // Ball right
      vm.Vector3(0, 95, 12),    // Big toe
      vm.Vector3(-20, 90, 12),  // Other toes
    ];
    
    // Get pressure values (assuming we have 4 sensors mapping to 8 visual points)
    final pressureValues = [
      pressureData!.heel,
      pressureData!.heel,
      pressureData!.arch,
      pressureData!.arch,
      pressureData!.ball,
      pressureData!.ball,
      pressureData!.toe,
      pressureData!.toe * 0.7,
    ];
    
    // Draw pressure visualization
    for (int i = 0; i < sensorPositions.length && i < pressureValues.length; i++) {
      final position = matrix.transform3(sensorPositions[i]);
      final pressure = pressureValues[i].clamp(0.0, 100.0);
      
      if (pressure > 1.0) {
        // Create pressure visualization
        final radius = 8 + (pressure / 100) * 20;
        final intensity = (pressure / 100).clamp(0.0, 1.0);
        
        // Color based on pressure intensity
        final color = Color.lerp(
          Colors.blue.withOpacity(0.3),
          Colors.red.withOpacity(0.8),
          intensity,
        )!;
        
        // Draw pressure circle with gradient
        final gradient = RadialGradient(
          colors: [
            color,
            color.withOpacity(0.1),
          ],
          stops: const [0.3, 1.0],
        );
        
        final paint = Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(
              center: Offset(position.x, position.y),
              radius: radius,
            ),
          );
        
        canvas.drawCircle(
          Offset(position.x, position.y),
          radius,
          paint,
        );
        
        // Draw pressure value text
        if (pressure > 10) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${pressure.toInt()}%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              position.x - textPainter.width / 2,
              position.y - textPainter.height / 2,
            ),
          );
        }
      }
    }
  }

  void _drawOrientationIndicator(Canvas canvas, Size size) {
    // Draw orientation axes in bottom right corner
    final origin = Offset(size.width - 60, size.height - 60);
    final axisLength = 30.0;
    
    // X-axis (Red)
    final xEnd = Offset(
      origin.dx + axisLength * math.cos(rotationY),
      origin.dy + axisLength * math.sin(rotationY) * math.cos(rotationX),
    );
    
    canvas.drawLine(
      origin,
      xEnd,
      Paint()
        ..color = Colors.red
        ..strokeWidth = 3,
    );
    
    // Y-axis (Green)  
    final yEnd = Offset(
      origin.dx - axisLength * math.sin(rotationY),
      origin.dy + axisLength * math.cos(rotationY) * math.cos(rotationX),
    );
    
    canvas.drawLine(
      origin,
      yEnd,
      Paint()
        ..color = Colors.green
        ..strokeWidth = 3,
    );
    
    // Z-axis (Blue)
    final zEnd = Offset(
      origin.dx,
      origin.dy - axisLength * math.sin(rotationX),
    );
    
    canvas.drawLine(
      origin,
      zEnd,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 3,
    );
    
    // Labels
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(1, 1),
          blurRadius: 2,
        ),
      ],
    );
    
    _drawAxisLabel(canvas, xEnd, 'X', textStyle);
    _drawAxisLabel(canvas, yEnd, 'Y', textStyle);
    _drawAxisLabel(canvas, zEnd, 'Z', textStyle);
  }

  void _drawAxisLabel(Canvas canvas, Offset position, String label, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(Insole3DPainter oldDelegate) {
    return oldDelegate.rotationY != rotationY ||
           oldDelegate.rotationX != rotationX ||
           oldDelegate.pressureData != pressureData ||
           oldDelegate.imuData != imuData;
  }
}
