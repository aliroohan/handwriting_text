import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/handwriting_style.dart';

class MLHandwritingAnalyzer {
  Future<HandwritingStyle> analyzeImageWithML(String imagePath, String recognizedText) async {
    try {
      // Load the image
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Enhanced analysis using ML techniques
      final inkColor = _detectInkColorAdvanced(image);
      final strokeWidth = _estimateStrokeWidthAdvanced(image);
      final slant = _estimateSlantAdvanced(image);
      final characterMetrics = _estimateCharacterMetricsAdvanced(image, recognizedText);
      final variations = _estimateVariationsAdvanced(image);
      final pressureProfile = _analyzePressureProfile(image);

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
      print('Error in ML handwriting analysis: $e');
      // Return enhanced default style
      return _getEnhancedDefaultStyle();
    }
  }

  Color _detectInkColorAdvanced(img.Image image) {
    // Advanced ink color detection using clustering
    final colorClusters = <ColorCluster>[];
    
    // Sample pixels to avoid processing entire image
    final sampleSize = min(10000, image.width * image.height);
    final step = (image.width * image.height) / sampleSize;
    
    for (int i = 0; i < sampleSize; i++) {
      final pixelIndex = (i * step).toInt();
      final y = pixelIndex ~/ image.width;
      final x = pixelIndex % image.width;
      
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        final pixel = image.getPixel(x, y);
        final r = img.getRed(pixel);
        final g = img.getGreen(pixel);
        final b = img.getBlue(pixel);
        
        // Check if pixel is dark (likely ink)
        if (r < 180 && g < 180 && b < 180) {
          final color = Color.fromARGB(255, r, g, b);
          
          // Find closest cluster or create new one
          ColorCluster? closestCluster;
          double minDistance = double.infinity;
          
          for (final cluster in colorClusters) {
            final distance = _colorDistance(color, cluster.centroid);
            if (distance < minDistance) {
              minDistance = distance;
              closestCluster = cluster;
            }
          }
          
          if (closestCluster != null && minDistance < 50) {
            closestCluster.addColor(color);
          } else {
            colorClusters.add(ColorCluster(color));
          }
        }
      }
    }
    
    if (colorClusters.isEmpty) {
      return Colors.black;
    }
    
