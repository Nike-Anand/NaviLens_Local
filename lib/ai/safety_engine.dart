import 'package:navilens_local/ai/models.dart';

class SafetyEngine {
  static MedicineInfo validateMedicineExtraction(MedicineInfo rawInfo) {
    // Rule 1: Never invent OCR text or dosage.
    // If the medicine name is too short or just numbers, mark as unsafe/unknown.
    final name = rawInfo.name;
    final isNameValid = name != null && name.length > 2 && !RegExp(r'^[0-9]+$').hasMatch(name);

    return MedicineInfo(
      name: isNameValid ? name : 'Unknown Medicine',
      strength: rawInfo.strength,
      dosageInstruction: _stripPrescriptiveLanguage(rawInfo.dosageInstruction),
      expiryDate: rawInfo.expiryDate,
      warnings: rawInfo.warnings,
      confidence: rawInfo.confidence,
    );
  }

  static String _stripPrescriptiveLanguage(String? rawInstruction) {
    if (rawInstruction == null || rawInstruction.isEmpty) return 'No instructions detected.';
    
    // Ensure we do not command the user to take medicine
    final lower = rawInstruction.toLowerCase();
    if (lower.contains('you should take') || lower.contains('i recommend')) {
      return 'The label says: $rawInstruction. Follow your prescription.';
    }
    
    return 'The label says: $rawInstruction';
  }

  static String generateSafetyDisclaimer() {
    return 'Information extracted from the package. Follow your prescription and healthcare professional\'s instructions. Do not use this as medical advice.';
  }
}
