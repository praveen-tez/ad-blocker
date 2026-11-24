import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../core/platform/platform_channel_interface.dart';
import '../models/protection_status.dart';
import '../models/blocking_stats.dart';
import '../models/filter_category.dart';
import '../models/filter_rule.dart';
import '../models/dns_log_entry.dart';

/// Central state provider for CLEARWAVE Foundation.
/// Manages engine lifecycle, telemetry previews, rule sets, and categories.
class ProtectionController extends ChangeNotifier {
  final ProtectionPlatformInterface _engine;
  late StreamSubscription<ProtectionState> _engineSubscription;

  ProtectionState _status = ProtectionState.disabled;
  final BlockingStats _stats = BlockingStats.placeholder();
  List<FilterCategory> _categories = FilterCategory.defaultCategories();
  List<FilterRule> _rules = FilterRule.initialSeedRules();
  final List<DnsLogEntry> _dnsFeed = DnsLogEntry.mockFeed();

  // Settings
  String _selectedDnsResolver = 'Quad9 (Encrypted)';
  bool _filterIpv6 = true;
  bool _blockLanTraffic = false;
  bool _hasCompletedOnboarding = true;

  ProtectionController({ProtectionPlatformInterface? engine})
      : _engine = engine ?? SimulatedProtectionEngine() {
    _initEngine();
  }

  // Getters
  ProtectionState get status => _status;
  BlockingStats get stats => _stats;
  List<FilterCategory> get categories => List.unmodifiable(_categories);
  List<FilterRule> get rules => List.unmodifiable(_rules);
  List<DnsLogEntry> get dnsFeed => List.unmodifiable(_dnsFeed);
  String get selectedDnsResolver => _selectedDnsResolver;
  bool get filterIpv6 => _filterIpv6;
  bool get blockLanTraffic => _blockLanTraffic;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  int get totalActiveRules {
    int count = 0;
    for (final cat in _categories) {
      if (cat.isEnabled) count += cat.ruleCount;
    }
    count += _rules.where((r) => r.isEnabled && r.isBlock).length;
    return count;
  }

  void _initEngine() {
    _engineSubscription = _engine.statusStream.listen((newState) {
      _status = newState;
      notifyListeners();
    });
  }

  Future<void> toggleProtection() async {
    if (_status == ProtectionState.active) {
      await _engine.stopProtection();
      _status = ProtectionState.disabled;
    } else {
      await _engine.startProtection();
      _status = ProtectionState.active;
    }
    notifyListeners();
  }

  void toggleCategory(String categoryId) {
    _categories = _categories.map((cat) {
      if (cat.id == categoryId) {
        return cat.copyWith(isEnabled: !cat.isEnabled);
      }
      return cat;
    }).toList();
    notifyListeners();
  }

  void toggleRule(String ruleId) {
    _rules = _rules.map((rule) {
      if (rule.id == ruleId) {
        return rule.copyWith(isEnabled: !rule.isEnabled);
      }
      return rule;
    }).toList();
    notifyListeners();
  }

  bool addCustomRule({
    required String domain,
    required RuleType type,
    String note = '',
  }) {
    final cleanDomain = domain.trim().toLowerCase();
    if (cleanDomain.isEmpty || !cleanDomain.contains('.')) {
      return false;
    }

    // Check duplicate
    if (_rules.any((r) => r.domain == cleanDomain && r.type == type)) {
      return false;
    }

    final newRule = FilterRule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      domain: cleanDomain,
      type: type,
      addedAt: DateTime.now(),
      note: note.trim(),
    );

    _rules = [newRule, ..._rules];
    notifyListeners();
    return true;
  }

  void removeRule(String ruleId) {
    _rules = _rules.where((r) => r.id != ruleId).toList();
    notifyListeners();
  }

  void setDnsResolver(String resolver) {
    _selectedDnsResolver = resolver;
    notifyListeners();
  }

  void setFilterIpv6(bool value) {
    _filterIpv6 = value;
    notifyListeners();
  }

  void setBlockLanTraffic(bool value) {
    _blockLanTraffic = value;
    notifyListeners();
  }

  void setOnboardingCompleted(bool value) {
    _hasCompletedOnboarding = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _engineSubscription.cancel();
    super.dispose();
  }
}

/// InheritedWidget for scoped state access without third-party packages.
class ProtectionScope extends InheritedNotifier<ProtectionController> {
  const ProtectionScope({
    super.key,
    required ProtectionController controller,
    required super.child,
  }) : super(notifier: controller);

  static ProtectionController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ProtectionScope>();
    assert(scope != null, 'No ProtectionScope found in context');
    return scope!.notifier!;
  }
}
