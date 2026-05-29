import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/event_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }

    _db = await _openDatabase();
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDir.path, 'ingv_db.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS events (
            event_id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_datetime TEXT NOT NULL,
            end_datetime TEXT NOT NULL,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            title TEXT,
            tag TEXT,
            description TEXT,
            category TEXT,
            author TEXT
          )
        ''');
      },
    );
  }

  Future<List<EventModel>> getAllEvents() async {
    final db = await database;
    final rows = await db.query('events', orderBy: 'start_datetime DESC');

    return rows.map(EventModel.fromMap).toList();
  }

  Future<int> insertEvent(EventModel event) async {
    final db = await database;

    return db.insert(
      'events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    if (_db == null) {
      return;
    }

    await _db!.close();
    _db = null;
  }
}