import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/protection_status.dart';

/// Ultra-modern, simple one-tap power hero card for CLEARWAVE.
/// Features a large glowing circular power button with immediate visual feedback.
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isActive ? AppColors.activeGreen.withAlpha(80) : AppColors.border,
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.activeGreen.withAlpha(35),
                  blurRadius: 36,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Circular Power Button with Glow Rings
          GestureDetector(
            onTap: isConnecting ? null : onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 164,
              height: 164,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isActive
                      ? [
                          AppColors.activeGreen.withAlpha(60),
                          AppColors.activeGreen.withAlpha(20),
                          Colors.transparent,
                        ]
                      : [
                          AppColors.surfaceElevated,
                          AppColors.surface,
                          Colors.transparent,
                        ],
                  stops: const [0.4, 0.8, 1.0],
                ),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? const Color(0xFF063327) : AppColors.surfaceElevated,
                    border: Border.all(
                      color: isActive ? AppColors.activeGreen : AppColors.border,
                      width: isActive ? 3 : 2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.activeGreen.withAlpha(120),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: isConnecting
                        ? const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.warningAmber),
                            ),
                          )
                        : Icon(
                            Icons.power_settings_new_rounded,
                            size: 54,
                            color: isActive ? AppColors.activeGreen : AppColors.textMuted,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Status Heading
          Text(
            isActive
                ? 'AD BLOCKING ACTIVE'
                : (isConnecting ? 'CONNECTING...' : 'PROTECTION OFF'),
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: statusColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),

          // Status Subtitle
          Text(
            isActive
                ? 'Ads and trackers are blocked in all apps and browsers'
                : (isConnecting
                    ? 'Setting up on-device protection engine...'
                    : 'Tap power button to turn on ad blocker'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Active rules pill badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.activeGreen.withAlpha(25)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? AppColors.activeGreen.withAlpha(60)
                    : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? Icons.verified_rounded : Icons.pause_circle_outline,
                  size: 14,
                  color: isActive ? AppColors.activeGreen : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  isActive
                      ? '$totalActiveRules filters active • System-wide'
                      : 'Standby • Ready to protect',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isActive ? AppColors.textPrimary : AppColors.textMuted,
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
