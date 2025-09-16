import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ModelDownloader {
  static const String _modelBaseUrl = 'https://github.com/your-org/handwriting-models/releases/download/v1.0/';
  
  // Model file names
  static const String _styleTransferModelName = 'handwriting_style_transfer.tflite';
  static const String _characterGenerationModelName = 'character_generation.tflite';
  
  static Future<String?> downloadStyleTransferModel() async {
    try {
      final modelPath = await _getModelPath(_styleTransferModelName);
      
      // Check if model already exists
      if (await File(modelPath).exists()) {
        print('Style transfer model already exists');
        return modelPath;
      }
      
      // Download model
      print('Downloading style transfer model...');
      final response = await http.get(Uri.parse('$_modelBaseUrl$_styleTransferModelName'));
      
      if (response.statusCode == 200) {
        await File(modelPath).writeAsBytes(response.bodyBytes);
        print('Style transfer model downloaded successfully');
        return modelPath;
      } else {
        print('Failed to download style transfer model: ${response.statusCode}');
        return await _loadBuiltInStyleTransferModel();
      }
    } catch (e) {
      print('Error downloading style transfer model: $e');
      return await _loadBuiltInStyleTransferModel();
    }
  }
  
  static Future<String?> downloadCharacterGenerationModel() async {
    try {
      final modelPath = await _getModelPath(_characterGenerationModelName);
      
      // Check if model already exists
      if (await File(modelPath).exists()) {
        print('Character generation model already exists');
        return modelPath;
      }
      
      // Download model
      print('Downloading character generation model...');
      final response = await http.get(Uri.parse('$_modelBaseUrl$_characterGenerationModelName'));
      
      if (response.statusCode == 200) {
        await File(modelPath).writeAsBytes(response.bodyBytes);
        print('Character generation model downloaded successfully');
        return modelPath;
      } else {
        print('Failed to download character generation model: ${response.statusCode}');
        return await _loadBuiltInCharacterGenerationModel();
      }
    } catch (e) {
      print('Error downloading character generation model: $e');
      return await _loadBuiltInCharacterGenerationModel();
    }
  }
  
  static Future<String> _getModelPath(String modelName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    
    return '${modelsDir.path}/$modelName';
  }
  
  static Future<String?> _loadBuiltInStyleTransferModel() async {
    try {
      // Try to load a built-in model from assets
      final modelPath = await _getModelPath('builtin_style_transfer.tflite');
      
      // For now, we'll create a placeholder file
      // In a real implementation, you would bundle a pre-trained model
      await File(modelPath).writeAsBytes(Uint8List(0));
      
      print('Using built-in style transfer model (placeholder)');
      return modelPath;
    } catch (e) {
      print('Error loading built-in style transfer model: $e');
      return null;
    }
  }
  
  static Future<String?> _loadBuiltInCharacterGenerationModel() async {
    try {
      // Try to load a built-in model from assets
      final modelPath = await _getModelPath('builtin_character_generation.tflite');
      
      // For now, we'll create a placeholder file
      // In a real implementation, you would bundle a pre-trained model
      await File(modelPath).writeAsBytes(Uint8List(0));
      
      print('Using built-in character generation model (placeholder)');
      return modelPath;
    } catch (e) {
      print('Error loading built-in character generation model: $e');
      return null;
    }
  }
  
  static Future<bool> checkModelAvailability() async {
    try {
      final styleTransferPath = await _getModelPath(_styleTransferModelName);
      final characterGenerationPath = await _getModelPath(_characterGenerationModelName);
      
      final styleTransferExists = await File(styleTransferPath).exists();
      final characterGenerationExists = await File(characterGenerationPath).exists();
      
      return styleTransferExists && characterGenerationExists;
    } catch (e) {
      print('Error checking model availability: $e');
      return false;
    }
  }
  
  static Future<void> deleteModels() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${appDir.path}/models');
      
      if (await modelsDir.exists()) {
        await modelsDir.delete(recursive: true);
        print('Models deleted successfully');
      }
    } catch (e) {
      print('Error deleting models: $e');
    }
  }
  
  static Future<Map<String, String>> getModelInfo() async {
    try {
      final styleTransferPath = await _getModelPath(_styleTransferModelName);
      final characterGenerationPath = await _getModelPath(_characterGenerationModelName);
      
      final styleTransferExists = await File(styleTransferPath).exists();
      final characterGenerationExists = await File(characterGenerationPath).exists();
      
      return {
        'style_transfer': styleTransferExists ? styleTransferPath : 'Not available',
        'character_generation': characterGenerationExists ? characterGenerationPath : 'Not available',
      };
    } catch (e) {
      print('Error getting model info: $e');
      return {
        'style_transfer': 'Error',
        'character_generation': 'Error',
      };
    }
  }
}