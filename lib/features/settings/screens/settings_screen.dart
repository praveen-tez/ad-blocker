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
          _buildSectionHeader('LOCAL DATABASE & STORAGE (STAGE 2)'),
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
                _buildInfoRow('Database Engine', 'SQLite (clearwave.db)'),
                const Divider(height: 16),
                _buildInfoRow('Custom User Rules', '${controller.rules.length} stored rules'),
                const Divider(height: 16),
                _buildInfoRow('Active Filtering Rules', '${controller.totalActiveRules} active rules'),
                const Divider(height: 16),
                _buildInfoRow('Allowlist Precedence', 'Enforced by SQLite index'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmResetDatabase(context, controller),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset Rules to Factory Defaults', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warningAmber,
                      side: BorderSide(color: AppColors.warningAmber.withAlpha(80)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
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
                _buildInfoRow('Development Stage', 'Stage 5 — Cross-Platform Production Ready'),
                const Divider(height: 16),
                _buildInfoRow('Local Rules Storage', 'SQLite (clearwave.db)'),
                const Divider(height: 16),
                _buildInfoRow('Android Target', 'Kotlin VpnService (DNS Sinkhole Loopback)'),
                const Divider(height: 16),
                _buildInfoRow('iOS Target', 'NetworkExtension / NEDNSSettingsManager'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('PLATFORM CAPABILITIES & IOS EXPORT (STAGE 4 & 5)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'iOS & System Capabilities Breakdown',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '• NEDNSSettingsManager: Public Apple API (iOS 14+) for system-wide encrypted DNS (DoH/DoT) without special developer entitlements.\n'
                  '• Safari Content Blocker: JSON rule list compiled for Safari web browsing.\n'
                  '• Packet Tunnel Provider: Requires restricted com.apple.developer.networking.networkextension entitlement.',
                  style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPlatformCapabilitiesDialog(context, controller),
                        icon: const Icon(Icons.security, size: 16),
                        label: const Text('Check Capabilities', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showSafariRulesDialog(context, controller),
                        icon: const Icon(Icons.code, size: 16),
                        label: const Text('Safari JSON Rules', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.activeGreen,
                          side: const BorderSide(color: AppColors.activeGreen),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
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

  void _showPlatformCapabilitiesDialog(BuildContext context, ProtectionController controller) async {
    final caps = await controller.checkPlatformCapabilities();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Platform Capabilities', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: caps.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.key}: ',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      '${e.value}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Close', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showSafariRulesDialog(BuildContext context, ProtectionController controller) {
    final jsonRules = controller.exportSafariContentBlockerJson();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.apple, color: AppColors.textPrimary, size: 22),
            SizedBox(width: 8),
            Text('Safari Content Blocker JSON', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Compiled Apple SFContentBlockerManager rule structure generated from active SQLite blocklist rules:',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonRules,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Close', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _confirmResetDatabase(BuildContext context, ProtectionController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Reset Rule Database', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: const Text(
          'This will restore the factory default seed rules and categories in SQLite. Custom domains will be reset.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await controller.resetDatabase();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rule database restored to factory defaults.')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.warningAmber),
            child: const Text('Reset Database'),
          ),
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
