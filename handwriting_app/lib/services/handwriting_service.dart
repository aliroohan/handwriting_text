import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/handwriting_style.dart';
import '../models/character_mapping.dart';
import '../utils/handwriting_analyzer.dart';

class HandwritingService extends ChangeNotifier {
  String? _sampleImagePath;
  String? _generatedImagePath;
  HandwritingStyle? _extractedStyle;
  bool _isProcessing = false;
  
  String? get sampleImagePath => _sampleImagePath;
  String? get generatedImagePath => _generatedImagePath;
  HandwritingStyle? get extractedStyle => _extractedStyle;
  bool get isProcessing => _isProcessing;

  void setSampleImage(String path) {
    _sampleImagePath = path;
    _extractedStyle = null;
    _generatedImagePath = null;
    notifyListeners();
    _analyzeHandwriting();
  }

  Future<void> _analyzeHandwriting() async {
    if (_sampleImagePath == null) return;
    
    _isProcessing = true;
    notifyListeners();
    
    try {
      // Analyze the handwriting sample
      final analyzer = HandwritingAnalyzer();
      _extractedStyle = await analyzer.analyzeImage(_sampleImagePath!);
    } catch (e) {
      print('Error analyzing handwriting: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> generateHandwriting(String text) async {
    if (_extractedStyle == null || text.isEmpty) return;
    
    _isProcessing = true;
    notifyListeners();
    
    try {
      // Create a canvas to draw the handwritten text
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Set up the canvas dimensions
      const double canvasWidth = 800;
      const double canvasHeight = 1200;
      const double margin = 50;
      const double lineHeight = 60;
      
      // Fill background
      final backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
        backgroundPaint,
      );
      
      // Draw handwritten text
      await _drawHandwrittenText(
        canvas,
        text,
        margin,
        margin,
        canvasWidth - (2 * margin),
        canvasHeight - (2 * margin),
        lineHeight,
      );
      
      // Convert canvas to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        canvasWidth.toInt(),
        canvasHeight.toInt(),
      );
      
      // Save the image
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/handwritten_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(buffer);
      
      _generatedImagePath = file.path;
    } catch (e) {
      print('Error generating handwriting: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _drawHandwrittenText(
    Canvas canvas,
    String text,
    double x,
    double y,
    double maxWidth,
    double maxHeight,
    double lineHeight,
  ) async {
    if (_extractedStyle == null) return;
    
    final style = _extractedStyle!;
    final random = Random();
    
    double currentX = x;
    double currentY = y + lineHeight;
    
    // Create paint for drawing
    final paint = Paint()
      ..color = style.inkColor
      ..strokeWidth = style.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    // Split text into words
    final words = text.split(' ');
    
    for (final word in words) {
      // Calculate word width (approximate)
      final wordWidth = word.length * style.characterWidth * 
        (1 + random.nextDouble() * 0.1); // Add some variation
      
      // Check if word fits on current line
      if (currentX + wordWidth > x + maxWidth) {
        currentX = x;
        currentY += lineHeight * (1 + random.nextDouble() * 0.1);
        
        if (currentY > y + maxHeight) break;
      }
      
      // Draw each character in the word
      for (final char in word.characters) {
        await _drawCharacter(
          canvas,
          char,
          currentX,
          currentY,
          paint,
          style,
          random,
        );
        
        currentX += style.characterWidth * 
          (1 + random.nextDouble() * style.widthVariation - style.widthVariation / 2);
      }
      
      // Add space after word
      currentX += style.spaceWidth * (1 + random.nextDouble() * 0.2);
    }
  }

  Future<void> _drawCharacter(
    Canvas canvas,
    String character,
    double x,
    double y,
    Paint paint,
    HandwritingStyle style,
    Random random,
  ) async {
    // Add character variations
    final angleVariation = (random.nextDouble() - 0.5) * style.slant;
    final sizeVariation = 1 + (random.nextDouble() - 0.5) * 0.1;
    final yOffset = (random.nextDouble() - 0.5) * style.baselineVariation;
    
    // Save canvas state
    canvas.save();
    
    // Apply transformations
    canvas.translate(x, y + yOffset);
    canvas.rotate(angleVariation);
    canvas.scale(sizeVariation);
    
    // Generate strokes for the character
    final path = _generateCharacterPath(character, style, random);
    
    // Add slight jitter to simulate hand movement
    final jitteredPath = _addJitterToPath(path, style.jitter);
    
    // Draw the character
    canvas.drawPath(jitteredPath, paint);
    
    // Restore canvas state
    canvas.restore();
  }

  Path _generateCharacterPath(
    String character,
    HandwritingStyle style,
    Random random,
  ) {
    final path = Path();
    
    // This is a simplified version - in a real implementation,
    // you would use character templates or neural network-based generation
    
    // For now, create simple strokes based on character type
    if (RegExp(r'[a-z]').hasMatch(character)) {
      _drawLowercaseLetter(path, character, style);
    } else if (RegExp(r'[A-Z]').hasMatch(character)) {
      _drawUppercaseLetter(path, character, style);
    } else if (RegExp(r'[0-9]').hasMatch(character)) {
      _drawDigit(path, character, style);
    } else {
      _drawPunctuation(path, character, style);
    }
    
    return path;
  }

  void _drawLowercaseLetter(Path path, String letter, HandwritingStyle style) {
    // Simplified lowercase letter drawing
    // In a real implementation, you would have specific paths for each letter
    final width = style.characterWidth * 0.7;
    final height = style.characterHeight * 0.5;
    
    switch (letter) {
      case 'a':
        path.moveTo(width * 0.8, height * 0.3);
        path.quadraticBezierTo(width * 0.5, 0, width * 0.2, height * 0.3);
        path.quadraticBezierTo(0, height * 0.6, width * 0.2, height * 0.9);
        path.quadraticBezierTo(width * 0.5, height, width * 0.8, height * 0.9);
        path.lineTo(width * 0.8, 0);
        break;
      case 'e':
        path.moveTo(width * 0.1, height * 0.5);
        path.lineTo(width * 0.9, height * 0.5);
        path.quadraticBezierTo(width, height * 0.2, width * 0.7, 0);
        path.quadraticBezierTo(width * 0.3, -height * 0.1, 0, height * 0.2);
        path.quadraticBezierTo(-width * 0.1, height * 0.8, width * 0.3, height);
        path.quadraticBezierTo(width * 0.7, height * 1.1, width * 0.9, height * 0.8);
        break;
      // Add more letters as needed
      default:
        // Default simple curve for other letters
        path.moveTo(0, height * 0.5);
        path.quadraticBezierTo(width * 0.5, 0, width, height * 0.5);
        path.quadraticBezierTo(width * 0.5, height, 0, height);
    }
  }

  void _drawUppercaseLetter(Path path, String letter, HandwritingStyle style) {
    // Simplified uppercase letter drawing
    final width = style.characterWidth;
    final height = style.characterHeight;
    
    switch (letter) {
      case 'A':
        path.moveTo(0, height);
        path.lineTo(width * 0.5, 0);
        path.lineTo(width, height);
        path.moveTo(width * 0.2, height * 0.6);
        path.lineTo(width * 0.8, height * 0.6);
        break;
      case 'B':
        path.moveTo(0, 0);
        path.lineTo(0, height);
        path.moveTo(0, 0);
        path.quadraticBezierTo(width, height * 0.1, width * 0.8, height * 0.25);
        path.quadraticBezierTo(width * 0.6, height * 0.4, 0, height * 0.5);
        path.quadraticBezierTo(width, height * 0.6, width * 0.8, height * 0.75);
        path.quadraticBezierTo(width * 0.6, height * 0.9, 0, height);
        break;
      // Add more letters as needed
      default:
        // Default vertical line for other letters
        path.moveTo(0, 0);
        path.lineTo(0, height);
    }
  }

  void _drawDigit(Path path, String digit, HandwritingStyle style) {
    // Simplified digit drawing
    final width = style.characterWidth * 0.8;
    final height = style.characterHeight;
    
    switch (digit) {
      case '0':
        path.addOval(Rect.fromLTWH(0, 0, width, height));
        break;
      case '1':
        path.moveTo(width * 0.3, height * 0.2);
        path.lineTo(width * 0.5, 0);
        path.lineTo(width * 0.5, height);
        break;
      // Add more digits as needed
      default:
        path.moveTo(0, height * 0.5);
        path.lineTo(width, height * 0.5);
    }
  }

  void _drawPunctuation(Path path, String punctuation, HandwritingStyle style) {
    // Simplified punctuation drawing
    final width = style.characterWidth * 0.3;
    final height = style.characterHeight;
    
    switch (punctuation) {
      case '.':
        path.addOval(Rect.fromLTWH(0, height * 0.8, width * 0.3, width * 0.3));
        break;
      case ',':
        path.moveTo(width * 0.2, height * 0.8);
        path.quadraticBezierTo(0, height * 0.9, width * 0.1, height);
        break;
      case '!':
        path.moveTo(width * 0.15, 0);
        path.lineTo(width * 0.15, height * 0.6);
        path.addOval(Rect.fromLTWH(0, height * 0.8, width * 0.3, width * 0.3));
        break;
      // Add more punctuation as needed
    }
  }

  Path _addJitterToPath(Path originalPath, double jitterAmount) {
    if (jitterAmount == 0) return originalPath;
    
    final jitteredPath = Path();
    final random = Random();
    
    // Convert path to points and add jitter
    final metrics = originalPath.computeMetrics();
    for (final metric in metrics) {
      final length = metric.length;
      const step = 2.0; // Sample every 2 units
      
      for (double distance = 0; distance <= length; distance += step) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          final jitterX = (random.nextDouble() - 0.5) * jitterAmount;
          final jitterY = (random.nextDouble() - 0.5) * jitterAmount;
          
          final point = tangent.position + Offset(jitterX, jitterY);
          
          if (distance == 0) {
            jitteredPath.moveTo(point.dx, point.dy);
          } else {
            jitteredPath.lineTo(point.dx, point.dy);
          }
        }
      }
    }
    
    return jitteredPath;
  }

  void clearGenerated() {
    _generatedImagePath = null;
    notifyListeners();
  }

  void reset() {
    _sampleImagePath = null;
    _generatedImagePath = null;
    _extractedStyle = null;
    _isProcessing = false;
    notifyListeners();
  }
}