import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwave/app.dart';
import 'package:clearwave/core/constants/app_strings.dart';
import 'package:clearwave/models/filter_rule.dart';
import 'package:clearwave/providers/protection_state.dart';

void main() {
  testWidgets('CLEARWAVE Stage 1 smoke and UI structure test', (WidgetTester tester) async {
    final controller = ProtectionController();
    await tester.pumpWidget(ClearwaveApp(controller: controller));
    await tester.pumpAndSettle();

    // 1. Verify Header and Product Branding
    expect(find.text(AppStrings.appName), findsOneWidget);

    // 2. Verify Stage 1 Engine Notice Banner
    expect(find.textContaining('STAGE 1 — FOUNDATION PREVIEW'), findsOneWidget);

    // 3. Verify Protection Card & Status
    expect(find.text('Unprotected'), findsOneWidget);
    expect(find.text('Standby'), findsOneWidget);

    // 4. Verify Placeholder Telemetry Badge
    expect(find.text('Simulated Baseline'), findsOneWidget);
    expect(find.text('Ads Blocked'), findsOneWidget);
    expect(find.text('Trackers Halted'), findsOneWidget);

    // 5. Test Protection Toggle interaction
    final switchFinder = find.byType(Switch).first;
    await tester.tap(switchFinder);
    await tester.pump();

    // Verify connecting or active transition
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Protected'), findsOneWidget);

    // 6. Test Navigation to Rules Tab
    await tester.tap(find.text('Rules'));
    await tester.pumpAndSettle();
    expect(find.text('Rules & Filtering'), findsOneWidget);
    expect(find.text('Advertising & Commercial Banners'), findsOneWidget);

    // 7. Test Navigation to Streaming Tab
    await tester.tap(find.text('Streaming'));
    await tester.pumpAndSettle();
    expect(find.text('Streaming Compatibility'), findsOneWidget);
    expect(find.text('Realistic Streaming Expectations'), findsOneWidget);

    // 8. Test Navigation to Settings Tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings & Engine'), findsOneWidget);
    expect(find.text('Stage 1 — Foundation'), findsOneWidget);

    controller.dispose();
  });

  test('ProtectionController rules precedence and management logic', () {
    final controller = ProtectionController();

    // Initial state
    expect(controller.rules.length, 3);
    final initialActiveRules = controller.totalActiveRules;

    // Add valid block rule
    final added = controller.addCustomRule(
      domain: 'adserver.doubleclick.net',
      type: RuleType.block,
      note: 'Test Block',
    );
    expect(added, isTrue);
    expect(controller.rules.length, 4);
    expect(controller.totalActiveRules, initialActiveRules + 1);

    // Prevent duplicate
    final duplicate = controller.addCustomRule(
      domain: 'adserver.doubleclick.net',
      type: RuleType.block,
    );
    expect(duplicate, isFalse);

    // Toggle rule
    final ruleId = controller.rules.first.id;
    controller.toggleRule(ruleId);
    expect(controller.rules.first.isEnabled, isFalse);

    // Remove rule
    controller.removeRule(ruleId);
    expect(controller.rules.length, 3);

    controller.dispose();
  });
}
