import 'package:material_ui/material_ui.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/filtering/filtering_engine.dart';
import '../../../models/filter_rule.dart';
import '../../../providers/protection_state.dart';

/// Interactive tool allowing the user to inspect and test the filtering engine
/// against any live domain, showing exact allowlist/blocklist precedence decisions.
class DomainInspectorCard extends StatefulWidget {
  const DomainInspectorCard({super.key});

  @override
  State<DomainInspectorCard> createState() => _DomainInspectorCardState();
}

class _DomainInspectorCardState extends State<DomainInspectorCard> {
  final _inputController = TextEditingController(text: 'ads.doubleclick.net');
  FilterDecision? _lastDecision;
  bool _isEvaluating = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _evaluate() async {
    final query = _inputController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isEvaluating = true);

    final controller = ProtectionScope.of(context);
    final decision = await controller.inspectDomain(query);

    setState(() {
      _lastDecision = decision;
      _isEvaluating = false;
    });
  }

  void _quickTest(String domain) {
    _inputController.text = domain;
    _evaluate();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ProtectionScope.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.search, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'DOMAIN FILTER INSPECTOR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.activeGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Live Engine',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.activeGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Test any domain against the local SQLite database to verify exact match and allowlist precedence.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
          ),
          const SizedBox(height: 12),
          // Input field and test button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'e.g. tracker.facebook.com',
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  onSubmitted: (_) => _evaluate(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isEvaluating ? null : _evaluate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isEvaluating
                    ? const Text('...', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))
                    : const Text('Test', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Quick sample chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip('ads.doubleclick.net', 'Blocklist match'),
                const SizedBox(width: 6),
                _buildQuickChip('auth.mybank.com', 'Allowlist override'),
                const SizedBox(width: 6),
                _buildQuickChip('graph.facebook.com', 'Tracker match'),
                const SizedBox(width: 6),
                _buildQuickChip('wikipedia.org', 'Clean / Upstream'),
              ],
            ),
          ),
          // Evaluation Result Card
          if (_lastDecision != null) ...[
            const SizedBox(height: 14),
            _buildDecisionResult(controller, _lastDecision!),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickChip(String domain, String tooltip) {
    return InkWell(
      onTap: () => _quickTest(domain),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          domain,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildDecisionResult(ProtectionController controller, FilterDecision decision) {
    final isBlocked = decision.isBlocked;
    final isPrecedence = decision.decisionType == DecisionType.allowlistPrecedence;

    final Color badgeColor = isBlocked
        ? AppColors.errorRed
        : (isPrecedence ? AppColors.activeGreen : AppColors.secondary);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withAlpha(60), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isBlocked ? Icons.block : Icons.check_circle_outline,
                    color: badgeColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isBlocked ? 'EVALUATION: BLOCKED' : 'EVALUATION: ALLOWED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
              Text(
                '1ms lookup',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Target: ${decision.canonicalDomain}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Resolution: ${decision.matchedRule}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          // Action button to allowlist or blocklist this domain
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isBlocked)
                OutlinedButton.icon(
                  onPressed: () async {
                    await controller.addCustomRule(
                      domain: decision.canonicalDomain,
                      type: RuleType.allow,
                      note: 'Allowed via Inspector override',
                    );
                    _evaluate();
                  },
                  icon: const Icon(Icons.shield_outlined, size: 14),
                  label: const Text('Add to Allowlist (Override)', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.activeGreen,
                    side: BorderSide(color: AppColors.activeGreen.withAlpha(80)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () async {
                    await controller.addCustomRule(
                      domain: decision.canonicalDomain,
                      type: RuleType.block,
                      note: 'Blocked via Inspector',
                    );
                    _evaluate();
                  },
                  icon: const Icon(Icons.block, size: 14),
                  label: const Text('Add to Blocklist', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                    side: BorderSide(color: AppColors.errorRed.withAlpha(80)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
