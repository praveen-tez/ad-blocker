import 'package:material_ui/material_ui.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'providers/protection_state.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/rules/screens/rules_screen.dart';
import 'features/streaming/screens/streaming_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

class ClearwaveApp extends StatefulWidget {
  final ProtectionController? controller;

  const ClearwaveApp({super.key, this.controller});

  @override
  State<ClearwaveApp> createState() => _ClearwaveAppState();
}

class _ClearwaveAppState extends State<ClearwaveApp> {
  late final ProtectionController _controller;
  int _currentIndex = 0;

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
                : Scaffold(
                    body: IndexedStack(
                      index: _currentIndex,
                      children: const [
                        DashboardScreen(),
                        RulesScreen(),
                        StreamingScreen(),
                        SettingsScreen(),
                      ],
                    ),
                    bottomNavigationBar: NavigationBar(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (index) {
                        setState(() => _currentIndex = index);
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.shield_outlined),
                          selectedIcon: Icon(Icons.shield),
                          label: 'Dashboard',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.tune_outlined),
                          selectedIcon: Icon(Icons.tune),
                          label: 'Rules',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.live_tv_outlined),
                          selectedIcon: Icon(Icons.live_tv),
                          label: 'Streaming',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: 'Settings',
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
