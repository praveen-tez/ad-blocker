import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/protection_status.dart';
import '../../../providers/protection_state.dart';
import '../widgets/engine_status_banner.dart';
import '../widgets/protection_status_card.dart';
import '../widgets/domain_inspector_card.dart';
import '../widgets/stats_overview_card.dart';
import '../widgets/dns_live_preview_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProtectionScope.of(context);
    final isActive = controller.status.isActive;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.activeGreen.withAlpha(30)
                    : AppColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_rounded,
                size: 18,
                color: isActive ? AppColors.activeGreen : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              AppStrings.appName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.activeGreen.withAlpha(25)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? AppColors.activeGreen.withAlpha(70)
                    : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppColors.activeGreen : AppColors.inactiveSlate,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? 'PROTECTED' : 'STANDBY',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.activeGreen : AppColors.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
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
              // Central One-Tap Power Shield Button
              ProtectionStatusCard(
                status: controller.status,
                totalActiveRules: controller.totalActiveRules,
                onToggle: controller.toggleProtection,
              ),
              // Activity Statistics Overview
              StatsOverviewCard(stats: controller.stats),
              // Quick Category Shields
              _buildQuickShieldsCard(context, controller),
              // Live Domain Filter Inspector (Allows testing any domain)
              const DomainInspectorCard(),
              // DNS Activity Preview
              DnsLivePreviewCard(entries: controller.dnsFeed),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickShieldsCard(BuildContext context, ProtectionController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK PROTECTION SHIELDS',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          _buildShieldRow(
            icon: Icons.block_rounded,
            iconColor: const Color(0xFFFF5252),
            title: 'Block Display & Video Ads',
            subtitle: 'Banners, intrusive popups, and ad servers',
            isEnabled: controller.categories.any((c) => c.id == 'ads' && c.isEnabled),
            onChanged: () => controller.toggleCategory('ads'),
          ),
          const Divider(height: 20),
          _buildShieldRow(
            icon: Icons.fingerprint_rounded,
            iconColor: AppColors.primary,
            title: 'Stop Online Trackers',
            subtitle: 'Analytics scripts, profiling, and telemetry',
            isEnabled: controller.categories.any((c) => c.id == 'trackers' && c.isEnabled),
            onChanged: () => controller.toggleCategory('trackers'),
          ),
          const Divider(height: 20),
          _buildShieldRow(
            icon: Icons.security_rounded,
            iconColor: AppColors.activeGreen,
            title: 'Block Malicious Domains',
            subtitle: 'Known phishing, fraud, and malware sites',
            isEnabled: controller.categories.any((c) => c.id == 'malware' && c.isEnabled),
            onChanged: () => controller.toggleCategory('malware'),
          ),
        ],
      ),
    );
  }

  Widget _buildShieldRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: isEnabled,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'CLEARWAVE Privacy Standard',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                AppStrings.privacyPromise,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                'No SSL/TLS Interception',
                'CLEARWAVE never asks you to install Root CA certificates.',
              ),
              const SizedBox(height: 8),
              _buildPrivacyPoint(
                'Zero Browsing History Collection',
                'Your visited URLs, search queries, and content are never logged or uploaded.',
              ),
              const SizedBox(height: 8),
              _buildPrivacyPoint(
                'On-Device Local Processing',
                'Filtering decisions occur 100% locally on your device.',
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
        const Icon(Icons.check_circle_rounded, color: AppColors.activeGreen, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.poppins(
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
