import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/protection_status.dart';

/// Highly-polished, animated VPN power toggle button.
/// Radiates smooth wave ripples when active, just like top commercial VPN applications.
class AnimatedVpnButton extends StatefulWidget {
  final ProtectionState status;
  final VoidCallback onToggle;

  const AnimatedVpnButton({
    super.key,
    required this.status,
    required this.onToggle,
  });

  @override
  State<AnimatedVpnButton> createState() => _AnimatedVpnButtonState();
}

class _AnimatedVpnButtonState extends State<AnimatedVpnButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    if (widget.status.isActive) {
      _rippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedVpnButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status.isActive && !oldWidget.status.isActive) {
      _rippleController.repeat();
    } else if (!widget.status.isActive && oldWidget.status.isActive) {
      _rippleController.stop();
      _rippleController.reset();
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.status.isActive;
    final isConnecting = widget.status.isConnecting;

    final Color primaryColor = isActive
        ? AppColors.activeGreen
        : (isConnecting ? AppColors.warningAmber : AppColors.inactiveSlate);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ripple & Power Button Stack
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            if (!isConnecting) widget.onToggle();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Ripple Waves (visible only when active)
                  if (isActive)
                    AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(250, 250),
                          painter: _VpnRipplePainter(
                            progress: _rippleController.value,
                            color: AppColors.activeGreen,
                          ),
                        );
                      },
                    ),

                  // Static Outer Ring
                  Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive
                            ? AppColors.activeGreen.withAlpha(60)
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                  ),

                  // Core Circular Button
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isActive
                            ? const [
                                Color(0xFF0D4B39),
                                Color(0xFF05251C),
                                Color(0xFF02140F),
                              ]
                            : [
                                AppColors.surfaceElevated,
                                AppColors.surface,
                                const Color(0xFF090D14),
                              ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                      border: Border.all(
                        color: isActive ? AppColors.activeGreen : AppColors.border,
                        width: isActive ? 3 : 2,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.activeGreen.withAlpha(140),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: AppColors.primary.withAlpha(80),
                                blurRadius: 44,
                                spreadRadius: 1,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withAlpha(120),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Center(
                      child: isConnecting
                          ? const SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.warningAmber,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.power_settings_new_rounded,
                              size: 64,
                              color: isActive
                                  ? AppColors.activeGreen
                                  : AppColors.textMuted,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Big Status Heading
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.activeGreen.withAlpha(180),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isActive
                  ? 'CONNECTED'
                  : (isConnecting ? 'CONNECTING...' : 'DISCONNECTED'),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: primaryColor,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Clean Subtitle
        Text(
          isActive
              ? 'Ad blocker running — all apps & websites ad-free'
              : (isConnecting
                  ? 'Starting secure on-device DNS filter...'
                  : 'Tap power button to block ads everywhere'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for smooth radiant wave pulses outward from the button.
class _VpnRipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _VpnRipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const minRadius = 76.0;
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i * 0.33)) % 1.0;
      final currentRadius = minRadius + (maxRadius - minRadius) * ringProgress;
      final opacity = math.sin(ringProgress * math.pi) * 0.35;

      final paint = Paint()
        ..color = color.withAlpha((opacity * 255).clamp(0, 255).toInt())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VpnRipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
