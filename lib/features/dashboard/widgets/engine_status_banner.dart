import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/protection_status.dart';
import '../../../providers/protection_state.dart';

/// Clean, consumer-friendly status banner for CLEARWAVE.
class EngineStatusBanner extends StatelessWidget {
  const EngineStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProtectionScope.of(context);
    final isActive = controller.status.isActive;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.activeGreen.withAlpha(20)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.activeGreen.withAlpha(60)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.activeGreen.withAlpha(30)
                  : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.shield_rounded : Icons.shield_outlined,
              size: 16,
              color: isActive ? AppColors.activeGreen : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'ALL DEVICES & APPS PROTECTED' : 'READY TO BLOCK ADS',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.activeGreen : AppColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  isActive
                      ? 'Stopping ads & trackers in real-time'
                      : 'One tap turns on ad blocking everywhere',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.activeGreen : AppColors.inactiveSlate,
            ),
          ),
        ],
      ),
    );
  }
}
