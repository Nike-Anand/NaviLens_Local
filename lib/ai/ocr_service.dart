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

  /// Parses raw OCR text from a medicine label.
  ///
  /// Returns `null` when the text contains no recognisable medicine data
  /// (blank scan, pure noise, or all-numeric garbage).
  static MedicineInfo? parseText(String rawText) {
    if (rawText.trim().isEmpty) return null;

    String? name;
    String? strength;
    String? expiryDate;

    // Trim each line and discard completely blank ones.
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return null;

    // Regex for dosage strength (e.g. 500mg, 500 mg, 5 ml, 1.5g, 50mcg).
    final strengthRegex = RegExp(
        r'\b(\d+(?:\.\d+)?)\s*(mg|ml|g|mcg|iu)\b',
        caseSensitive: false);

    // Regex for expiry date (e.g. EXP 12/27, EXP: 12/2027, Use by 06/2025).
    final expiryRegex = RegExp(
        r'(?:exp(?:iry)?|use\s*by|best\s*before)[:\s]*(\d{1,2}[/\-]\d{2,4})',
        caseSensitive: false);

    // Lines that look like pure noise: all-digit, single chars, or
    // contain only punctuation/symbols.
    final noiseRegex = RegExp(r'^[\d\s\-_/\\|.,:;!@#$%^&*()]+$');

    // Candidate lines for the medicine name (not a strength or expiry line,
    // not noise, and contains at least one letter).
    final nameCandidates = <String>[];

    for (final line in lines) {
      // Extract strength.
      if (strength == null) {
        final m = strengthRegex.firstMatch(line);
        if (m != null) {
          strength = '${m.group(1)} ${m.group(2)!.toLowerCase()}';
        }
      }

      // Extract expiry date.
      if (expiryDate == null) {
        final m = expiryRegex.firstMatch(line);
        if (m != null) {
          expiryDate = m.group(1);
        }
      }

      // Collect name candidates: must be >3 chars, contain a letter,
      // and not look like noise.
      if (line.length > 3 &&
          RegExp(r'[a-zA-Z]').hasMatch(line) &&
          !noiseRegex.hasMatch(line) &&
          !strengthRegex.hasMatch(line) &&
          !expiryRegex.hasMatch(line)) {
        nameCandidates.add(line);
      }
    }

    // Pick the longest candidate — medicine names tend to be the most
    // prominent (largest) text on the label, which ML Kit usually returns
    // first and is often the longest alpha line.
    if (nameCandidates.isNotEmpty) {
      name = nameCandidates.reduce(
          (a, b) => a.length >= b.length ? a : b);
    }

    // Nothing useful was extracted at all.
    if (name == null && strength == null && expiryDate == null) return null;

    // Compute a simple confidence score based on how many fields were found.
    final fieldsFound =
        (name != null ? 1 : 0) + (strength != null ? 1 : 0) + (expiryDate != null ? 1 : 0);
    final confidence = 0.60 + (fieldsFound - 1) * 0.15; // 0.60 / 0.75 / 0.90

    return MedicineInfo(
      name: name ?? 'Unknown Medicine',
      strength: strength,
      expiryDate: expiryDate,
      confidence: confidence.clamp(0.60, 0.95),
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
