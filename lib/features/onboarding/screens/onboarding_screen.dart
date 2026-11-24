import 'package:material_ui/material_ui.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/protection_state.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isStandalone;

  const OnboardingScreen({super.key, this.isStandalone = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      icon: Icons.shield,
      title: 'Zero-Interception DNS Protection',
      description:
          'CLEARWAVE operates as a local on-device DNS filter. It terminates connections to known trackers and ad networks before requests ever leave your hardware.',
      highlight: 'No HTTPS interception • No certificate installation required',
    ),
    _OnboardingStep(
      icon: Icons.rule_folder_outlined,
      title: 'Categorized Rules & Allowlist Precedence',
      description:
          'Tailor protection with granular categories or add custom domains. Essential apps and services can be protected using allowlist rules which strictly override all blocks.',
      highlight: 'Exact and subdomain matching • Local SQLite storage',
    ),
    _OnboardingStep(
      icon: Icons.tv,
      title: 'Honest Streaming Expectations',
      description:
          'Unlike generic blockers, CLEARWAVE is upfront: server-side stitched video ads (like YouTube) share hostnames with video content and cannot be blocked via DNS alone.',
      highlight: 'Third-party ads & trackers blocked • Unbroken playback',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    if (widget.isStandalone) {
      Navigator.of(context).pop();
    } else {
      ProtectionScope.of(context).setOnboardingCompleted(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Introduction'),
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Skip', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(60),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(step.icon, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          step.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            step.highlight,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _steps.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == index ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (_currentPage < _steps.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finish();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _currentPage == _steps.length - 1
                          ? 'Get Started'
                          : 'Continue',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final IconData icon;
  final String title;
  final String description;
  final String highlight;

  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.highlight,
  });
}
