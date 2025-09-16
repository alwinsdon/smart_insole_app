import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/sensor_data.dart';

class PressureHeatmap extends StatelessWidget {
  final PressureData pressureData;
  
  const PressureHeatmap({
    Key? key,
    required this.pressureData,
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
              'Pressure Heatmap',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Shoe sole visualization
            AspectRatio(
              aspectRatio: 0.4, // Shoe sole aspect ratio
              child: CustomPaint(
                painter: ShoeSolePainter(pressureData),
                child: Container(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Pressure legend
            _buildPressureLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildPressureLegend() {
    final pressures = pressureData.asMap;
    
    return Column(
      children: pressures.entries.map((entry) {
        final zone = entry.key;
        final pressure = entry.value;
        final color = _getPressureColor(pressure);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$zone: ${pressure.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getPressureColor(double pressure) {
    // Create a heat map color from blue (low) to red (high)
    if (pressure <= 0) return Colors.grey.shade200;
    
    final intensity = math.min(pressure / 100.0, 1.0);
    
    if (intensity < 0.25) {
      // Blue to cyan
      return Color.lerp(Colors.blue.shade100, Colors.cyan, intensity * 4)!;
    } else if (intensity < 0.5) {
      // Cyan to green
      return Color.lerp(Colors.cyan, Colors.green, (intensity - 0.25) * 4)!;
    } else if (intensity < 0.75) {
      // Green to yellow
      return Color.lerp(Colors.green, Colors.yellow, (intensity - 0.5) * 4)!;
    } else {
      // Yellow to red
      return Color.lerp(Colors.yellow, Colors.red, (intensity - 0.75) * 4)!;
    }
  }
}

class ShoeSolePainter extends CustomPainter {
  final PressureData pressureData;
  
  ShoeSolePainter(this.pressureData);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey.shade600
      ..strokeWidth = 2;

    // Draw shoe sole outline
    final soleRect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.05,
      size.width * 0.8,
      size.height * 0.9,
    );
    
    final soleRRect = RRect.fromRectAndRadius(
      soleRect,
      const Radius.circular(20),
    );
    
    // Draw sole background
    paint.color = Colors.grey.shade100;
    canvas.drawRRect(soleRRect, paint);
    canvas.drawRRect(soleRRect, borderPaint);
    
    // Define pressure zones
    final zones = [
      {'name': 'Toe', 'pressure': pressureData.toe, 'rect': _getToeRect(soleRect)},
      {'name': 'Ball', 'pressure': pressureData.ball, 'rect': _getBallRect(soleRect)},
      {'name': 'Arch', 'pressure': pressureData.arch, 'rect': _getArchRect(soleRect)},
      {'name': 'Heel', 'pressure': pressureData.heel, 'rect': _getHeelRect(soleRect)},
    ];
    
    // Draw pressure zones
    for (final zone in zones) {
      final pressure = zone['pressure'] as double;
      final rect = zone['rect'] as Rect;
      final name = zone['name'] as String;
      
      // Draw pressure area
      paint.color = _getPressureColor(pressure);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );
      
      // Draw zone border
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        borderPaint,
      );
      
      // Draw zone label
      final textPainter = TextPainter(
        text: TextSpan(
          text: name,
          style: TextStyle(
            color: pressure > 50 ? Colors.white : Colors.black,
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
          rect.center.dx - textPainter.width / 2,
          rect.center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  Rect _getToeRect(Rect soleRect) {
    return Rect.fromLTWH(
      soleRect.left + soleRect.width * 0.1,
      soleRect.top,
      soleRect.width * 0.8,
      soleRect.height * 0.2,
    );
  }

  Rect _getBallRect(Rect soleRect) {
    return Rect.fromLTWH(
      soleRect.left + soleRect.width * 0.05,
      soleRect.top + soleRect.height * 0.25,
      soleRect.width * 0.9,
      soleRect.height * 0.2,
    );
  }

  Rect _getArchRect(Rect soleRect) {
    return Rect.fromLTWH(
      soleRect.left + soleRect.width * 0.2,
      soleRect.top + soleRect.height * 0.5,
      soleRect.width * 0.6,
      soleRect.height * 0.25,
    );
  }

  Rect _getHeelRect(Rect soleRect) {
    return Rect.fromLTWH(
      soleRect.left + soleRect.width * 0.1,
      soleRect.top + soleRect.height * 0.8,
      soleRect.width * 0.8,
      soleRect.height * 0.2,
    );
  }

  Color _getPressureColor(double pressure) {
    if (pressure <= 0) return Colors.grey.shade200;
    
    final intensity = math.min(pressure / 100.0, 1.0);
    
    if (intensity < 0.25) {
      return Color.lerp(Colors.blue.shade100, Colors.cyan, intensity * 4)!;
    } else if (intensity < 0.5) {
      return Color.lerp(Colors.cyan, Colors.green, (intensity - 0.25) * 4)!;
    } else if (intensity < 0.75) {
      return Color.lerp(Colors.green, Colors.yellow, (intensity - 0.5) * 4)!;
    } else {
      return Color.lerp(Colors.yellow, Colors.red, (intensity - 0.75) * 4)!;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
