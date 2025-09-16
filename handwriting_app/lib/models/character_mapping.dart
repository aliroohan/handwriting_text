import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

class CharacterMapping {
  final String character;
  final List<List<Offset>> strokes;
  final double width;
  final double height;
  final double baseline;

  CharacterMapping({
    required this.character,
    required this.strokes,
    required this.width,
    required this.height,
    this.baseline = 0.7,
  });

  // Convert strokes to a Path
  Path toPath() {
    final path = Path();
    
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      
      path.moveTo(stroke[0].dx, stroke[0].dy);
      
      if (stroke.length == 1) {
        // Single point - draw a small circle
        path.addOval(Rect.fromCircle(center: stroke[0], radius: 1));
      } else if (stroke.length == 2) {
        // Two points - draw a line
        path.lineTo(stroke[1].dx, stroke[1].dy);
      } else {
        // Multiple points - draw smooth curve
        for (int i = 1; i < stroke.length - 1; i++) {
          final p1 = stroke[i];
          final p2 = stroke[i + 1];
          final midPoint = Offset(
            (p1.dx + p2.dx) / 2,
            (p1.dy + p2.dy) / 2,
          );
          path.quadraticBezierTo(p1.dx, p1.dy, midPoint.dx, midPoint.dy);
        }
        // Connect to last point
        path.lineTo(stroke.last.dx, stroke.last.dy);
      }
    }
    
    return path;
  }

  // Scale the character to fit within given bounds
  CharacterMapping scale(double targetWidth, double targetHeight) {
    final scaleX = targetWidth / width;
    final scaleY = targetHeight / height;
    
    final scaledStrokes = strokes.map((stroke) {
      return stroke.map((point) {
        return Offset(point.dx * scaleX, point.dy * scaleY);
      }).toList();
    }).toList();
    
    return CharacterMapping(
      character: character,
      strokes: scaledStrokes,
      width: targetWidth,
      height: targetHeight,
      baseline: baseline,
    );
  }

  // Apply transformation to the character
  CharacterMapping transform(Matrix4 matrix) {
    final scaledStrokes = strokes.map((stroke) {
      return stroke.map((point) {
        final vector = matrix.transform3(Vector3(point.dx, point.dy, 0));
        return Offset(vector.x, vector.y);
      }).toList();
    }).toList();
    
    return CharacterMapping(
      character: character,
      strokes: scaledStrokes,
      width: width,
      height: height,
      baseline: baseline,
    );
  }

  // Create a simplified version with fewer points
  CharacterMapping simplify({double tolerance = 2.0}) {
    final simplifiedStrokes = strokes.map((stroke) {
      if (stroke.length <= 2) return stroke;
      
      final simplified = <Offset>[stroke.first];
      Offset lastPoint = stroke.first;
      
      for (int i = 1; i < stroke.length - 1; i++) {
        final currentPoint = stroke[i];
        final distance = (currentPoint - lastPoint).distance;
        
        if (distance >= tolerance) {
          simplified.add(currentPoint);
          lastPoint = currentPoint;
        }
      }
      
      simplified.add(stroke.last);
      return simplified;
    }).toList();
    
    return CharacterMapping(
      character: character,
      strokes: simplifiedStrokes,
      width: width,
      height: height,
      baseline: baseline,
    );
  }
}