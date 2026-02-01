import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'sim_telemetry.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE setups (
            id TEXT PRIMARY KEY,
            car_id TEXT,
            track_id TEXT,
            name TEXT,
            created_at INTEGER,
            parameters TEXT
          )
        ''');
      },
    );

    return _db!;
  }
}
