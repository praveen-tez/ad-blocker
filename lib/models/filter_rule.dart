enum RuleType {
  block,
  allow,
}

/// Representation of a custom user-defined domain rule.
/// Allowlist rules strictly take precedence over blocklist rules.
class FilterRule {
  final String id;
  final String domain;
  final RuleType type;
  final bool isWildcard;
  final bool isEnabled;
  final DateTime addedAt;
  final String note;

  const FilterRule({
    required this.id,
    required this.domain,
    required this.type,
    this.isWildcard = true,
    this.isEnabled = true,
    required this.addedAt,
    this.note = '',
  });

  bool get isAllow => type == RuleType.allow;
  bool get isBlock => type == RuleType.block;

  FilterRule copyWith({
    String? id,
    String? domain,
    RuleType? type,
    bool? isWildcard,
    bool? isEnabled,
    DateTime? addedAt,
    String? note,
  }) {
    return FilterRule(
      id: id ?? this.id,
      domain: domain ?? this.domain,
      type: type ?? this.type,
      isWildcard: isWildcard ?? this.isWildcard,
      isEnabled: isEnabled ?? this.isEnabled,
      addedAt: addedAt ?? this.addedAt,
      note: note ?? this.note,
    );
  }

  static List<FilterRule> initialSeedRules() {
    return [
      FilterRule(
        id: '1',
        domain: 'telemetry.sdk-analytics.com',
        type: RuleType.block,
        addedAt: DateTime.now().subtract(const Duration(days: 2)),
        note: 'Aggressive third-party ad telemetry',
      ),
      FilterRule(
        id: '2',
        domain: 'ads.inapptracking.net',
        type: RuleType.block,
        addedAt: DateTime.now().subtract(const Duration(days: 1)),
        note: 'Known banner network',
      ),
      FilterRule(
        id: '3',
        domain: 'auth.mybank.com',
        type: RuleType.allow,
        addedAt: DateTime.now().subtract(const Duration(hours: 12)),
        note: 'Essential banking authentication bypass',
      ),
    ];
  }
}
