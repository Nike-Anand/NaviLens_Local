import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:navilens_local/ai/models.dart';
import 'package:navilens_local/data/history_db.dart';

void main() {
  setUpAll(() {
    // Use the FFI (in-memory) SQLite for unit tests on Windows/Linux/macOS
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('HistoryDB', () {
    test('database initializes without throwing', () async {
      expect(() async => await HistoryDB.instance.database, returnsNormally);
    });

    test('insert and retrieve exercise session', () async {
      await HistoryDB.instance.logExerciseSession('Squat', 10, 120);
      final db = await HistoryDB.instance.database;
      final rows = await db.query(
        'exercise_sessions',
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      expect(rows, isNotEmpty);
      expect(rows.first['exerciseName'], equals('Squat'));
      expect(rows.first['repetitions'], equals(10));
      expect(rows.first['durationSeconds'], equals(120));
    });

    test('insert and retrieve medicine scan', () async {
      final info = MedicineInfo(
        name: 'Paracetamol',
        strength: '500 mg',
        expiryDate: '12/2027',
        confidence: 0.85,
      );
      await HistoryDB.instance.logMedicineScan(info);
      final db = await HistoryDB.instance.database;
      final rows = await db.query(
        'medicine_scans',
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      expect(rows, isNotEmpty);
      expect(rows.first['name'], equals('Paracetamol'));
      expect(rows.first['strength'], equals('500 mg'));
      expect(rows.first['expiry'], equals('12/2027'));
    });

    test('delete all medicine scans', () async {
      // Insert two records
      final info1 = MedicineInfo(name: 'DrugA', confidence: 0.8);
      final info2 = MedicineInfo(name: 'DrugB', confidence: 0.9);
      await HistoryDB.instance.logMedicineScan(info1);
      await HistoryDB.instance.logMedicineScan(info2);

      final db = await HistoryDB.instance.database;
      await db.delete('medicine_scans');

      final rows = await db.query('medicine_scans');
      expect(rows, isEmpty);
    });

    test('delete all exercise sessions', () async {
      await HistoryDB.instance.logExerciseSession('Knee Raise', 5, 60);

      final db = await HistoryDB.instance.database;
      await db.delete('exercise_sessions');

      final rows = await db.query('exercise_sessions');
      expect(rows, isEmpty);
    });

    test('medicine scan timestamp is ISO 8601', () async {
      final info = MedicineInfo(name: 'Amoxicillin', confidence: 0.85);
      await HistoryDB.instance.logMedicineScan(info);
      final db = await HistoryDB.instance.database;
      final rows = await db.query(
        'medicine_scans',
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      final ts = rows.first['timestamp'] as String;
      expect(() => DateTime.parse(ts), returnsNormally);
    });

    test('exercise session timestamp is ISO 8601', () async {
      await HistoryDB.instance.logExerciseSession('Arm Raise', 8, 90);
      final db = await HistoryDB.instance.database;
      final rows = await db.query(
        'exercise_sessions',
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      final ts = rows.first['timestamp'] as String;
      expect(() => DateTime.parse(ts), returnsNormally);
    });
  });
}
