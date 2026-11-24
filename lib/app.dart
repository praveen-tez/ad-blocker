import 'package:material_ui/material_ui.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'providers/protection_state.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

class ClearwaveApp extends StatefulWidget {
  final ProtectionController? controller;

  const ClearwaveApp({super.key, this.controller});

  @override
  State<ClearwaveApp> createState() => _ClearwaveAppState();
}

class _ClearwaveAppState extends State<ClearwaveApp> {
  late final ProtectionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ProtectionController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProtectionScope(
      controller: _controller,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            home: !_controller.hasCompletedOnboarding
                ? const OnboardingScreen()
                : const DashboardScreen(),
          );
        },
      ),
    );
  }
}
