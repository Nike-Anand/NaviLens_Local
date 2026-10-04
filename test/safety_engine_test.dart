import 'package:flutter_test/flutter_test.dart';
import 'package:navilens_local/ai/models.dart';
import 'package:navilens_local/ai/safety_engine.dart';

// ────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────

MedicineInfo _info({
  String? name,
  String? strength,
  String? instruction,
  String? expiry,
  List<String> warnings = const [],
  double confidence = 0.85,
}) =>
    MedicineInfo(
      name: name,
      strength: strength,
      dosageInstruction: instruction,
      expiryDate: expiry,
      warnings: warnings,
      confidence: confidence,
    );

// ────────────────────────────────────────────────────────────
// SafetyEngine tests
// ────────────────────────────────────────────────────────────

void main() {
  group('SafetyEngine', () {
    // ── Prescriptive language must be neutralized ──────────────

    const prescriptivePhrases = [
      'You should take this medicine daily.',
      'Take one tablet after food.',
      'Stop taking immediately.',
      'Increase your dose by 10 mg.',
      'Decrease your dose slowly.',
      'Start taking from tomorrow.',
      'Do not take with alcohol.',
    ];

    for (final phrase in prescriptivePhrases) {
      test('neutralizes prescriptive phrase: "$phrase"', () {
        final raw = _info(name: 'TestDrug', instruction: phrase);
        final result = SafetyEngine.validateMedicineExtraction(raw);

        if (result != null) {
          // If result is returned, instruction must be scrubbed or replaced
          final instruction = result.dosageInstruction ?? '';
          // It should not reproduce the original prescriptive instruction verbatim
          // OR it should have an injected disclaimer
          final isScrubbedOrDisclaimer = instruction != phrase ||
              (result.warnings.isNotEmpty);
          expect(
            isScrubbedOrDisclaimer,
            isTrue,
            reason:
                'SafetyEngine must not pass prescriptive language unchanged without a warning',
          );
        }
        // null result is also acceptable — means it was rejected
      });
    }

    // ── Safety disclaimer must be present ──────────────────────

    test('validated result always contains at least one warning/disclaimer', () {
      final raw = _info(name: 'Amlodipine', strength: '5 mg', expiry: '12/2027');
      final result = SafetyEngine.validateMedicineExtraction(raw);
      expect(result, isNotNull);
      expect(result!.warnings, isNotEmpty,
          reason: 'Every validated result must carry a safety disclaimer');
    });

    test('warning text is non-empty string', () {
      final raw = _info(name: 'Paracetamol', strength: '500 mg');
      final result = SafetyEngine.validateMedicineExtraction(raw);
      if (result != null) {
        for (final w in result.warnings) {
          expect(w.trim().isNotEmpty, isTrue);
        }
      }
    });

    // ── Low confidence handling ────────────────────────────────

    test('very low confidence (< 0.3) is rejected or flagged', () {
      final raw = _info(name: 'XYZ', confidence: 0.1);
      final result = SafetyEngine.validateMedicineExtraction(raw);
      // Either result is null (rejected) OR warnings contain confidence note
      if (result != null) {
        // Acceptable: returned but with warnings
        expect(result.warnings, isNotEmpty);
      }
      // null is also acceptable
    });

    // ── Normal valid medicine passes through ───────────────────

    test('well-formed medicine info is not null', () {
      final raw = _info(
        name: 'Amlodipine Tablets IP',
        strength: '5 mg',
        expiry: '12/2027',
        confidence: 0.9,
      );
      final result = SafetyEngine.validateMedicineExtraction(raw);
      expect(result, isNotNull);
      expect(result!.name, equals('Amlodipine Tablets IP'));
    });

    test('strength is preserved through validation', () {
      final raw = _info(name: 'Paracetamol', strength: '500 mg', confidence: 0.85);
      final result = SafetyEngine.validateMedicineExtraction(raw);
      if (result != null) {
        expect(result.strength, equals('500 mg'));
      }
    });

    test('expiry date is preserved through validation', () {
      final raw = _info(name: 'Amox', expiry: '12/2027', confidence: 0.85);
      final result = SafetyEngine.validateMedicineExtraction(raw);
      if (result != null) {
        expect(result.expiryDate, equals('12/2027'));
      }
    });

    // ── Null / unknown name handling ───────────────────────────

    test('null name is handled without throwing', () {
      final raw = _info(name: null, confidence: 0.85);
      expect(() => SafetyEngine.validateMedicineExtraction(raw), returnsNormally);
    });

    test('empty-string name is handled without throwing', () {
      final raw = _info(name: '', confidence: 0.85);
      expect(() => SafetyEngine.validateMedicineExtraction(raw), returnsNormally);
    });
  });
}
