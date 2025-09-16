import 'package:flutter/material.dart';

class HandwritingStyle {
  final double strokeWidth;
  final Color inkColor;
  final double slant; // Angle of writing
  final double characterHeight;
  final double characterWidth;
  final double spaceWidth;
  final double lineSpacing;
  final double baselineVariation; // How much characters vary from baseline
  final double jitter; // Hand shake simulation
  final double pressure; // Pen pressure variation
  final double widthVariation; // Character width variation
  final Map<String, List<Offset>> characterTemplates; // Character stroke data

  HandwritingStyle({
    this.strokeWidth = 2.0,
    this.inkColor = Colors.black,
    this.slant = 0.0,
    this.characterHeight = 30.0,
    this.characterWidth = 20.0,
    this.spaceWidth = 10.0,
    this.lineSpacing = 40.0,
    this.baselineVariation = 2.0,
    this.jitter = 0.5,
    this.pressure = 0.8,
    this.widthVariation = 0.1,
    this.characterTemplates = const {},
  });

  // Create a copy with modifications
  HandwritingStyle copyWith({
    double? strokeWidth,
    Color? inkColor,
    double? slant,
    double? characterHeight,
    double? characterWidth,
    double? spaceWidth,
    double? lineSpacing,
    double? baselineVariation,
    double? jitter,
    double? pressure,
    double? widthVariation,
    Map<String, List<Offset>>? characterTemplates,
  }) {
    return HandwritingStyle(
      strokeWidth: strokeWidth ?? this.strokeWidth,
      inkColor: inkColor ?? this.inkColor,
      slant: slant ?? this.slant,
      characterHeight: characterHeight ?? this.characterHeight,
      characterWidth: characterWidth ?? this.characterWidth,
      spaceWidth: spaceWidth ?? this.spaceWidth,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      baselineVariation: baselineVariation ?? this.baselineVariation,
      jitter: jitter ?? this.jitter,
      pressure: pressure ?? this.pressure,
      widthVariation: widthVariation ?? this.widthVariation,
      characterTemplates: characterTemplates ?? this.characterTemplates,
    );
  }

  // Convert to/from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'strokeWidth': strokeWidth,
      'inkColor': inkColor.value,
      'slant': slant,
      'characterHeight': characterHeight,
      'characterWidth': characterWidth,
      'spaceWidth': spaceWidth,
      'lineSpacing': lineSpacing,
      'baselineVariation': baselineVariation,
      'jitter': jitter,
      'pressure': pressure,
      'widthVariation': widthVariation,
    };
  }

  factory HandwritingStyle.fromJson(Map<String, dynamic> json) {
    return HandwritingStyle(
      strokeWidth: json['strokeWidth'] ?? 2.0,
      inkColor: Color(json['inkColor'] ?? Colors.black.value),
      slant: json['slant'] ?? 0.0,
      characterHeight: json['characterHeight'] ?? 30.0,
      characterWidth: json['characterWidth'] ?? 20.0,
      spaceWidth: json['spaceWidth'] ?? 10.0,
      lineSpacing: json['lineSpacing'] ?? 40.0,
      baselineVariation: json['baselineVariation'] ?? 2.0,
      jitter: json['jitter'] ?? 0.5,
      pressure: json['pressure'] ?? 0.8,
      widthVariation: json['widthVariation'] ?? 0.1,
    );
  }
}