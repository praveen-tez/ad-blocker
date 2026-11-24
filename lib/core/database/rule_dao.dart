import 'package:sqflite/sqflite.dart';
import 'package:material_ui/material_ui.dart';
import 'app_database.dart';
import '../../models/filter_rule.dart';
import '../../models/filter_category.dart';

/// DAO for filter rules and categories in SQLite.
class RuleDao {
  final AppDatabase _dbManager;

  RuleDao(this._dbManager);

  Future<Database> get _db => _dbManager.database;

  // MARK: - Rule Queries

  /// Retrieves all custom rules (user-defined), optionally filtered by search text and type.
  Future<List<FilterRule>> getRules({
    String? search,
    RuleType? typeFilter,
    bool customOnly = true,
  }) async {
    final db = await _db;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (customOnly) {
      whereClauses.add('category_id IS NULL');
    }

    if (typeFilter != null) {
      whereClauses.add('type = ?');
      whereArgs.add(typeFilter == RuleType.allow ? 'allow' : 'block');
    }

    if (search != null && search.trim().isNotEmpty) {
      whereClauses.add('(domain LIKE ? OR note LIKE ?)');
      final term = '%${search.trim().toLowerCase()}%';
      whereArgs.add(term);
      whereArgs.add(term);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final rows = await db.query(
      'filter_rules',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'added_at DESC',
    );

    return rows.map(_mapRowToRule).toList();
  }

  /// Returns map of domain -> FilterRule for all active allowlist rules.
  Future<Map<String, FilterRule>> getActiveAllowlist() async {
    final db = await _db;
    final rows = await db.query(
      'filter_rules',
      where: 'type = ? AND is_enabled = 1',
      whereArgs: ['allow'],
    );

    final map = <String, FilterRule>{};
    for (final row in rows) {
      final rule = _mapRowToRule(row);
      map[rule.domain] = rule;
    }
    return map;
  }

  /// Returns map of domain -> FilterRule for all active blocklist rules (custom & enabled categories).
  Future<Map<String, FilterRule>> getActiveBlocklist() async {
    final db = await _db;
    // Join with categories to only include rules whose category is enabled
    final rows = await db.rawQuery('''
      SELECT r.* FROM filter_rules r
      LEFT JOIN categories c ON r.category_id = c.id
      WHERE r.type = 'block'
        AND r.is_enabled = 1
        AND (r.category_id IS NULL OR c.is_enabled = 1)
    ''');

    final map = <String, FilterRule>{};
    for (final row in rows) {
      final rule = _mapRowToRule(row);
      map[rule.domain] = rule;
    }
    return map;
  }

  // MARK: - Rule Mutations

  Future<bool> insertRule(FilterRule rule) async {
    final db = await _db;

    // Check duplicate
    final existing = await db.query(
      'filter_rules',
      where: 'domain = ? AND type = ?',
      whereArgs: [rule.domain, rule.isAllow ? 'allow' : 'block'],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return false;
    }

    await db.insert('filter_rules', {
      'id': rule.id,
      'domain': rule.domain,
      'type': rule.isAllow ? 'allow' : 'block',
      'is_wildcard': rule.isWildcard ? 1 : 0,
      'is_enabled': rule.isEnabled ? 1 : 0,
      'category_id': rule.categoryId,
      'added_at': rule.addedAt.millisecondsSinceEpoch,
      'note': rule.note,
    });
    return true;
  }

  Future<void> updateRule(FilterRule rule) async {
    final db = await _db;
    await db.update(
      'filter_rules',
      {
        'domain': rule.domain,
        'type': rule.isAllow ? 'allow' : 'block',
        'is_wildcard': rule.isWildcard ? 1 : 0,
        'is_enabled': rule.isEnabled ? 1 : 0,
        'category_id': rule.categoryId,
        'note': rule.note,
      },
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<void> toggleRule(String ruleId, bool isEnabled) async {
    final db = await _db;
    await db.update(
      'filter_rules',
      {'is_enabled': isEnabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [ruleId],
    );
  }

  Future<void> deleteRule(String ruleId) async {
    final db = await _db;
    await db.delete(
      'filter_rules',
      where: 'id = ?',
      whereArgs: [ruleId],
    );
  }

  // MARK: - Categories

  Future<List<FilterCategory>> getCategories() async {
    final db = await _db;
    final rows = await db.query('categories');

    // Also get live rule counts per category
    final countRows = await db.rawQuery('''
      SELECT category_id, COUNT(*) as cnt FROM filter_rules
      WHERE category_id IS NOT NULL
      GROUP BY category_id
    ''');
    final countMap = {
      for (var r in countRows) r['category_id'] as String: r['cnt'] as int,
    };

    return rows.map((row) {
      final id = row['id'] as String;
      final count = countMap[id] ?? (row['rule_count'] as int);
      return FilterCategory(
        id: id,
        name: row['name'] as String,
        description: row['description'] as String,
        ruleCount: count,
        isEnabled: (row['is_enabled'] as int) == 1,
        icon: _mapIconName(row['icon_name'] as String),
      );
    }).toList();
  }

  Future<void> updateCategoryEnabled(String categoryId, bool isEnabled) async {
    final db = await _db;
    await db.update(
      'categories',
      {'is_enabled': isEnabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  // MARK: - Rule Statistics

  Future<int> getTotalActiveRulesCount() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM filter_rules r
      LEFT JOIN categories c ON r.category_id = c.id
      WHERE r.is_enabled = 1
        AND r.type = 'block'
        AND (r.category_id IS NULL OR c.is_enabled = 1)
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getRuleSummaryCounts() async {
    final db = await _db;
    final totalAllow = await db.rawQuery(
      "SELECT COUNT(*) as count FROM filter_rules WHERE type = 'allow' AND is_enabled = 1 AND category_id IS NULL",
    );
    final totalCustomBlock = await db.rawQuery(
      "SELECT COUNT(*) as count FROM filter_rules WHERE type = 'block' AND is_enabled = 1 AND category_id IS NULL",
    );

    return {
      'allow': Sqflite.firstIntValue(totalAllow) ?? 0,
      'customBlock': Sqflite.firstIntValue(totalCustomBlock) ?? 0,
    };
  }

  // MARK: - Helpers

  FilterRule _mapRowToRule(Map<String, dynamic> row) {
    return FilterRule(
      id: row['id'] as String,
      domain: row['domain'] as String,
      type: row['type'] == 'allow' ? RuleType.allow : RuleType.block,
      isWildcard: (row['is_wildcard'] as int) == 1,
      isEnabled: (row['is_enabled'] as int) == 1,
      categoryId: row['category_id'] as String?,
      addedAt: DateTime.fromMillisecondsSinceEpoch(row['added_at'] as int),
      note: (row['note'] as String?) ?? '',
    );
  }

  IconData _mapIconName(String iconName) {
    switch (iconName) {
      case 'campaign_outlined':
        return Icons.campaign_outlined;
      case 'fingerprint':
        return Icons.fingerprint;
      case 'security_outlined':
        return Icons.security_outlined;
      case 'memory':
        return Icons.memory;
      case 'family_restroom':
        return Icons.family_restroom;
      default:
        return Icons.shield_outlined;
    }
  }
}

