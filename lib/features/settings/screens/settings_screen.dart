import 'package:material_ui/material_ui.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/protection_state.dart';
import '../../onboarding/screens/onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProtectionScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Engine'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('UPSTREAM DNS RESOLVER'),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildResolverTile(
                  controller: controller,
                  title: 'Quad9 (Encrypted DNS)',
                  subtitle: 'Malware blocking default • Swiss privacy compliant',
                  value: 'Quad9 (Encrypted)',
                ),
                const Divider(height: 1),
                _buildResolverTile(
                  controller: controller,
                  title: 'Cloudflare (1.1.1.1)',
                  subtitle: 'Ultra low latency • Zero logs policy',
                  value: 'Cloudflare 1.1.1.1',
                ),
                const Divider(height: 1),
                _buildResolverTile(
                  controller: controller,
                  title: 'AdGuard DNS',
                  subtitle: 'Secondary upstream ad-filtering fallback',
                  value: 'AdGuard DNS',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('NETWORK BEHAVIOR'),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Filter IPv6 Traffic',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Prevents IPv6 DNS leaks by filtering AAAA queries.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  value: controller.filterIpv6,
                  onChanged: controller.setFilterIpv6,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text(
                    'Bypass Local LAN Traffic',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Direct communication with local network devices and routers.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  value: controller.blockLanTraffic,
                  onChanged: controller.setBlockLanTraffic,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('SYSTEM & DIAGNOSTICS'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildInfoRow('Product Name', AppStrings.appName),
                const Divider(height: 16),
                _buildInfoRow('Development Stage', 'Stage 1 — Foundation'),
                const Divider(height: 16),
                _buildInfoRow('Engine Architecture', 'Hybrid Flutter + Native OS'),
                const Divider(height: 16),
                _buildInfoRow('Android Target', 'Kotlin VpnService (Stage 3)'),
                const Divider(height: 16),
                _buildInfoRow('iOS Target', 'NetworkExtension / DNS (Stage 4)'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(isStandalone: true),
                ),
              );
            },
            icon: const Icon(Icons.school_outlined, size: 18),
            label: const Text('View Onboarding Tour'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildResolverTile({
    required ProtectionController controller,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = controller.selectedDnsResolver == value;

    return InkWell(
      onTap: () => controller.setDnsResolver(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
