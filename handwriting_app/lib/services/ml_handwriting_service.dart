import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../models/handwriting_style.dart';
import '../models/character_mapping.dart';
import '../utils/handwriting_analyzer.dart';

class MLHandwritingService extends ChangeNotifier {
  String? _sampleImagePath;
  String? _generatedImagePath;
  Uint8List? _generatedImageBytes;
  HandwritingStyle? _extractedStyle;
  bool _isProcessing = false;
  
  // ML Models
  Interpreter? _styleTransferModel;
  Interpreter? _characterGenerationModel;
  TextRecognizer? _textRecognizer;
  
  // Model parameters
  static const int _inputSize = 224;
  static const int _outputSize = 224;
  
  String? get sampleImagePath => _sampleImagePath;
  String? get generatedImagePath => _generatedImagePath;
  Uint8List? get generatedImageBytes => _generatedImageBytes;
  HandwritingStyle? get extractedStyle => _extractedStyle;
  bool get isProcessing => _isProcessing;

  Future<void> initializeModels() async {
    try {
      // Initialize Text Recognizer for OCR
      _textRecognizer = TextRecognizer();
      
      // Load TensorFlow Lite models
      await _loadStyleTransferModel();
      await _loadCharacterGenerationModel();
      
      print('ML models initialized successfully');
    } catch (e) {
      print('Error initializing ML models: $e');
      // Fallback to basic implementation if models fail to load
    }
  }

  Future<void> _loadStyleTransferModel() async {
    try {
      // In a real implementation, you would load a pre-trained style transfer model
      // For now, we'll create a placeholder that can be replaced with actual model
      _styleTransferModel = null; // Placeholder
      print('Style transfer model loaded (placeholder)');
    } catch (e) {
      print('Error loading style transfer model: $e');
    }
  }

  Future<void> _loadCharacterGenerationModel() async {
    try {
      // In a real implementation, you would load a pre-trained character generation model
      // For now, we'll create a placeholder that can be replaced with actual model
      _characterGenerationModel = null; // Placeholder
      print('Character generation model loaded (placeholder)');
    } catch (e) {
      print('Error loading character generation model: $e');
    }
  }

  void setSampleImage(String path) {
    _sampleImagePath = path;
    _extractedStyle = null;
    _generatedImagePath = null;
    notifyListeners();
    _analyzeHandwritingWithML();
  }

