import 'package:material_ui/material_ui.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/protection_state.dart';

/// Top banner that dynamically displays native vs simulation engine status.
class EngineStatusBanner extends StatelessWidget {
  const EngineStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProtectionScope.of(context);
    final isNative = controller.isNativeEngine;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNative ? AppColors.activeGreen.withAlpha(80) : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isNative ? Icons.verified_user : Icons.info_outline,
            size: 16,
            color: isNative ? AppColors.activeGreen : AppColors.textAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isNative ? 'ANDROID NATIVE ENGINE' : 'STAGE 3 — ANDROID VPN ENGINE READY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isNative ? AppColors.activeGreen : AppColors.textAccent,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isNative ? AppColors.activeGreen.withAlpha(25) : AppColors.badgeBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isNative ? 'VpnService Active' : 'Native Kotlin Engine',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isNative ? AppColors.activeGreen : AppColors.badgeText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isNative
                      ? 'Android VpnService loopback TUN is active. DNS traffic is filtered locally without external proxying.'
                      : 'Kotlin VpnService DNS loopback engine and TUN packet parser are fully implemented in native code.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
