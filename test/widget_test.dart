import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:clearwave/app.dart';
import 'package:clearwave/core/constants/app_strings.dart';
import 'package:clearwave/core/database/app_database.dart';
import 'package:clearwave/core/platform/platform_channel_interface.dart';
import 'package:clearwave/models/filter_rule.dart';
import 'package:clearwave/providers/protection_state.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase dbManager;
  late ProtectionController controller;

  setUp(() async {
    final inMemoryDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    dbManager = AppDatabase(db: inMemoryDb);
    await dbManager.database;
    controller = ProtectionController(
      engine: SimulatedProtectionEngine(),
      database: dbManager,
    );
    await controller.loadFromDatabase();
  });

  tearDown(() async {
    controller.dispose();
  });

  testWidgets('CLEARWAVE Stage 2 SQLite integrated app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(ClearwaveApp(controller: controller));
    await tester.pumpAndSettle();

    // 1. Verify Header and Product Branding
    expect(find.text(AppStrings.appName), findsOneWidget);

    // 2. Verify Domain Filter Inspector Tool (Stage 2 Feature)
    expect(find.text('DOMAIN FILTER INSPECTOR'), findsOneWidget);
    expect(find.text('Live Engine'), findsOneWidget);

    // 3. Test Live Domain Evaluation in Inspector
    final testButton = find.widgetWithText(FilledButton, 'Test');
    expect(testButton, findsOneWidget);
    await tester.tap(testButton);

    // Run async to let the SQLite FFI isolate complete the insert and lookup
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    // Evaluation of default 'ads.doubleclick.net' should be BLOCKED
    expect(find.text('EVALUATION: BLOCKED'), findsOneWidget);
    expect(find.text('Add to Allowlist (Override)'), findsOneWidget);

    // 4. Test Navigation to Rules Tab & SQLite loaded rules
    await tester.tap(find.text('Rules'));
    await tester.pumpAndSettle();
    expect(find.text('Rules & Filtering'), findsOneWidget);
    expect(find.text('Advertising & Banners'), findsOneWidget);

    // 5. Test Navigation to Custom Rules Tab
    await tester.tap(find.text('Custom Rules'));
    await tester.pumpAndSettle();
    expect(
      find.text('Precedence hierarchy: Allowlist rules strictly override all blocklist categories and custom blocks.'),
      findsOneWidget,
    );

    // 6. Test Navigation to Settings Tab with SQLite diagnostics
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('LOCAL DATABASE & STORAGE (STAGE 2)'), findsOneWidget);
    expect(find.text('SQLite (clearwave.db)'), findsOneWidget);
  });

  test('ProtectionController rules precedence and management logic via SQLite', () async {
    // Initial state loaded from seeded database
    expect(controller.rules.length, greaterThanOrEqualTo(5));

    // Add valid block rule
    final added = await controller.addCustomRule(
      domain: 'https://custom-adserver.com:443/banner',
      type: RuleType.block,
      note: 'Custom block test',
    );
    expect(added, isTrue);
    expect(controller.rules.any((r) => r.domain == 'custom-adserver.com'), isTrue);

    // Prevent duplicate
    final duplicate = await controller.addCustomRule(
      domain: 'custom-adserver.com',
      type: RuleType.block,
    );
    expect(duplicate, isFalse);

    // Toggle rule
    final rule = controller.rules.firstWhere((r) => r.domain == 'custom-adserver.com');
    await controller.toggleRule(rule.id);
    expect(controller.rules.firstWhere((r) => r.domain == 'custom-adserver.com').isEnabled, isFalse);

    // Remove rule
    await controller.removeRule(rule.id);
    expect(controller.rules.any((r) => r.domain == 'custom-adserver.com'), isFalse);
  });
}
