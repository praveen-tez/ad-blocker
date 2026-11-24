import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clearwave/core/database/app_database.dart';
import 'package:clearwave/core/database/rule_dao.dart';
import 'package:clearwave/core/database/settings_dao.dart';
import 'package:clearwave/core/database/query_log_dao.dart';
import 'package:clearwave/models/filter_rule.dart';
import 'package:clearwave/models/dns_log_entry.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase dbManager;
  late RuleDao ruleDao;
  late SettingsDao settingsDao;
  late QueryLogDao queryLogDao;

  setUp(() async {
    final inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    dbManager = AppDatabase(db: inMemoryDb);
    // Initialize schema and seed data
    await dbManager.database;

    ruleDao = RuleDao(dbManager);
    settingsDao = SettingsDao(dbManager);
    queryLogDao = QueryLogDao(dbManager);
  });

  tearDown(() async {
    await dbManager.close();
  });

  group('SQLite Database & DAO Tests', () {
    test('Database seeds initial categories and rules on creation', () async {
      final categories = await ruleDao.getCategories();
      expect(categories.length, greaterThanOrEqualTo(5));

      final activeAllow = await ruleDao.getActiveAllowlist();
      expect(activeAllow.containsKey('auth.mybank.com'), isTrue);
      expect(activeAllow.containsKey('apple.com'), isTrue);

      final activeBlock = await ruleDao.getActiveBlocklist();
      expect(activeBlock.containsKey('doubleclick.net'), isTrue);
      expect(activeBlock.containsKey('graph.facebook.com'), isTrue);
    });

    test('Custom rule insertion, query, and toggle in SQLite', () async {
      final rule = FilterRule(
        id: 'test_rule_1',
        domain: 'tracking.example.org',
        type: RuleType.block,
        addedAt: DateTime.now(),
        note: 'Test rule',
      );

      final inserted = await ruleDao.insertRule(rule);
      expect(inserted, isTrue);

      // Verify in custom rules query
      final rules = await ruleDao.getRules(customOnly: true);
      expect(rules.any((r) => r.domain == 'tracking.example.org'), isTrue);

      // Toggle rule
      await ruleDao.toggleRule('test_rule_1', false);
      final activeBlock = await ruleDao.getActiveBlocklist();
      expect(activeBlock.containsKey('tracking.example.org'), isFalse);

      // Delete rule
      await ruleDao.deleteRule('test_rule_1');
      final afterDelete = await ruleDao.getRules(customOnly: true);
      expect(afterDelete.any((r) => r.domain == 'tracking.example.org'), isFalse);
    });

    test('Duplicate prevention in rule insertion', () async {
      final rule = FilterRule(
        id: 'dup_1',
        domain: 'duplicate.com',
        type: RuleType.block,
        addedAt: DateTime.now(),
      );

      final first = await ruleDao.insertRule(rule);
      expect(first, isTrue);

      final second = await ruleDao.insertRule(rule);
      expect(second, isFalse);
    });

    test('Category toggle in SQLite enables/disables category rules', () async {
      // Ads category is enabled by default
      var activeBlock = await ruleDao.getActiveBlocklist();
      expect(activeBlock.containsKey('doubleclick.net'), isTrue);

      // Disable 'ads' category
      await ruleDao.updateCategoryEnabled('ads', false);

      activeBlock = await ruleDao.getActiveBlocklist();
      expect(activeBlock.containsKey('doubleclick.net'), isFalse);

      // Re-enable
      await ruleDao.updateCategoryEnabled('ads', true);
      activeBlock = await ruleDao.getActiveBlocklist();
      expect(activeBlock.containsKey('doubleclick.net'), isTrue);
    });

    test('SettingsDao persists and reads key-value configuration', () async {
      await settingsDao.setString('selected_dns', 'Cloudflare 1.1.1.1');
      expect(await settingsDao.getString('selected_dns'), 'Cloudflare 1.1.1.1');

      await settingsDao.setBool('filter_ipv6', false);
      expect(await settingsDao.getBool('filter_ipv6'), isFalse);
    });

    test('QueryLogDao records queries and prunes correctly', () async {
      final log = DnsLogEntry(
        domain: 'test.telemetry.io',
        isBlocked: true,
        matchedRule: 'Category: Trackers',
        timestamp: DateTime.now(),
        latencyMs: 1,
      );

      await queryLogDao.insertLog(log);
      final logs = await queryLogDao.getRecentLogs(limit: 10);
      expect(logs.any((l) => l.domain == 'test.telemetry.io'), isTrue);
    });
  });
}