    // Find the largest cluster (most common ink color)
    colorClusters.sort((a, b) => b.count.compareTo(a.count));
    return colorClusters.first.centroid;
  }

  double _colorDistance(Color a, Color b) {
    final dr = a.red - b.red;
    final dg = a.green - b.green;
    final db = a.blue - b.blue;
    return sqrt(dr * dr + dg * dg + db * db);
  }

  double _estimateStrokeWidthAdvanced(img.Image image) {
    // Advanced stroke width estimation using morphological operations
    final binary = _binarizeImageAdvanced(image);
    
    // Use distance transform to find stroke widths
    final distances = _computeDistanceTransform(binary);
    
    // Find the most common distance (stroke width)
    final widthHistogram = <int, int>{};
    for (int y = 0; y < distances.length; y++) {
      for (int x = 0; x < distances[y].length; x++) {
        if (distances[y][x] > 0) {
          final width = (distances[y][x] * 2).round();
          widthHistogram[width] = (widthHistogram[width] ?? 0) + 1;
        }
      }
    }
    
    if (widthHistogram.isEmpty) return 2.0;
    
    // Find the most common stroke width
    final mostCommonWidth = widthHistogram.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return mostCommonWidth.toDouble();
  }

  double _estimateSlantAdvanced(img.Image image) {
    // Advanced slant estimation using Hough transform
    final binary = _binarizeImageAdvanced(image);
    final angles = <double>[];
    
    // Extract vertical strokes using edge detection
    final edges = _detectEdges(binary);
    
    // Apply Hough transform to detect lines
    final houghSpace = _computeHoughTransform(edges);
    
    // Find dominant angles
    final dominantAngles = _findDominantAngles(houghSpace);
    
    if (dominantAngles.isEmpty) return 0.0;
    
    // Calculate weighted average of dominant angles
    double weightedSum = 0;
    double totalWeight = 0;
    
    for (final angle in dominantAngles) {
      final weight = _getAngleWeight(angle, houghSpace);
      weightedSum += angle * weight;
      totalWeight += weight;
    }
    
    return totalWeight > 0 ? (weightedSum / totalWeight) * pi / 180 : 0.0;
  }

  Map<String, double> _estimateCharacterMetricsAdvanced(img.Image image, String recognizedText) {
    final binary = _binarizeImageAdvanced(image);
    
    // Find text lines with improved algorithm
    final linePositions = _findTextLinesAdvanced(binary);
    
    // Estimate line spacing
    double lineSpacing = 40.0;
    if (linePositions.length > 1) {
      final spacings = <double>[];
      for (int i = 1; i < linePositions.length; i++) {
        spacings.add((linePositions[i] - linePositions[i - 1]).toDouble());
      }
      spacings.sort();
      // Use median spacing for more robust estimation
      lineSpacing = spacings[spacings.length ~/ 2];
    }
    
    // Advanced character segmentation
    final characters = _segmentCharactersAdvanced(binary, linePositions);
    
    double avgHeight = 30.0;
    double avgWidth = 20.0;
    double avgSpace = 10.0;
    
    if (characters.isNotEmpty) {
      final heights = characters.map((c) => c['height']!.toDouble()).toList();
      final widths = characters.map((c) => c['width']!.toDouble()).toList();
      
      heights.sort();
      widths.sort();
      
      // Use median values for robustness
      avgHeight = heights[heights.length ~/ 2];
      avgWidth = widths[widths.length ~/ 2];
      
      // Estimate space width based on character analysis
      avgSpace = _estimateSpaceWidth(binary, characters);
    }
    
    // Adjust based on recognized text length
    if (recognizedText.isNotEmpty) {
      final textLength = recognizedText.length;
      final estimatedTextWidth = _estimateTextWidth(binary);
      if (estimatedTextWidth > 0) {
        final avgCharWidth = estimatedTextWidth / textLength;
        avgWidth = (avgWidth + avgCharWidth) / 2;
      }
    }
    
    return {
      'height': avgHeight,
      'width': avgWidth,
      'spaceWidth': avgSpace,
      'lineSpacing': lineSpacing,
    };
  }

  Map<String, double> _estimateVariationsAdvanced(img.Image image) {
    final binary = _binarizeImageAdvanced(image);
    
    // Analyze baseline variation
    final baselineVariation = _analyzeBaselineVariation(binary);
    
    // Analyze jitter (hand shake)
    final jitter = _analyzeJitter(binary);
    
    // Analyze pressure variation
    final pressure = _analyzePressureVariation(image);
    
    // Analyze width variation
    final widthVariation = _analyzeWidthVariation(binary);
    
    return {
      'baseline': baselineVariation,
      'jitter': jitter,
      'pressure': pressure,
      'width': widthVariation,
    };
  }

  Map<String, double> _analyzePressureProfile(img.Image image) {
    // Analyze ink density to estimate pressure
    final binary = _binarizeImageAdvanced(image);
    final pressureMap = <String, double>{};
    
    // Sample different regions to analyze pressure variation
    final regions = [
      {'name': 'light', 'threshold': 0.3},
      {'name': 'medium', 'threshold': 0.6},
      {'name': 'heavy', 'threshold': 0.9},
    ];
    
    for (final region in regions) {
      final density = _calculateInkDensity(binary);
      pressureMap[region['name'] as String] = density;
    }
    
    return pressureMap;
  }

  img.Image _binarizeImageAdvanced(img.Image image) {
    // Advanced binarization using adaptive thresholding
    final binary = img.Image(image.width, image.height);
    
    // Convert to grayscale first
    final grayscale = img.grayscale(image);
    
    // Apply adaptive thresholding
    final blockSize = 15;
    final c = 10; // Constant subtracted from mean
    
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final threshold = _calculateAdaptiveThreshold(grayscale, x, y, blockSize, c);
        final pixel = grayscale.getPixel(x, y);
        final gray = img.getLuminance(pixel);
        
        if (gray < threshold) {
          binary.setPixel(x, y, 0xFF000000); // Black
        } else {
          binary.setPixel(x, y, 0xFFFFFFFF); // White
        }
      }
    }
    
    return binary;
  }

  int _calculateAdaptiveThreshold(img.Image image, int x, int y, int blockSize, int c) {
    final halfBlock = blockSize ~/ 2;
    int sum = 0;
    int count = 0;
    
    for (int dy = -halfBlock; dy <= halfBlock; dy++) {
      for (int dx = -halfBlock; dx <= halfBlock; dx++) {
        final nx = x + dx;
        final ny = y + dy;
        
        if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
          final pixel = image.getPixel(nx, ny);
          sum += img.getLuminance(pixel);
          count++;
        }
      }
    }
    
    return count > 0 ? (sum / count) - c : 128;
  }

  List<List<double>> _computeDistanceTransform(List<List<int>> binary) {
    final width = binary[0].length;
    final height = binary.length;
    final distances = List.generate(height, (_) => List.filled(width, 0.0));
    
    // Forward pass
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (binary[y][x] == 0) { // Black pixel
          double minDist = double.infinity;
          
          for (int dy = 0; dy <= 1; dy++) {
            for (int dx = 0; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) continue;
              
              final nx = x - dx;
              final ny = y - dy;
              
              if (nx >= 0 && ny >= 0) {
                final dist = distances[ny][nx] + sqrt(dx * dx + dy * dy);
                if (dist < minDist) {
                  minDist = dist;
                }
              }
            }
          }
          
          distances[y][x] = minDist == double.infinity ? 1.0 : minDist;
        }
      }
    }
    
    // Backward pass
    for (int y = height - 1; y >= 0; y--) {
      for (int x = width - 1; x >= 0; x--) {
        if (binary[y][x] == 0) { // Black pixel
          double minDist = distances[y][x];
          
          for (int dy = 0; dy <= 1; dy++) {
            for (int dx = 0; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) continue;
              
              final nx = x + dx;
              final ny = y + dy;
              
              if (nx < width && ny < height) {
                final dist = distances[ny][nx] + sqrt(dx * dx + dy * dy);
                if (dist < minDist) {
                  minDist = dist;
                }
              }
            }
          }
          
          distances[y][x] = minDist;
        }
      }
    }
    
    return distances;
  }

  List<List<int>> _detectEdges(List<List<int>> binary) {
    final width = binary[0].length;
    final height = binary.length;
    final edges = List.generate(height, (_) => List.filled(width, 0));
    
    // Simple Sobel edge detection
    final sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];
    
    final sobelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];
    
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        int gx = 0, gy = 0;
        
        for (int ky = 0; ky < 3; ky++) {
          for (int kx = 0; kx < 3; kx++) {
            final pixel = binary[y + ky - 1][x + kx - 1] == 0 ? 1 : 0;
            gx += pixel * sobelX[ky][kx];
            gy += pixel * sobelY[ky][kx];
          }
        }
        
        final magnitude = sqrt(gx * gx + gy * gy).toInt();
        edges[y][x] = magnitude > 50 ? 1 : 0;
      }
    }
    
    return edges;
  }

  List<List<int>> _computeHoughTransform(List<List<int>> edges) {
    final width = edges[0].length;
    final height = edges.length;
    
    // Hough space dimensions
    const int thetaSteps = 180;
    const int rhoSteps = 400;
    final maxRho = sqrt(width * width + height * height);
    
    final houghSpace = List.generate(rhoSteps, (_) => List.filled(thetaSteps, 0));
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (edges[y][x] == 1) {
          for (int theta = 0; theta < thetaSteps; theta++) {
            final thetaRad = theta * pi / 180;
            final rho = x * cos(thetaRad) + y * sin(thetaRad);
            
            if (rho >= 0 && rho < maxRho) {
              final rhoIndex = (rho * rhoSteps / maxRho).toInt();
              if (rhoIndex >= 0 && rhoIndex < rhoSteps) {
                houghSpace[rhoIndex][theta]++;
              }
            }
          }
        }
      }
    }
    
    return houghSpace;
  }

  List<double> _findDominantAngles(List<List<int>> houghSpace) {
    final angles = <double>[];
    final threshold = 10; // Minimum votes for a line
    
    for (int rho = 0; rho < houghSpace.length; rho++) {
      for (int theta = 0; theta < houghSpace[rho].length; theta++) {
        if (houghSpace[rho][theta] > threshold) {
          angles.add(theta.toDouble());
        }
      }
    }
    
    return angles;
  }

  double _getAngleWeight(double angle, List<List<int>> houghSpace) {
    final thetaIndex = angle.toInt();
    if (thetaIndex < 0 || thetaIndex >= houghSpace[0].length) return 0;
    
    int maxVotes = 0;
    for (int rho = 0; rho < houghSpace.length; rho++) {
      if (houghSpace[rho][thetaIndex] > maxVotes) {
        maxVotes = houghSpace[rho][thetaIndex];
      }
    }
    
    return maxVotes.toDouble();
  }

  List<int> _findTextLinesAdvanced(List<List<int>> binary) {
    final histogram = List<int>.filled(binary.length, 0);
    
    // Create horizontal projection
    for (int y = 0; y < binary.length; y++) {
      for (int x = 0; x < binary[y].length; x++) {
        if (binary[y][x] == 0) { // Black pixel
          histogram[y]++;
        }
      }
    }
    
    // Find peaks with improved algorithm
    final lines = <int>[];
    final smoothedHistogram = _smoothHistogram(histogram, 5);
    
    for (int y = 2; y < smoothedHistogram.length - 2; y++) {
      if (_isLocalMaximum(smoothedHistogram, y, 2)) {
        final threshold = binary[0].length * 0.01; // At least 1% of width
        if (smoothedHistogram[y] > threshold) {
          lines.add(y);
        }
      }
    }
    
    return lines;
  }

  List<int> _smoothHistogram(List<int> histogram, int windowSize) {
    final smoothed = List<int>.filled(histogram.length, 0);
    final halfWindow = windowSize ~/ 2;
    
    for (int i = 0; i < histogram.length; i++) {
      int sum = 0;
      int count = 0;
      
      for (int j = max(0, i - halfWindow); j <= min(histogram.length - 1, i + halfWindow); j++) {
        sum += histogram[j];
        count++;
      }
      
      smoothed[i] = count > 0 ? sum ~/ count : histogram[i];
    }
    
    return smoothed;
  }

  bool _isLocalMaximum(List<int> histogram, int index, int radius) {
    final value = histogram[index];
    
    for (int i = max(0, index - radius); i <= min(histogram.length - 1, index + radius); i++) {
      if (i != index && histogram[i] >= value) {
        return false;
      }
    }
    
    return true;
  }

  List<Map<String, int>> _segmentCharactersAdvanced(List<List<int>> binary, List<int> linePositions) {
    final characters = <Map<String, int>>[];
    
    for (int i = 0; i < linePositions.length; i++) {
      final lineY = linePositions[i];
      final lineHeight = i < linePositions.length - 1 
          ? linePositions[i + 1] - lineY 
          : 50; // Default height for last line
      
      final lineCharacters = _segmentCharactersInLine(binary, lineY, lineHeight);
      characters.addAll(lineCharacters);
    }
    
    return characters;
  }

  List<Map<String, int>> _segmentCharactersInLine(List<List<int>> binary, int lineY, int lineHeight) {
    final characters = <Map<String, int>>[];
    final width = binary[0].length;
    
    int charStart = -1;
    int charEnd = -1;
    
    for (int x = 0; x < width; x++) {
      bool hasInk = false;
      
      // Check if there's ink in this column
      for (int dy = 0; dy < lineHeight; dy++) {
        final y = lineY + dy;
        if (y >= 0 && y < binary.length && x < binary[y].length) {
          if (binary[y][x] == 0) { // Black pixel
            hasInk = true;
            break;
          }
        }
      }
      
      if (hasInk && charStart == -1) {
        charStart = x;
      } else if (!hasInk && charStart != -1) {
        charEnd = x;
        
        // Find character bounds
        final charBounds = _findCharacterBounds(binary, charStart, charEnd, lineY, lineHeight);
        if (charBounds != null) {
          characters.add(charBounds);
        }
        
        charStart = -1;
        charEnd = -1;
      }
    }
    
    return characters;
  }

  Map<String, int>? _findCharacterBounds(List<List<int>> binary, int startX, int endX, int lineY, int lineHeight) {
    int minY = lineY + lineHeight;
    int maxY = lineY;
    
    for (int x = startX; x < endX; x++) {
      for (int dy = 0; dy < lineHeight; dy++) {
        final y = lineY + dy;
        if (y >= 0 && y < binary.length && x < binary[y].length) {
          if (binary[y][x] == 0) { // Black pixel
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }
    }
    
    final width = endX - startX;
    final height = maxY - minY;
    
    if (width > 3 && height > 3 && width < 100 && height < 100) {
      return {
        'x': startX,
        'y': minY,
        'width': width,
        'height': height,
      };
    }
    
    return null;
  }

  double _estimateSpaceWidth(List<List<int>> binary, List<Map<String, int>> characters) {
    if (characters.length < 2) return 20.0;
    
    final spaces = <double>[];
    
    for (int i = 1; i < characters.length; i++) {
      final prevChar = characters[i - 1];
      final currChar = characters[i];
      
      // Check if characters are on the same line (similar Y coordinates)
      if ((currChar['y']! - prevChar['y']!).abs() < 20) {
        final space = currChar['x']! - (prevChar['x']! + prevChar['width']!);
        if (space > 0 && space < 50) {
          spaces.add(space.toDouble());
        }
      }
    }
    
    if (spaces.isEmpty) return 20.0;
    
    spaces.sort();
    return spaces[spaces.length ~/ 2]; // Median space width
  }

  double _estimateTextWidth(List<List<int>> binary) {
    int minX = binary[0].length;
    int maxX = 0;
    
    for (int y = 0; y < binary.length; y++) {
      for (int x = 0; x < binary[y].length; x++) {
        if (binary[y][x] == 0) { // Black pixel
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
        }
      }
    }
    
    return (maxX - minX).toDouble();
  }

  double _analyzeBaselineVariation(List<List<int>> binary) {
    final linePositions = _findTextLinesAdvanced(binary);
    if (linePositions.length < 2) return 2.0;
    
    final variations = <double>[];
    for (int i = 1; i < linePositions.length; i++) {
      final expectedSpacing = linePositions[i] - linePositions[i - 1];
      final actualSpacing = linePositions[i] - linePositions[i - 1];
      variations.add((actualSpacing - expectedSpacing).abs().toDouble());
    }
    
    if (variations.isEmpty) return 2.0;
    
    variations.sort();
    return variations[variations.length ~/ 2];
  }

  double _analyzeJitter(List<List<int>> binary) {
    // Analyze stroke smoothness to estimate jitter
    final edges = _detectEdges(binary);
    int totalEdges = 0;
    int jaggedEdges = 0;
    
    for (int y = 1; y < edges.length - 1; y++) {
      for (int x = 1; x < edges[y].length - 1; x++) {
        if (edges[y][x] == 1) {
          totalEdges++;
          
          // Check for jaggedness in 3x3 neighborhood
          int neighbors = 0;
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) continue;
              if (y + dy >= 0 && y + dy < edges.length && 
                  x + dx >= 0 && x + dx < edges[y + dy].length) {
                if (edges[y + dy][x + dx] == 1) {
                  neighbors++;
                }
              }
            }
          }
          
          if (neighbors < 2) { // Isolated edge points indicate jitter
            jaggedEdges++;
          }
        }
      }
    }
    
    return totalEdges > 0 ? (jaggedEdges / totalEdges) * 2.0 : 0.5;
  }

  double _analyzePressureVariation(img.Image image) {
    final binary = _binarizeImageAdvanced(image);
    final densities = <double>[];
    
    // Sample different regions
    const sampleSize = 50;
    final step = binary.length ~/ sampleSize;
    
    for (int i = 0; i < sampleSize; i++) {
      final y = i * step;
      if (y >= 0 && y < binary.length) {
        final density = _calculateInkDensityInRow(binary, y);
        if (density > 0) {
          densities.add(density);
        }
      }
    }
    
    if (densities.isEmpty) return 0.8;
    
    densities.sort();
    final medianDensity = densities[densities.length ~/ 2];
    final maxDensity = densities.last;
    
    return min(1.0, medianDensity / maxDensity);
  }

  double _calculateInkDensityInRow(List<List<int>> binary, int y) {
    if (y < 0 || y >= binary.length) return 0.0;
    
    int inkPixels = 0;
    for (int x = 0; x < binary[y].length; x++) {
      if (binary[y][x] == 0) { // Black pixel
        inkPixels++;
      }
    }
    
    return inkPixels / binary[y].length;
  }

  double _analyzeWidthVariation(List<List<int>> binary) {
    final characters = _segmentCharactersAdvanced(binary, _findTextLinesAdvanced(binary));
    if (characters.length < 3) return 0.1;
    
    final widths = characters.map((c) => c['width']!.toDouble()).toList();
    widths.sort();
    
    final medianWidth = widths[widths.length ~/ 2];
    final variations = widths.map((w) => (w - medianWidth).abs() / medianWidth).toList();
    
    variations.sort();
    return min(0.3, variations[variations.length ~/ 2]);
  }

  double _calculateInkDensity(List<List<int>> binary) {
    int totalPixels = 0;
    int inkPixels = 0;
    
    for (int y = 0; y < binary.length; y++) {
      for (int x = 0; x < binary[y].length; x++) {
        totalPixels++;
        if (binary[y][x] == 0) { // Black pixel
          inkPixels++;
        }
      }
    }
    
    return totalPixels > 0 ? inkPixels / totalPixels : 0.0;
  }

  HandwritingStyle _getEnhancedDefaultStyle() {
    return HandwritingStyle(
      inkColor: Colors.black,
      strokeWidth: 2.5,
      slant: 0.1,
      characterHeight: 35.0,
      characterWidth: 25.0,
      spaceWidth: 15.0,
      lineSpacing: 45.0,
      baselineVariation: 2.5,
      jitter: 0.8,
      pressure: 0.9,
      widthVariation: 0.15,
    );
  }
}

class ColorCluster {
  Color centroid;
  int count = 0;
  int redSum = 0;
  int greenSum = 0;
  int blueSum = 0;

  ColorCluster(Color color) {
    centroid = color;
    addColor(color);
  }

  void addColor(Color color) {
    redSum += color.red;
    greenSum += color.green;
    blueSum += color.blue;
    count++;
    
    centroid = Color.fromARGB(
      255,
      redSum ~/ count,
      greenSum ~/ count,
      blueSum ~/ count,
    );
  }
}