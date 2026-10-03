class MedicineInfo {
  final String? name;
  final String? strength;
  final String? dosageInstruction;
  final String? expiryDate;
  final List<String> warnings;
  final double confidence;

  MedicineInfo({
    this.name,
    this.strength,
    this.dosageInstruction,
    this.expiryDate,
    this.warnings = const [],
    required this.confidence,
  });

  @override
  String toString() {
    return 'MedicineInfo(name: $name, strength: $strength, dosage: $dosageInstruction, expiry: $expiryDate)';
  }
}
