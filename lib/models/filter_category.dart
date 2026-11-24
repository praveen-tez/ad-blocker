import 'package:material_ui/material_ui.dart';

/// Pre-configured filter categories for DNS blocking.
class FilterCategory {
  final String id;
  final String name;
  final String description;
  final int ruleCount;
  final bool isEnabled;
  final IconData icon;

  const FilterCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.ruleCount,
    this.isEnabled = true,
    required this.icon,
  });

  FilterCategory copyWith({
    String? id,
    String? name,
    String? description,
    int? ruleCount,
    bool? isEnabled,
    IconData? icon,
  }) {
    return FilterCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ruleCount: ruleCount ?? this.ruleCount,
      isEnabled: isEnabled ?? this.isEnabled,
      icon: icon ?? this.icon,
    );
  }

  static List<FilterCategory> defaultCategories() {
    return const [
      FilterCategory(
        id: 'ads',
        name: 'Advertising & Commercial Banners',
        description: 'Blocks widespread mobile and web ad networks.',
        ruleCount: 84210,
        isEnabled: true,
        icon: Icons.campaign_outlined,
      ),
      FilterCategory(
        id: 'trackers',
        name: 'Behavioral Trackers & Telemetry',
        description: 'Blocks analytics, fingerprinting, and session recording.',
        ruleCount: 42180,
        isEnabled: true,
        icon: Icons.fingerprint,
      ),
      FilterCategory(
        id: 'malware',
        name: 'Malware & Phishing Shields',
        description: 'Blocks verified malicious domains and spoofed sites.',
        ruleCount: 26900,
        isEnabled: true,
        icon: Icons.security_outlined,
      ),
      FilterCategory(
        id: 'crypto',
        name: 'Cryptojackers & Miners',
        description: 'Blocks silent in-browser cryptocurrency mining scripts.',
        ruleCount: 3120,
        isEnabled: true,
        icon: Icons.memory,
      ),
      FilterCategory(
        id: 'adult',
        name: 'Adult & Gambling Gate',
        description: 'Filters adult material, illegal betting, and fraud domains.',
        ruleCount: 65400,
        isEnabled: false,
        icon: Icons.family_restroom,
      ),
    ];
  }
}
