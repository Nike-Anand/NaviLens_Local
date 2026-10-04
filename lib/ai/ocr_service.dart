import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'models.dart';
import 'safety_engine.dart';

class OcrService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<MedicineInfo?> analyzeImage(InputImage inputImage) async {
    try {
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);
      final rawInfo = parseText(recognizedText.text);
      if (rawInfo == null) return null;
      return SafetyEngine.validateMedicineExtraction(rawInfo);
    } catch (e) {
      debugPrint('OCR Error: $e');
      return null;
    }
  }

  static MedicineInfo? parseText(String rawText) {
    if (rawText.trim().isEmpty) return null;

    String? name;
    String? strength;
    String? expiryDate;

    final lines = rawText.split('\n').map((line) => line.trim()).toList();

    // Regex for dosage (e.g. 500mg, 500 mg, 5ml)
    final strengthRegex =
        RegExp(r'\b(\d+(?:\.\d+)?)\s*(mg|ml|g|mcg|iu)\b', caseSensitive: false);
    // Regex for expiry (e.g. EXP 12/27, EXP: 12/2027, Expiry: 12/2027)
    final expiryRegex = RegExp(
        r'(?:exp(?:iry)?|use\s*by)[\s:]*(\d{1,2}[/\-]\d{2,4})',
        caseSensitive: false);

    for (String line in lines) {
      if (strength == null) {
        final match = strengthRegex.firstMatch(line);
        if (match != null) {
          strength = '${match.group(1)} ${match.group(2)!.toLowerCase()}';
        }
      }

      if (expiryDate == null) {
        final match = expiryRegex.firstMatch(line);
        if (match != null) {
          expiryDate = match.group(1);
        }
      }

      if (name == null &&
          line.length > 3 &&
          !strengthRegex.hasMatch(line) &&
          !expiryRegex.hasMatch(line)) {
        name = line;
      }
    }

    if (name == null && strength == null && expiryDate == null) return null;

    return MedicineInfo(
      name: name ?? 'Unknown Medicine',
      strength: strength,
      expiryDate: expiryDate,
      confidence: 0.85,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
