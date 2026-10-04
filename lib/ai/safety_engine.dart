import 'package:navilens_local/ai/models.dart';

class SafetyEngine {
  static const String _disclaimer =
      'Information extracted from the package. Always follow your prescription '
      'and healthcare professional\'s instructions. Do not use this as medical advice.';

  static const List<String> _prescriptivePatterns = [
    'you should take',
    'i recommend',
    'take one',
    'take two',
    'take three',
    'stop taking',
    'increase your dose',
    'decrease your dose',
    'start taking',
    'do not take',
  ];

  /// Validates and sanitises a raw [MedicineInfo] extraction.
  ///
  /// Returns [null] only for extremely low-confidence results that would
  /// mislead the user. Otherwise always returns a sanitised result with
  /// at least one warning/disclaimer injected.
  static MedicineInfo? validateMedicineExtraction(MedicineInfo rawInfo) {
    // Reject extremely low-confidence results
    if (rawInfo.confidence < 0.3) return null;

    final name = rawInfo.name;
    final isNameValid =
        name != null && name.trim().length > 2 && !RegExp(r'^[0-9]+$').hasMatch(name.trim());

    final cleanedInstruction = _stripPrescriptiveLanguage(rawInfo.dosageInstruction);

    return MedicineInfo(
      name: isNameValid ? name : 'Unknown Medicine',
      strength: rawInfo.strength,
      dosageInstruction: cleanedInstruction,
      expiryDate: rawInfo.expiryDate,
      warnings: [...rawInfo.warnings, _disclaimer],
      confidence: rawInfo.confidence,
    );
  }

  static String _stripPrescriptiveLanguage(String? rawInstruction) {
    if (rawInstruction == null || rawInstruction.trim().isEmpty) {
      return 'Take as directed on the label.';
    }

    final lower = rawInstruction.toLowerCase();
    for (final pattern in _prescriptivePatterns) {
      if (lower.contains(pattern)) {
        // Wrap in a label-attribution phrase rather than presenting as advice
        return 'Label reads: ${rawInstruction.trim()}';
      }
    }

    return rawInstruction.trim();
  }

  static String generateSafetyDisclaimer() => _disclaimer;
}
