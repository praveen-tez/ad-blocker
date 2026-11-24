import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// SQLite Database Manager for CLEARWAVE.
/// Persists filter rules, categories, DNS query telemetry, and user settings.
class AppDatabase {
  static const String databaseName = 'clearwave.db';
  static const int databaseVersion = 1;

  Database? _db;

  AppDatabase({Database? db}) {
    _db = db;
  }

  Future<Database> get database async {
    if (_db != null) {
      final tables = await _db!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='categories'",
      );
      if (tables.isEmpty) {
        await createTables(_db!, databaseVersion);
      }
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, databaseName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: createTables,
    );
  }

  static Future<void> createTables(Database db, int version) async {
    // 1. Filter Rules Table (Both custom and default rules)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS filter_rules (
        id TEXT PRIMARY KEY,
        domain TEXT NOT NULL,
        type TEXT NOT NULL,
        is_wildcard INTEGER NOT NULL DEFAULT 1,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        category_id TEXT,
        added_at INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_rules_domain ON filter_rules(domain)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_rules_type ON filter_rules(type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_rules_category ON filter_rules(category_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_rules_enabled ON filter_rules(is_enabled)');

    // 2. Categories Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        rule_count INTEGER NOT NULL DEFAULT 0,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        icon_name TEXT NOT NULL
      )
    ''');

    // 3. Settings Key-Value Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 4. DNS Query Logs Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dns_query_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        domain TEXT NOT NULL,
        is_blocked INTEGER NOT NULL,
        matched_rule TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        latency_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON dns_query_logs(timestamp DESC)');

    // Seed initial rules and categories
    await seedDatabase(db);
  }

  static Future<void> seedDatabase(Database db) async {
    final batch = db.batch();

    // Default Categories
    final categories = [
      {
        'id': 'ads',
        'name': 'Advertising & Banners',
        'description': 'Blocks major mobile and web banner networks',
        'rule_count': 12,
        'is_enabled': 1,
        'icon_name': 'campaign_outlined',
      },
      {
        'id': 'trackers',
        'name': 'Behavioral Trackers & Telemetry',
        'description': 'Blocks user profiling, telemetry, and session analytics',
        'rule_count': 10,
        'is_enabled': 1,
        'icon_name': 'fingerprint',
      },
      {
        'id': 'malware',
        'name': 'Malware & Phishing Shields',
        'description': 'Blocks malicious software distribution and credential harvesters',
        'rule_count': 6,
        'is_enabled': 1,
        'icon_name': 'security_outlined',
      },
      {
        'id': 'crypto',
        'name': 'Cryptojackers & Miners',
        'description': 'Blocks unauthorized in-browser crypto mining endpoints',
        'rule_count': 4,
        'is_enabled': 1,
        'icon_name': 'memory',
      },
      {
        'id': 'adult',
        'name': 'Adult & Gambling Gate',
        'description': 'Filters pornographic, illegal betting, and scam destinations',
        'rule_count': 5,
        'is_enabled': 0,
        'icon_name': 'family_restroom',
      },
    ];

    for (final cat in categories) {
      batch.insert('categories', cat, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Default Seed Rules
    final now = DateTime.now().millisecondsSinceEpoch;
    final seedRules = [
      // Advertising Category
      {'id': 'rule_ad_1', 'domain': 'doubleclick.net', 'type': 'block', 'category_id': 'ads', 'note': 'Google ad delivery network'},
      {'id': 'rule_ad_2', 'domain': 'googleadservices.com', 'type': 'block', 'category_id': 'ads', 'note': 'Google search sponsored ads'},
      {'id': 'rule_ad_3', 'domain': 'adservice.google.com', 'type': 'block', 'category_id': 'ads', 'note': 'Google ad syndication'},
      {'id': 'rule_ad_4', 'domain': 'pagead2.googlesyndication.com', 'type': 'block', 'category_id': 'ads', 'note': 'AdSense display ads'},
      {'id': 'rule_ad_5', 'domain': 'ads-twitter.com', 'type': 'block', 'category_id': 'ads', 'note': 'X/Twitter promotional ads'},
      {'id': 'rule_ad_6', 'domain': 'adnxs.com', 'type': 'block', 'category_id': 'ads', 'note': 'AppNexus display advertising'},
      {'id': 'rule_ad_7', 'domain': 'taboola.com', 'type': 'block', 'category_id': 'ads', 'note': 'Sponsored content widget'},
      {'id': 'rule_ad_8', 'domain': 'outbrain.com', 'type': 'block', 'category_id': 'ads', 'note': 'Native ad distributor'},
      {'id': 'rule_ad_9', 'domain': 'advertising.apple.com', 'type': 'block', 'category_id': 'ads', 'note': 'Apple Search Ads network'},
      {'id': 'rule_ad_10', 'domain': 'popads.net', 'type': 'block', 'category_id': 'ads', 'note': 'Pop-under ad network'},
      {'id': 'rule_ad_11', 'domain': 'inmobi.com', 'type': 'block', 'category_id': 'ads', 'note': 'In-app mobile ad SDK'},
      {'id': 'rule_ad_12', 'domain': 'unityads.unity3d.com', 'type': 'block', 'category_id': 'ads', 'note': 'Unity game advertising'},

      // Trackers & Telemetry Category
      {'id': 'rule_tr_1', 'domain': 'graph.facebook.com', 'type': 'block', 'category_id': 'trackers', 'note': 'Meta Graph SDK telemetry'},
      {'id': 'rule_tr_2', 'domain': 'pixel.facebook.com', 'type': 'block', 'category_id': 'trackers', 'note': 'Meta ad tracking pixel'},
      {'id': 'rule_tr_3', 'domain': 'google-analytics.com', 'type': 'block', 'category_id': 'trackers', 'note': 'Google universal analytics'},
      {'id': 'rule_tr_4', 'domain': 'mixpanel.com', 'type': 'block', 'category_id': 'trackers', 'note': 'Event tracking service'},
      {'id': 'rule_tr_5', 'domain': 'segment.io', 'type': 'block', 'category_id': 'trackers', 'note': 'Customer telemetry aggregator'},
      {'id': 'rule_tr_6', 'domain': 'hotjar.com', 'type': 'block', 'category_id': 'trackers', 'note': 'Session recording & heatmaps'},
      {'id': 'rule_tr_7', 'domain': 'scorecardresearch.com', 'type': 'block', 'category_id': 'trackers', 'note': 'Audience profiling beacon'},
      {'id': 'rule_tr_8', 'domain': 'adjust.com', 'type': 'block', 'category_id': 'trackers', 'note': 'Mobile app attribution tracker'},
      {'id': 'rule_tr_9', 'domain': 'appsflyer.com', 'type': 'block', 'category_id': 'trackers', 'note': 'Install & attribution telemetry'},
      {'id': 'rule_tr_10', 'domain': 'telemetry.sdk-analytics.com', 'type': 'block', 'category_id': 'trackers', 'note': 'Third-party SDK telemetry'},

      // Malware Category
      {'id': 'rule_mal_1', 'domain': 'malware-traffic-analysis.net', 'type': 'block', 'category_id': 'malware', 'note': 'Known infected test origin'},
      {'id': 'rule_mal_2', 'domain': 'phishing-credential-gate.com', 'type': 'block', 'category_id': 'malware', 'note': 'Credential harvesting domain'},
      {'id': 'rule_mal_3', 'domain': 'payload-delivery.cc', 'type': 'block', 'category_id': 'malware', 'note': 'Trojan binary dropper'},
      {'id': 'rule_mal_4', 'domain': 'fake-update-alert.info', 'type': 'block', 'category_id': 'malware', 'note': 'Scareware alert spoof'},
      {'id': 'rule_mal_5', 'domain': 'ransomware-c2-node.top', 'type': 'block', 'category_id': 'malware', 'note': 'Command and control server'},
      {'id': 'rule_mal_6', 'domain': 'account-recovery-scam.xyz', 'type': 'block', 'category_id': 'malware', 'note': 'Financial phishing domain'},

      // Cryptominers Category
      {'id': 'rule_cr_1', 'domain': 'coinhive.com', 'type': 'block', 'category_id': 'crypto', 'note': 'In-browser Monero cryptominer'},
      {'id': 'rule_cr_2', 'domain': 'cryptoloot.pro', 'type': 'block', 'category_id': 'crypto', 'note': 'Silent mining script'},
      {'id': 'rule_cr_3', 'domain': 'coin-have.com', 'type': 'block', 'category_id': 'crypto', 'note': 'Coinhive mirror domain'},
      {'id': 'rule_cr_4', 'domain': 'webminepool.com', 'type': 'block', 'category_id': 'crypto', 'note': 'Browser hash computing pool'},

      // Adult & Gambling Category
      {'id': 'rule_adlt_1', 'domain': 'betonline-casino.com', 'type': 'block', 'category_id': 'adult', 'note': 'Unregulated gambling'},
      {'id': 'rule_adlt_2', 'domain': 'onlinepoker-roulette.net', 'type': 'block', 'category_id': 'adult', 'note': 'Betting portal'},
      {'id': 'rule_adlt_3', 'domain': 'adult-content-network.xxx', 'type': 'block', 'category_id': 'adult', 'note': 'Adult material'},
      {'id': 'rule_adlt_4', 'domain': 'live-cam-strip.tv', 'type': 'block', 'category_id': 'adult', 'note': 'Adult video chat'},
      {'id': 'rule_adlt_5', 'domain': 'lottery-jackpot-scam.vip', 'type': 'block', 'category_id': 'adult', 'note': 'Gambling scam portal'},

      // Essential Seed Allowlist (Crucial services with explicit precedence over blocks)
      {'id': 'rule_al_1', 'domain': 'auth.mybank.com', 'type': 'allow', 'category_id': null, 'note': 'User banking auth portal (Precedence)'},
      {'id': 'rule_al_2', 'domain': 'apple.com', 'type': 'allow', 'category_id': null, 'note': 'Apple ID & iOS system updates'},
      {'id': 'rule_al_3', 'domain': 'icloud.com', 'type': 'allow', 'category_id': null, 'note': 'iCloud core services'},
      {'id': 'rule_al_4', 'domain': 'github.com', 'type': 'allow', 'category_id': null, 'note': 'GitHub developer platform'},
      {'id': 'rule_al_5', 'domain': 'play.google.com', 'type': 'allow', 'category_id': null, 'note': 'Google Play Store services'},
    ];

    for (final rule in seedRules) {
      batch.insert('filter_rules', {
        'id': rule['id'],
        'domain': rule['domain'],
        'type': rule['type'],
        'is_wildcard': 1,
        'is_enabled': 1,
        'category_id': rule['category_id'],
        'added_at': now,
        'note': rule['note'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Default Settings
    final defaultSettings = {
      'selected_dns': 'Quad9 (Encrypted)',
      'filter_ipv6': 'true',
      'block_lan': 'false',
      'onboarding_done': 'true',
    };

    defaultSettings.forEach((k, v) {
      batch.insert('settings', {'key': k, 'value': v}, conflictAlgorithm: ConflictAlgorithm.replace);
    });

    // Seed initial queries for activity feed
    final seedLogs = [
      {'domain': 'pagead2.googlesyndication.com', 'is_blocked': 1, 'matched_rule': 'Category: Advertising & Banners', 'timestamp': now - 15000, 'latency_ms': 1},
      {'domain': 'graph.facebook.com', 'is_blocked': 1, 'matched_rule': 'Category: Behavioral Trackers & Telemetry', 'timestamp': now - 35000, 'latency_ms': 1},
      {'domain': 'api.github.com', 'is_blocked': 0, 'matched_rule': 'Allowed: Upstream Resolver', 'timestamp': now - 58000, 'latency_ms': 12},
      {'domain': 'auth.mybank.com', 'is_blocked': 0, 'matched_rule': 'Allowed: Precedence Rule (auth.mybank.com)', 'timestamp': now - 120000, 'latency_ms': 16},
      {'domain': 'google-analytics.com', 'is_blocked': 1, 'matched_rule': 'Category: Behavioral Trackers & Telemetry', 'timestamp': now - 180000, 'latency_ms': 1},
    ];

    for (final log in seedLogs) {
      batch.insert('dns_query_logs', log);
    }

    await batch.commit(noResult: true);
  }

  Future<void> resetToDefaults() async {
    final db = await database;
    await db.delete('filter_rules');
    await db.delete('categories');
    await db.delete('settings');
    await db.delete('dns_query_logs');
    await seedDatabase(db);
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
