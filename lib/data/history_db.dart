import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:navilens_local/ai/models.dart';

class HistoryDB {
  static final HistoryDB instance = HistoryDB._init();
  static Database? _database;

  HistoryDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE medicine_scans (
  id $idType,
  name $textType,
  strength TEXT,
  expiry TEXT,
  timestamp $textType,
  confidence $realType
)
''');

    await db.execute('''
CREATE TABLE exercise_sessions (
  id $idType,
  exerciseName $textType,
  repetitions $integerType,
  timestamp $textType,
  durationSeconds $integerType
)
''');
  }

  Future<void> logMedicineScan(MedicineInfo info) async {
    final db = await instance.database;
    await db.insert('medicine_scans', {
      'name': info.name ?? 'Unknown',
      'strength': info.strength,
      'expiry': info.expiryDate,
      'timestamp': DateTime.now().toIso8601String(),
      'confidence': info.confidence,
    });
  }

  Future<void> logExerciseSession(String name, int reps, int durationSeconds) async {
    final db = await instance.database;
    await db.insert('exercise_sessions', {
      'exerciseName': name,
      'repetitions': reps,
      'timestamp': DateTime.now().toIso8601String(),
      'durationSeconds': durationSeconds,
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
