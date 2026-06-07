import 'package:flutter/material.dart';

import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import 'browse_screen.dart';
import 'onboarding_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _checking = true;
  bool _needsOnboarding = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await PreferencesService().load();
    setState(() {
      _needsOnboarding = !prefs.onboardingComplete;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.void950,
        body: Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
      );
    }
    return _needsOnboarding ? const OnboardingScreen() : const BrowseScreen();
  }
}
