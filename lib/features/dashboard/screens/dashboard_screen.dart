import 'package:material_ui/material_ui.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/protection_status.dart';
import '../../../providers/protection_state.dart';
import '../widgets/engine_status_banner.dart';
import '../widgets/protection_status_card.dart';
import '../widgets/stats_overview_card.dart';
import '../widgets/dns_live_preview_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProtectionScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: controller.status.isActive
                    ? AppColors.activeGreen
                    : AppColors.inactiveSlate,
              ),
            ),
            const SizedBox(width: 8),
            const Text(AppStrings.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.privacy_tip_outlined, size: 20),
            tooltip: 'Privacy Principles',
            onPressed: () => _showPrivacySheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EngineStatusBanner(),
              ProtectionStatusCard(
                status: controller.status,
                totalActiveRules: controller.totalActiveRules,
                onToggle: controller.toggleProtection,
              ),
              StatsOverviewCard(stats: controller.stats),
              DnsLivePreviewCard(entries: controller.dnsFeed),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user, color: AppColors.primary, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'CLEARWAVE Privacy Standard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                AppStrings.privacyPromise,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                'No SSL/TLS Interception',
                'CLEARWAVE never asks you to install Root CA certificates.',
              ),
              const SizedBox(height: 8),
              _buildPrivacyPoint(
                'Zero Browsing History Collection',
                'Your visited URLs, search queries, and content are never logged.',
              ),
              const SizedBox(height: 8),
              _buildPrivacyPoint(
                'Local DNS Resolution',
                'Filtering decisions occur directly on device loopback socket.',
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivacyPoint(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.activeGreen, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
