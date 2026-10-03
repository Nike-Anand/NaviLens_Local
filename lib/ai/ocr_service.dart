import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'models.dart';
import 'safety_engine.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<MedicineInfo?> analyzeImage(InputImage inputImage) async {
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      final rawInfo = _extractMedicineData(recognizedText.text);
      return SafetyEngine.validateMedicineExtraction(rawInfo);
    } catch (e) {
      print('OCR Error: $e');
      return null;
    }
  }

  MedicineInfo _extractMedicineData(String rawText) {
    // Basic heuristics to extract data from raw text
    final lines = rawText.split('\n');
    
    String? name;
    String? strength;
    String? expiryDate;
    
    // Very basic extraction logic for MVP
    for (String line in lines) {
      final upper = line.toUpperCase();
      if (upper.contains('MG') || upper.contains('ML')) {
        strength = line;
      }
      if (upper.contains('EXP') || upper.contains('USE BY')) {
        expiryDate = line;
      }
      if (name == null && line.length > 3 && !upper.contains('MG')) {
        name = line;
      }
    }

    return MedicineInfo(
      name: name ?? 'Unknown Medicine',
      strength: strength,
      dosageInstruction: 'Take as prescribed',
      expiryDate: expiryDate,
      confidence: 0.85, // Dummy confidence for MVP
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
