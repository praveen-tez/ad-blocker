import 'package:material_ui/material_ui.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/protection_state.dart';
import '../widgets/add_domain_dialog.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: category.isEnabled
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
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
                        '${category.ruleCount.toString()} local rules',
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
    final rules = controller.rules;
    final allowCount = rules.where((r) => r.isAllow).length;
    final blockCount = rules.where((r) => r.isBlock).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddDomainDialog(
              onAdd: (domain, type, note) {
                final success = controller.addCustomRule(
                  domain: domain,
                  type: type,
                  note: note,
                );
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rule already exists or is invalid.'),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCountBadge(
                  label: 'ALLOWLIST (BYPASS)',
                  count: allowCount,
                  color: AppColors.activeGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCountBadge(
                  label: 'BLOCKLIST (CUSTOM)',
                  count: blockCount,
                  color: AppColors.errorRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rules.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No custom rules configured yet.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
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
                        onPressed: () => controller.removeRule(rule.id),
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

  Widget _buildCountBadge({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count rules active',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
