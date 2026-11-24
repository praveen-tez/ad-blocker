import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/protection_status.dart';
import '../../../providers/protection_state.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/animated_vpn_button.dart';
import '../widgets/domain_inspector_card.dart';

/// Pure VPN-style Dashboard for CLEARWAVE.
/// Centered around a large animated power button with radiant wave ripples.
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
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.activeGreen.withAlpha(25)
                    : AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? AppColors.activeGreen.withAlpha(80)
                      : AppColors.border,
                ),
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
          // Connection Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.activeGreen.withAlpha(20)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
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
                  isActive ? 'PROTECTED' : 'OFF',
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
          const SizedBox(width: 4),
          // Settings Gear Icon (navigates to Settings, Rules, and Advanced Config)
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            tooltip: 'Settings & Rules',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 28),

              // Hero: Center Animated VPN Power Button with Waves
              AnimatedVpnButton(
                status: controller.status,
                onToggle: controller.toggleProtection,
              ),

              const SizedBox(height: 24),

              // Server / Protocol Info Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.dns_rounded,
                      size: 14,
                      color: isActive ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${controller.selectedDnsResolver} • ${controller.totalActiveRules} Rules',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Simple 3-Metric Quick Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.block_rounded,
                        color: const Color(0xFFFF5252),
                        label: 'Ads Blocked',
                        value: controller.stats.blockedAds.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.fingerprint_rounded,
                        color: AppColors.primary,
                        label: 'Trackers',
                        value: controller.stats.blockedTrackers.toString(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFFFFD600),
                        label: 'Data Saved',
                        value: '${controller.stats.dataSavedMb} MB',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bottom Section: Ad Blocker Test Tool (Allows testing any URL/domain)
              const DomainInspectorCard(),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
