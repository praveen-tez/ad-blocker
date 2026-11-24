import 'package:material_ui/material_ui.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/filter_rule.dart';
import '../../../providers/protection_state.dart';
import '../widgets/add_domain_dialog.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  final _searchController = TextEditingController();
  RuleType? _filterType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ProtectionScope.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rules & Filtering'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Categories'),
              Tab(text: 'Custom Rules'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCategoriesTab(controller),
            _buildCustomRulesTab(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab(ProtectionController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.categories.length,
      itemBuilder: (context, index) {
        final category = controller.categories[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: category.isEnabled
                  ? AppColors.border
                  : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: category.isEnabled
                      ? AppColors.primary.withAlpha(25)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  category.icon,
                  size: 20,
                  color: category.isEnabled
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: category.isEnabled
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      category.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${category.ruleCount} embedded rules (SQLite)',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: category.isEnabled,
                onChanged: (_) => controller.toggleCategory(category.id),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomRulesTab(
    BuildContext context,
    ProtectionController controller,
  ) {
    var filteredRules = controller.rules;

    // Apply type filter
    if (_filterType != null) {
      filteredRules = filteredRules.where((r) => r.type == _filterType).toList();
    }

    // Apply search filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filteredRules = filteredRules.where((r) {
        return r.domain.toLowerCase().contains(query) ||
            r.note.toLowerCase().contains(query);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddDomainDialog(
              onAdd: (domain, type, note) async {
                final success = await controller.addCustomRule(
                  domain: domain,
                  type: type,
                  note: note,
                );
                if (!context.mounted) return;
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rule already exists or domain format is invalid.'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $domain to ${type == RuleType.allow ? "Allowlist" : "Blocklist"}'),
                    ),
                  );
                }
              },
            ),
          );
        },
        icon: const Icon(Icons.add, size: 18),
        label: const Text(
          'Add Rule',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Precedence explanation banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.balance,
                  size: 18,
                  color: AppColors.textAccent,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Precedence hierarchy: Allowlist rules strictly override all blocklist categories and custom blocks.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search Bar
          TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search custom rules...',
              prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceCard,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          Row(
            children: [
              _buildFilterChip(
                label: 'All (${controller.rules.length})',
                isSelected: _filterType == null,
                onSelected: () => setState(() => _filterType = null),
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Allow (${controller.allowlistCount})',
                isSelected: _filterType == RuleType.allow,
                onSelected: () => setState(() => _filterType = RuleType.allow),
                activeColor: AppColors.activeGreen,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Block (${controller.customBlockCount})',
                isSelected: _filterType == RuleType.block,
                onSelected: () => setState(() => _filterType = RuleType.block),
                activeColor: AppColors.errorRed,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // List of rules
          if (filteredRules.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  _searchController.text.isNotEmpty
                      ? 'No rules match "${_searchController.text}".'
                      : 'No custom rules found.',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRules.length,
              itemBuilder: (context, index) {
                final rule = filteredRules[index];
                final isAllow = rule.isAllow;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: rule.isEnabled
                          ? AppColors.border
                          : AppColors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isAllow
                              ? AppColors.activeGreen.withAlpha(25)
                              : AppColors.errorRed.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isAllow ? 'ALLOW' : 'BLOCK',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isAllow
                                ? AppColors.activeGreen
                                : AppColors.errorRed,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rule.domain,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: rule.isEnabled
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                            if (rule.note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  rule.note,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => _confirmDelete(context, controller, rule),
                      ),
                      Switch(
                        value: rule.isEnabled,
                        onChanged: (_) => controller.toggleRule(rule.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(25) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProtectionController controller,
    FilterRule rule,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Rule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "${rule.domain}" from custom ${rule.isAllow ? "allowlist" : "blocklist"}?',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.removeRule(rule.id);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