  Future<void> _analyzeHandwritingWithML() async {
    if (_sampleImagePath == null) return;
    
    _isProcessing = true;
    notifyListeners();
    
    try {
      // Use ML Kit for text recognition
      final recognizedText = await _performOCR(_sampleImagePath!);
      
      // Analyze handwriting with enhanced ML-based analyzer
      final analyzer = MLHandwritingAnalyzer();
      _extractedStyle = await analyzer.analyzeImageWithML(_sampleImagePath!, recognizedText);
      
      print('Handwriting analysis completed with ML');
      print('Recognized text: $recognizedText');
    } catch (e) {
      print('Error analyzing handwriting with ML: $e');
      // Fallback to basic analyzer
      final analyzer = HandwritingAnalyzer();
      _extractedStyle = await analyzer.analyzeImage(_sampleImagePath!);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<String> _performOCR(String imagePath) async {
    try {
      if (_textRecognizer == null) {
        _textRecognizer = TextRecognizer();
      }
      
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      print('Error performing OCR: $e');
      return '';
    }
  }

  Future<void> generateHandwriting(String text) async {
    if (_extractedStyle == null || text.isEmpty) return;
    
    _isProcessing = true;
    notifyListeners();
    
    try {
      // Use ML-based generation if models are available
      if (_characterGenerationModel != null) {
        await _generateWithML(text);
      } else {
        await _generateWithEnhancedAlgorithm(text);
      }
    } catch (e) {
      print('Error generating handwriting: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _generateWithML(String text) async {
    // Placeholder for ML-based generation
    // In a real implementation, this would use the loaded TensorFlow Lite model
    print('ML-based generation (placeholder)');
    await _generateWithEnhancedAlgorithm(text);
  }

  Future<void> _generateWithEnhancedAlgorithm(String text) async {
    // Enhanced algorithm with better character generation
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Set up the canvas dimensions
    const double canvasWidth = 1200;
    const double canvasHeight = 1600;
    const double margin = 80;
    const double lineHeight = 80;
    
    // Fill background with paper-like texture
    await _drawPaperBackground(canvas, canvasWidth, canvasHeight);
    
    // Draw handwritten text with enhanced algorithm
    await _drawEnhancedHandwrittenText(
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
    
    // Get PNG bytes
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    if (kIsWeb) {
      _generatedImageBytes = buffer;
      _generatedImagePath = null;
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/handwritten_ml_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(buffer);
      _generatedImagePath = file.path;
      _generatedImageBytes = null;
    }
  }

  Future<void> _drawPaperBackground(Canvas canvas, double width, double height) async {
    // Create paper-like background
    final backgroundPaint = Paint()..color = const Color(0xFFFDFCF8);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);
    
    // Add subtle paper texture
    final texturePaint = Paint()
      ..color = const Color(0xFFF5F5F5)
      ..strokeWidth = 0.5;
    
    final random = Random(42); // Fixed seed for consistent texture
    for (int i = 0; i < 1000; i++) {
      final x = random.nextDouble() * width;
      final y = random.nextDouble() * height;
      canvas.drawPoint(Offset(x, y), texturePaint);
    }
    
    // Add ruled lines if style suggests lined paper
    if (_extractedStyle?.lineSpacing != null && _extractedStyle!.lineSpacing > 0) {
      final linePaint = Paint()
        ..color = const Color(0xFFE0E0E0)
        ..strokeWidth = 0.5;
      
      final lineSpacing = _extractedStyle!.lineSpacing;
      for (double y = 100; y < height - 100; y += lineSpacing) {
        canvas.drawLine(
          Offset(50, y),
          Offset(width - 50, y),
          linePaint,
        );
      }
    }
  }

  Future<void> _drawEnhancedHandwrittenText(
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
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    
    double currentX = x;
    double currentY = y + lineHeight;
    
    // Create paint for drawing with enhanced parameters
    final paint = Paint()
      ..color = style.inkColor
      ..strokeWidth = style.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    // Split text into words
    final words = text.split(' ');
    
    for (final word in words) {
      // Calculate word width with better estimation
      final wordWidth = _estimateWordWidth(word, style);
      
      // Check if word fits on current line
      if (currentX + wordWidth > x + maxWidth) {
        currentX = x;
        currentY += lineHeight * (1 + random.nextDouble() * 0.15);
        
        if (currentY > y + maxHeight) break;
      }
      
      // Draw each character in the word with enhanced generation
      for (int i = 0; i < word.length; i++) {
        final char = word[i];
        await _drawEnhancedCharacter(
          canvas,
          char,
          currentX,
          currentY,
          paint,
          style,
          random,
          i == 0, // isFirstLetter
          i == word.length - 1, // isLastLetter
        );
        
        currentX += _getCharacterWidth(char, style) * 
          (1 + random.nextDouble() * style.widthVariation - style.widthVariation / 2);
      }
      
      // Add space after word with natural variation
      currentX += style.spaceWidth * (0.8 + random.nextDouble() * 0.4);
    }
  }

  double _estimateWordWidth(String word, HandwritingStyle style) {
    double width = 0;
    for (final char in word.characters) {
      width += _getCharacterWidth(char, style);
    }
    return width * 0.9; // Slight compression for natural look
  }

  double _getCharacterWidth(String character, HandwritingStyle style) {
    // More accurate character width estimation
    if (character == 'i' || character == 'l' || character == 't') {
      return style.characterWidth * 0.3;
    } else if (character == 'm' || character == 'w') {
      return style.characterWidth * 1.4;
    } else if (character == 'f' || character == 'j' || character == 'p' || character == 'q' || character == 'y') {
      return style.characterWidth * 0.8;
    }
    return style.characterWidth;
  }

  Future<void> _drawEnhancedCharacter(
    Canvas canvas,
    String character,
    double x,
    double y,
    Paint paint,
    HandwritingStyle style,
    Random random,
    bool isFirstLetter,
    bool isLastLetter,
  ) async {
    // Enhanced character generation with more realistic variations
    final angleVariation = (random.nextDouble() - 0.5) * style.slant * 2;
    final sizeVariation = 0.9 + random.nextDouble() * 0.2;
    final yOffset = (random.nextDouble() - 0.5) * style.baselineVariation * 1.5;
    
    // Add pressure variation
    final pressureVariation = 0.8 + random.nextDouble() * 0.4;
    final adjustedStrokeWidth = style.strokeWidth * pressureVariation;
    
    // Save canvas state
    canvas.save();
    
    // Apply transformations
    canvas.translate(x, y + yOffset);
    canvas.rotate(angleVariation);
    canvas.scale(sizeVariation);
    
    // Generate enhanced character path
    final path = _generateEnhancedCharacterPath(character, style, random, isFirstLetter, isLastLetter);
    
    // Add realistic jitter
    final jitteredPath = _addRealisticJitterToPath(path, style.jitter * 1.5);
    
    // Draw with adjusted stroke width
    final adjustedPaint = Paint()
      ..color = paint.color
      ..strokeWidth = adjustedStrokeWidth
      ..style = paint.style
      ..strokeCap = paint.strokeCap
      ..strokeJoin = paint.strokeJoin;
    
    canvas.drawPath(jitteredPath, adjustedPaint);
    
    // Restore canvas state
    canvas.restore();
  }

  Path _generateEnhancedCharacterPath(
    String character,
    HandwritingStyle style,
    Random random,
    bool isFirstLetter,
    bool isLastLetter,
  ) {
    final path = Path();
    
    // Use enhanced character templates with more realistic strokes
    if (RegExp(r'[a-z]').hasMatch(character)) {
      _drawEnhancedLowercaseLetter(path, character, style, random, isFirstLetter, isLastLetter);
    } else if (RegExp(r'[A-Z]').hasMatch(character)) {
      _drawEnhancedUppercaseLetter(path, character, style, random);
    } else if (RegExp(r'[0-9]').hasMatch(character)) {
      _drawEnhancedDigit(path, character, style, random);
    } else {
      _drawEnhancedPunctuation(path, character, style, random);
    }
    
    return path;
  }

  void _drawEnhancedLowercaseLetter(Path path, String letter, HandwritingStyle style, Random random, bool isFirstLetter, bool isLastLetter) {
    final width = style.characterWidth * 0.7;
    final height = style.characterHeight * 0.5;
    
    // Add connection strokes for cursive-like appearance
    if (isFirstLetter && random.nextDouble() > 0.3) {
      path.moveTo(-width * 0.1, height * 0.5);
      path.lineTo(0, height * 0.5);
    }
    
    switch (letter) {
      case 'a':
        _drawLetterA(path, width, height, style, random);
        break;
      case 'e':
        _drawLetterE(path, width, height, style, random);
        break;
      case 'h':
        _drawLetterH(path, width, height, style, random);
        break;
      case 'l':
        _drawLetterL(path, width, height, style, random);
        break;
      case 'o':
        _drawLetterO(path, width, height, style, random);
        break;
      case 't':
        _drawLetterT(path, width, height, style, random);
        break;
      default:
        _drawGenericLetter(path, letter, width, height, style, random);
    }
    
    // Add exit stroke for cursive-like appearance
    if (isLastLetter && random.nextDouble() > 0.4) {
      path.moveTo(width, height * 0.5);
      path.lineTo(width * 1.1, height * 0.5);
    }
  }

  void _drawLetterA(Path path, double width, double height, HandwritingStyle style, Random random) {
    // More realistic 'a' with proper stroke order
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.3 + offsetX, height * 0.9 + offsetY);
    path.quadraticBezierTo(width * 0.1, height * 0.7, width * 0.3, height * 0.5);
    path.quadraticBezierTo(width * 0.5, height * 0.3, width * 0.7, height * 0.5);
    path.quadraticBezierTo(width * 0.9, height * 0.7, width * 0.7, height * 0.9);
    path.lineTo(width * 0.7, height * 0.5);
    path.lineTo(width * 0.7, height * 0.9);
  }

  void _drawLetterE(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.8 + offsetX, height * 0.9 + offsetY);
    path.lineTo(width * 0.2, height * 0.9);
    path.lineTo(width * 0.2, height * 0.1);
    path.lineTo(width * 0.8, height * 0.1);
    path.moveTo(width * 0.2, height * 0.5);
    path.lineTo(width * 0.6, height * 0.5);
  }

  void _drawLetterH(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.2 + offsetX, height * 0.9 + offsetY);
    path.lineTo(width * 0.2, height * 0.1);
    path.moveTo(width * 0.8, height * 0.9);
    path.lineTo(width * 0.8, height * 0.1);
    path.moveTo(width * 0.2, height * 0.5);
    path.lineTo(width * 0.8, height * 0.5);
  }

  void _drawLetterL(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.2 + offsetX, height * 0.1 + offsetY);
    path.lineTo(width * 0.2, height * 0.9);
    path.lineTo(width * 0.8, height * 0.9);
  }

