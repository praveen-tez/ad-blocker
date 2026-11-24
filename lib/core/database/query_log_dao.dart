import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../../models/dns_log_entry.dart';

/// DAO for DNS evaluation logs in SQLite.
class QueryLogDao {
  final AppDatabase _dbManager;

  QueryLogDao(this._dbManager);

  Future<Database> get _db => _dbManager.database;

  Future<void> insertLog(DnsLogEntry entry) async {
    final db = await _db;
    await db.insert('dns_query_logs', {
      'domain': entry.domain,
      'is_blocked': entry.isBlocked ? 1 : 0,
      'matched_rule': entry.matchedRule,
      'timestamp': entry.timestamp.millisecondsSinceEpoch,
      'latency_ms': entry.latencyMs,
    });
  }

  Future<List<DnsLogEntry>> getRecentLogs({int limit = 50}) async {
    final db = await _db;
    final rows = await db.query(
      'dns_query_logs',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return rows.map((row) {
      return DnsLogEntry(
        domain: row['domain'] as String,
        isBlocked: (row['is_blocked'] as int) == 1,
        matchedRule: row['matched_rule'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
        latencyMs: row['latency_ms'] as int,
      );
    }).toList();
  }

  Future<int> getBlockedCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM dns_query_logs WHERE is_blocked = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM dns_query_logs',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearLogs() async {
    final db = await _db;
    await db.delete('dns_query_logs');
  }
}
