import 'package:material_ui/material_ui.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/protection_status.dart';

/// Hero card featuring the main protection toggle and state visualization.
class ProtectionStatusCard extends StatelessWidget {
  final ProtectionState status;
  final int totalActiveRules;
  final VoidCallback onToggle;

  const ProtectionStatusCard({
    super.key,
    required this.status,
    required this.totalActiveRules,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status.isActive;
    final isConnecting = status.isConnecting;

    final Color statusColor = isActive
        ? AppColors.activeGreen
        : (isConnecting ? AppColors.warningAmber : AppColors.inactiveSlate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.activeGreen.withAlpha(70) : AppColors.border,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // State Indicator Shield Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withAlpha(80), width: 1),
                ),
                child: Icon(
                  isActive
                      ? Icons.shield
                      : (isConnecting ? Icons.sync : Icons.shield_outlined),
                  color: statusColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Main Toggle Switch
              Switch(
                value: isActive || isConnecting,
                onChanged: isConnecting ? null : (_) => onToggle(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Metadata Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetaItem(
                label: 'Active Rules',
                value: isActive ? '$totalActiveRules rules' : 'Standby',
              ),
              _buildMetaItem(
                label: 'Protocol',
                value: 'Local DNS Loopback',
              ),
              _buildMetaItem(
                label: 'Engine',
                value: 'Stage 1 Simulated',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
