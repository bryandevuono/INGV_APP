import 'package:sembast/sembast.dart';

import 'app_database_factory_io.dart'
    if (dart.library.html) 'app_database_factory_web.dart'
    as database_factory;

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Future<Database>? _databaseFuture;

  Future<Database> get database {
    return _databaseFuture ??= database_factory.openAppDatabase();
  }

  Future<void> clearAllData() async {
    if (_databaseFuture != null) {
      final db = await _databaseFuture!;

      // 1. Close the active connection
      await db.dropAll();
    }
  }
}
