import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/handwriting_style.dart';

class HandwritingAnalyzer {
  Future<HandwritingStyle> analyzeImage(String imagePath) async {
    try {
      // Load the image
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Analyze various aspects of the handwriting
      final inkColor = _detectInkColor(image);
      final strokeWidth = _estimateStrokeWidth(image);
      final slant = _estimateSlant(image);
      final characterMetrics = _estimateCharacterMetrics(image);
      final variations = _estimateVariations(image);

      return HandwritingStyle(
        inkColor: inkColor,
        strokeWidth: strokeWidth,
        slant: slant,
        characterHeight: characterMetrics['height']!,
        characterWidth: characterMetrics['width']!,
        spaceWidth: characterMetrics['spaceWidth']!,
        lineSpacing: characterMetrics['lineSpacing']!,
        baselineVariation: variations['baseline']!,
        jitter: variations['jitter']!,
        pressure: variations['pressure']!,
        widthVariation: variations['width']!,
      );
    } catch (e) {
      // Return default style if analysis fails
      return HandwritingStyle();
    }
  }

  Color _detectInkColor(img.Image image) {
    // Simple ink color detection - finds the most common dark color
    final colorCounts = <int, int>{};
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        // Check if pixel is dark (likely ink)
        if (r < 200 && g < 200 && b < 200) {
          final color = (r << 16) | (g << 8) | b;
          colorCounts[color] = (colorCounts[color] ?? 0) + 1;
        }
      }
    }
    
    if (colorCounts.isEmpty) {
      return Colors.black;
    }
    
    // Find most common color
    final mostCommon = colorCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return Color(0xFF000000 | mostCommon);
  }

  double _estimateStrokeWidth(img.Image image) {
    // Estimate stroke width by analyzing connected components
    final binary = _binarizeImage(image);
    final strokes = <int>[];
    
    // Sample horizontal lines
    for (int y = image.height ~/ 4; y < 3 * image.height ~/ 4; y += 10) {
      int strokeStart = -1;
      
      for (int x = 0; x < image.width; x++) {
        final isInk = binary.getPixel(x, y) == 0xFF000000;
        
        if (isInk && strokeStart == -1) {
          strokeStart = x;
        } else if (!isInk && strokeStart != -1) {
          strokes.add(x - strokeStart);
          strokeStart = -1;
        }
      }
    }
    
    if (strokes.isEmpty) return 2.0;
    
    // Calculate median stroke width
    strokes.sort();
    return strokes[strokes.length ~/ 2].toDouble() * 0.5;
  }

  double _estimateSlant(img.Image image) {
    // Estimate writing slant using Hough transform principles
    final binary = _binarizeImage(image);
    final angles = <double>[];
    
    // Sample vertical strokes
    for (int x = image.width ~/ 4; x < 3 * image.width ~/ 4; x += 20) {
      final points = <Point<int>>[];
      
      for (int y = 0; y < image.height; y++) {
        if (binary.getPixel(x, y) == 0xFF000000) {
          points.add(Point(x, y));
        }
      }
      
      if (points.length > 10) {
        // Fit line to points and calculate angle
        final angle = _fitLineAngle(points);
        if (angle != null) {
          angles.add(angle);
        }
      }
    }
    
    if (angles.isEmpty) return 0.0;
    
    // Calculate average angle
    final avgAngle = angles.reduce((a, b) => a + b) / angles.length;
    return avgAngle * pi / 180; // Convert to radians
  }

  Map<String, double> _estimateCharacterMetrics(img.Image image) {
    final binary = _binarizeImage(image);
    
    // Find text lines
    final linePositions = _findTextLines(binary);
    
    // Estimate line spacing
    double lineSpacing = 40.0;
    if (linePositions.length > 1) {
      final spacings = <double>[];
      for (int i = 1; i < linePositions.length; i++) {
        spacings.add((linePositions[i] - linePositions[i - 1]).toDouble());
      }
      lineSpacing = spacings.reduce((a, b) => a + b) / spacings.length;
    }
    
    // Estimate character dimensions
    final charBounds = _findCharacterBounds(binary);
    
    double avgHeight = 30.0;
    double avgWidth = 20.0;
    double avgSpace = 10.0;
    
    if (charBounds.isNotEmpty) {
      final heights = charBounds.map((b) => b['height']!.toDouble()).toList();
      final widths = charBounds.map((b) => b['width']!.toDouble()).toList();
      
      avgHeight = heights.reduce((a, b) => a + b) / heights.length;
      avgWidth = widths.reduce((a, b) => a + b) / widths.length;
      avgSpace = avgWidth * 0.5; // Approximate space width
    }
    
    return {
      'height': avgHeight,
      'width': avgWidth,
      'spaceWidth': avgSpace,
      'lineSpacing': lineSpacing,
    };
  }

  Map<String, double> _estimateVariations(img.Image image) {
    // Estimate various writing variations
    return {
      'baseline': 2.0, // Baseline variation in pixels
      'jitter': 0.5, // Hand shake amount
      'pressure': 0.8, // Pressure variation factor
      'width': 0.1, // Character width variation factor
    };
  }

  img.Image _binarizeImage(img.Image image) {
    // Convert to binary (black and white)
    final binary = img.Image(image.width, image.height);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = (img.getRed(pixel) + img.getGreen(pixel) + img.getBlue(pixel)) ~/ 3;
        
        // Threshold at 200
        if (gray < 200) {
          binary.setPixel(x, y, 0xFF000000); // Black
        } else {
          binary.setPixel(x, y, 0xFFFFFFFF); // White
        }
      }
    }
    
    return binary;
  }

  List<int> _findTextLines(img.Image binary) {
    final histogram = List<int>.filled(binary.height, 0);
    
    // Create horizontal projection
    for (int y = 0; y < binary.height; y++) {
      for (int x = 0; x < binary.width; x++) {
        if (binary.getPixel(x, y) == 0xFF000000) {
          histogram[y]++;
        }
      }
    }
    
    // Find peaks (text lines)
    final lines = <int>[];
    final threshold = binary.width * 0.02; // At least 2% of width
    
    for (int y = 1; y < binary.height - 1; y++) {
      if (histogram[y] > threshold &&
          histogram[y] > histogram[y - 1] &&
          histogram[y] > histogram[y + 1]) {
        lines.add(y);
      }
    }
    
    return lines;
  }

  List<Map<String, int>> _findCharacterBounds(img.Image binary) {
    final bounds = <Map<String, int>>[];
    
    // Simple connected component analysis
    // This is a simplified version - real implementation would be more sophisticated
    
    for (int y = 10; y < binary.height - 10; y += 30) {
      int charStart = -1;
      
      for (int x = 0; x < binary.width; x++) {
        bool hasInk = false;
        
        // Check vertical strip for ink
        for (int dy = -15; dy <= 15; dy++) {
          if (binary.getPixel(x, y + dy) == 0xFF000000) {
            hasInk = true;
            break;
          }
        }
        
        if (hasInk && charStart == -1) {
          charStart = x;
        } else if (!hasInk && charStart != -1) {
          final width = x - charStart;
          if (width > 5 && width < 100) {
            bounds.add({
              'x': charStart,
              'y': y - 15,
              'width': width,
              'height': 30,
            });
          }
          charStart = -1;
        }
      }
    }
    
    return bounds;
  }

  double? _fitLineAngle(List<Point<int>> points) {
    if (points.length < 2) return null;
    
    // Simple linear regression
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    for (final point in points) {
      sumX += point.x;
      sumY += point.y;
      sumXY += point.x * point.y;
      sumX2 += point.x * point.x;
    }
    
    final n = points.length;
    final denominator = n * sumX2 - sumX * sumX;
    
    if (denominator == 0) return null;
    
    final slope = (n * sumXY - sumX * sumY) / denominator;
    return atan(slope) * 180 / pi; // Convert to degrees
  }
}