  void _drawLetterO(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.5 + offsetX, height * 0.9 + offsetY);
    path.quadraticBezierTo(width * 0.1, height * 0.7, width * 0.1, height * 0.5);
    path.quadraticBezierTo(width * 0.1, height * 0.3, width * 0.5, height * 0.1);
    path.quadraticBezierTo(width * 0.9, height * 0.3, width * 0.9, height * 0.5);
    path.quadraticBezierTo(width * 0.9, height * 0.7, width * 0.5, height * 0.9);
  }

  void _drawLetterT(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.2 + offsetX, height * 0.2 + offsetY);
    path.lineTo(width * 0.8, height * 0.2);
    path.moveTo(width * 0.5, height * 0.2);
    path.lineTo(width * 0.5, height * 0.9);
  }

  void _drawGenericLetter(Path path, String letter, double width, double height, HandwritingStyle style, Random random) {
    // Generic letter drawing for unhandled characters
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.2 + offsetX, height * 0.9 + offsetY);
    path.quadraticBezierTo(width * 0.5, height * 0.1, width * 0.8, height * 0.9);
  }

  void _drawEnhancedUppercaseLetter(Path path, String letter, HandwritingStyle style, Random random) {
    final width = style.characterWidth;
    final height = style.characterHeight;
    
    switch (letter) {
      case 'A':
        _drawUppercaseA(path, width, height, style, random);
        break;
      case 'B':
        _drawUppercaseB(path, width, height, style, random);
        break;
      default:
        _drawGenericUppercaseLetter(path, letter, width, height, style, random);
    }
  }

  void _drawUppercaseA(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.1 + offsetX, height * 0.9 + offsetY);
    path.lineTo(width * 0.5, height * 0.1);
    path.lineTo(width * 0.9, height * 0.9);
    path.moveTo(width * 0.3, height * 0.6);
    path.lineTo(width * 0.7, height * 0.6);
  }

  void _drawUppercaseB(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.2 + offsetX, height * 0.1 + offsetY);
    path.lineTo(width * 0.2, height * 0.9);
    path.moveTo(width * 0.2, height * 0.1);
    path.quadraticBezierTo(width * 0.8, height * 0.2, width * 0.8, height * 0.4);
    path.quadraticBezierTo(width * 0.8, height * 0.6, width * 0.2, height * 0.5);
    path.moveTo(width * 0.2, height * 0.5);
    path.quadraticBezierTo(width * 0.8, height * 0.6, width * 0.8, height * 0.8);
    path.quadraticBezierTo(width * 0.8, height * 0.9, width * 0.2, height * 0.9);
  }

  void _drawGenericUppercaseLetter(Path path, String letter, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.2 + offsetX, height * 0.1 + offsetY);
    path.lineTo(width * 0.2, height * 0.9);
  }

  void _drawEnhancedDigit(Path path, String digit, HandwritingStyle style, Random random) {
    final width = style.characterWidth * 0.8;
    final height = style.characterHeight;
    
    switch (digit) {
      case '0':
        _drawDigitZero(path, width, height, style, random);
        break;
      case '1':
        _drawDigitOne(path, width, height, style, random);
        break;
      case '2':
        _drawDigitTwo(path, width, height, style, random);
        break;
      default:
        _drawGenericDigit(path, digit, width, height, style, random);
    }
  }

  void _drawDigitZero(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.5 + offsetX, height * 0.9 + offsetY);
    path.quadraticBezierTo(width * 0.1, height * 0.7, width * 0.1, height * 0.5);
    path.quadraticBezierTo(width * 0.1, height * 0.3, width * 0.5, height * 0.1);
    path.quadraticBezierTo(width * 0.9, height * 0.3, width * 0.9, height * 0.5);
    path.quadraticBezierTo(width * 0.9, height * 0.7, width * 0.5, height * 0.9);
  }

  void _drawDigitOne(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.3 + offsetX, height * 0.3 + offsetY);
    path.lineTo(width * 0.5, height * 0.1);
    path.lineTo(width * 0.5, height * 0.9);
  }

  void _drawDigitTwo(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.1 + offsetX, height * 0.3 + offsetY);
    path.quadraticBezierTo(width * 0.5, height * 0.1, width * 0.9, height * 0.3);
    path.lineTo(width * 0.9, height * 0.5);
    path.quadraticBezierTo(width * 0.5, height * 0.7, width * 0.1, height * 0.9);
  }

  void _drawGenericDigit(Path path, String digit, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.2 + offsetX, height * 0.5 + offsetY);
    path.lineTo(width * 0.8, height * 0.5);
  }

  void _drawEnhancedPunctuation(Path path, String punctuation, HandwritingStyle style, Random random) {
    final width = style.characterWidth * 0.3;
    final height = style.characterHeight;
    
    switch (punctuation) {
      case '.':
        _drawPeriod(path, width, height, style, random);
        break;
      case ',':
        _drawComma(path, width, height, style, random);
        break;
      case '!':
        _drawExclamation(path, width, height, style, random);
        break;
      case '?':
        _drawQuestionMark(path, width, height, style, random);
        break;
    }
  }

  void _drawPeriod(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.addOval(Rect.fromLTWH(
      width * 0.35 + offsetX, 
      height * 0.8 + offsetY, 
      width * 0.3, 
      width * 0.3
    ));
  }

  void _drawComma(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.4 + offsetX, height * 0.8 + offsetY);
    path.quadraticBezierTo(width * 0.2, height * 0.9, width * 0.3, height * 1.0);
  }

  void _drawExclamation(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.4 + offsetX, height * 0.1 + offsetY);
    path.lineTo(width * 0.4, height * 0.7);
    path.addOval(Rect.fromLTWH(width * 0.3, height * 0.8, width * 0.2, width * 0.2));
  }

  void _drawQuestionMark(Path path, double width, double height, HandwritingStyle style, Random random) {
    final offsetX = (random.nextDouble() - 0.5) * width * 0.1;
    final offsetY = (random.nextDouble() - 0.5) * height * 0.1;
    
    path.moveTo(width * 0.6 + offsetX, height * 0.4 + offsetY);
    path.quadraticBezierTo(width * 0.3, height * 0.1, width * 0.1, height * 0.4);
    path.quadraticBezierTo(width * 0.1, height * 0.6, width * 0.4, height * 0.6);
    path.lineTo(width * 0.4, height * 0.7);
    path.lineTo(width * 0.4, height * 0.8);
    path.addOval(Rect.fromLTWH(width * 0.3, height * 0.85, width * 0.2, width * 0.2));
  }

  Path _addRealisticJitterToPath(Path originalPath, double jitterAmount) {
    if (jitterAmount == 0) return originalPath;
    
    final jitteredPath = Path();
    final random = Random();
    
    // Convert path to points and add realistic jitter
    final metrics = originalPath.computeMetrics();
    for (final metric in metrics) {
      final length = metric.length;
      const step = 1.5; // Smaller steps for smoother jitter
      
      for (double distance = 0; distance <= length; distance += step) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          // More realistic jitter based on writing speed
          final speed = 1.0; // Could be calculated based on distance
          final jitterX = (random.nextGaussian() * jitterAmount * speed) * 0.5;
          final jitterY = (random.nextGaussian() * jitterAmount * speed) * 0.5;
          
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
    _generatedImageBytes = null;
    notifyListeners();
  }

  void reset() {
    _sampleImagePath = null;
    _generatedImagePath = null;
    _generatedImageBytes = null;
    _extractedStyle = null;
    _isProcessing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _styleTransferModel?.close();
    _characterGenerationModel?.close();
    _textRecognizer?.close();
    super.dispose();
  }
}