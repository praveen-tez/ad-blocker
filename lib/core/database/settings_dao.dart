import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

/// DAO for user settings and preferences in SQLite.
class SettingsDao {
  final AppDatabase _dbManager;

  SettingsDao(this._dbManager);

  Future<Database> get _db => _dbManager.database;

  Future<String?> getString(String key) async {
    final db = await _db;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first['value'] as String;
    }
    return null;
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final val = await getString(key);
    if (val == null) return defaultValue;
    return val.toLowerCase() == 'true';
  }

  Future<void> setString(String key, String value) async {
    final db = await _db;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setBool(String key, bool value) async {
    await setString(key, value.toString());
  }
}

