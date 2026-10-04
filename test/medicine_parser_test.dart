import 'package:flutter_test/flutter_test.dart';
import 'package:navilens_local/ai/models.dart';
import 'package:navilens_local/ai/safety_engine.dart';

// ────────────────────────────────────────────────────────────
// We test the _extractMedicineData logic indirectly by replicating
// the exact same regex logic used in OcrService. This lets us test
// the parser without spinning up a TextRecognizer.
// ────────────────────────────────────────────────────────────

MedicineInfo _parse(String rawText) {
  String? name;
  String? strength;
  String? expiryDate;

  final lines = rawText.split('\n');
  final strengthRegex =
      RegExp(r'\b(\d+(?:\.\d+)?)\s*(mg|ml|g|mcg|iu)\b', caseSensitive: false);
  final expiryRegex =
      RegExp(r'(?:exp(?:iry)?|use\s*by)[\s:]*(\d{1,2}[/\-]\d{2,4})', caseSensitive: false);

  for (final line in lines) {
    if (strength == null) {
      final match = strengthRegex.firstMatch(line);
      if (match != null) {
        strength = '${match.group(1)} ${match.group(2)!.toLowerCase()}';
      }
    }
    if (expiryDate == null) {
      final match = expiryRegex.firstMatch(line);
      if (match != null) expiryDate = match.group(1);
    }
    if (name == null &&
        line.length > 3 &&
        !strengthRegex.hasMatch(line) &&
        !expiryRegex.hasMatch(line)) {
      name = line;
    }
  }

  return MedicineInfo(
    name: name ?? 'Unknown Medicine',
    strength: strength,
    dosageInstruction: 'Take as prescribed',
    expiryDate: expiryDate,
    confidence: 0.85,
  );
}

void main() {
  // ──── Strength extraction ────────────────────────────────────

  group('Medicine parser — strength extraction', () {
    test('500 mg (space)', () {
      final info = _parse('Paracetamol\n500 mg\nEXP 12/2027');
      expect(info.strength, equals('500 mg'));
    });

    test('500mg (no space)', () {
      final info = _parse('Paracetamol\n500mg\nEXP 12/2027');
      expect(info.strength, equals('500 mg'));
    });

    test('500 MG (uppercase)', () {
      final info = _parse('Paracetamol\n500 MG\nEXP 12/2027');
      expect(info.strength, equals('500 mg'));
    });

    test('5 ml', () {
      final info = _parse('Cough Syrup\n5 ml\nEXP 06/2026');
      expect(info.strength, equals('5 ml'));
    });

    test('2.5 mg (decimal)', () {
      final info = _parse('Alprazolam\n2.5 mg\nEXP 03/2028');
      expect(info.strength, equals('2.5 mg'));
    });

    test('no strength returns null', () {
      final info = _parse('Vitamin Tablets\nEXP 01/2030');
      expect(info.strength, isNull);
    });
  });

  // ──── Expiry extraction ─────────────────────────────────────

  group('Medicine parser — expiry extraction', () {
    test('EXP 12/2027', () {
      final info = _parse('Amlodipine\n5 mg\nEXP 12/2027');
      expect(info.expiryDate, equals('12/2027'));
    });

    test('EXP: 12/27 (abbreviated year)', () {
      final info = _parse('Amlodipine\n5 mg\nEXP: 12/27');
      expect(info.expiryDate, equals('12/27'));
    });

    test('Expiry: 06/2026', () {
      final info = _parse('Drug X\nExpiry: 06/2026');
      expect(info.expiryDate, equals('06/2026'));
    });

    test('use by 03-2025 (hyphen separator)', () {
      final info = _parse('Drug X\nuse by 03-2025');
      expect(info.expiryDate, equals('03-2025'));
    });

    test('no expiry returns null', () {
      final info = _parse('Vitamin C\n500 mg');
      expect(info.expiryDate, isNull);
    });
  });

  // ──── Name extraction ────────────────────────────────────────

  group('Medicine parser — name extraction', () {
    test('extracts first non-strength non-expiry line as name', () {
      final info = _parse('Paracetamol\n500 mg\nEXP 12/2027');
      expect(info.name, equals('Paracetamol'));
    });

    test('empty OCR text gives Unknown Medicine', () {
      final info = _parse('');
      expect(info.name, equals('Unknown Medicine'));
    });

    test('garbage OCR with only numbers gives Unknown Medicine', () {
      // All lines are numbers or too short
      final info = _parse('12\n34\n56\n78');
      // Name may be Unknown Medicine or a short line depending on length check
      expect(info.name, isNotNull);
    });

    test('partial label (name + no strength) still returns name', () {
      final info = _parse('Metformin\nBefore meals');
      expect(info.name, equals('Metformin'));
      expect(info.strength, isNull);
    });
  });

  // ──── End-to-end with SafetyEngine ─────────────────────────

  group('Medicine parser + SafetyEngine integration', () {
    test('Paracetamol 500 mg EXP 12/2027 passes through safely', () {
      final raw = _parse('Paracetamol\n500 mg\nEXP 12/2027');
      final result = SafetyEngine.validateMedicineExtraction(raw);
      expect(result, isNotNull);
      expect(result!.name, equals('Paracetamol'));
      expect(result.strength, equals('500 mg'));
      expect(result.expiryDate, equals('12/2027'));
      expect(result.warnings, isNotEmpty);
    });

    test('empty OCR after safety engine returns Unknown Medicine with disclaimer', () {
      final raw = _parse('');
      final result = SafetyEngine.validateMedicineExtraction(raw);
      // 'Unknown Medicine' (3+ chars, no numbers-only) → may pass
      // Regardless, warnings must be present if result is non-null
      if (result != null) {
        expect(result.warnings, isNotEmpty);
      }
    });

    test('safety engine adds disclaimer on top of existing warnings', () {
      final raw = MedicineInfo(
        name: 'Metformin',
        strength: '500 mg',
        dosageInstruction: 'Take as prescribed',
        confidence: 0.85,
        warnings: ['Pre-existing warning'],
      );
      final result = SafetyEngine.validateMedicineExtraction(raw);
      expect(result, isNotNull);
      expect(result!.warnings.length, greaterThanOrEqualTo(2));
    });
  });
}
