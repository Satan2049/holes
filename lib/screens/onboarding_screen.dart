import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/camera.dart';
import '../models/user_preferences.dart';
import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import 'browse_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.fromSettings = false});

  /// True when opened from browse screen gear icon.
  final bool fromSettings;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _autoplay = true;
  bool _allowHls = true;
  bool _allowMjpeg = true;
  final _blocked = <ContentCategory>{};

  @override
  void initState() {
    super.initState();
    if (widget.fromSettings) {
      _loadExisting();
    } else {
      final d = UserPreferences.platformDefaults();
      _autoplay = d.autoplayStreams;
      _allowHls = d.allowHls;
      _allowMjpeg = d.allowMjpeg;
    }
  }

  Future<void> _loadExisting() async {
    final p = await PreferencesService().load();
    setState(() {
      _autoplay = p.autoplayStreams;
      _allowHls = p.allowHls;
      _allowMjpeg = p.allowMjpeg;
      _blocked
        ..clear()
        ..addAll(p.blockedCategories);
    });
  }

  Future<void> _finish() async {
    final prefs = UserPreferences(
      onboardingComplete: true,
      autoplayStreams: _autoplay,
      allowHls: _allowHls,
      allowMjpeg: _allowMjpeg,
      blockedCategories: _blocked,
    );
    await PreferencesService().save(prefs);
    if (!mounted) return;
    if (widget.fromSettings) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BrowseScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.void950,
      appBar: AppBar(
        backgroundColor: AppColors.void950,
        title: Text(widget.fromSettings ? 'Content settings' : 'Welcome'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Choose what you want — keeps the app fast.',
            style: TextStyle(color: AppColors.cyber400, height: 1.4),
          ),
          const SizedBox(height: 24),
          _section('Playback'),
          SwitchListTile(
            title: const Text('Autoplay streams', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Start video when you open a camera', style: TextStyle(color: AppColors.cyber400)),
            value: _autoplay,
            activeThumbColor: AppColors.accent,
            onChanged: (v) => setState(() => _autoplay = v),
          ),
          _section('Stream types'),
          SwitchListTile(
            title: const Text('HLS (.m3u8)', style: TextStyle(color: Colors.white)),
            value: _allowHls,
            activeThumbColor: AppColors.accent,
            onChanged: (v) => setState(() => _allowHls = v),
          ),
          SwitchListTile(
            title: const Text('MJPEG / image streams', style: TextStyle(color: Colors.white)),
            subtitle: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
                ? const Text(
                    'Off by default on Android — HLS is smoother',
                    style: TextStyle(color: AppColors.cyber400, fontSize: 11),
                  )
                : null,
            value: _allowMjpeg,
            activeThumbColor: AppColors.accent,
            onChanged: (v) => setState(() => _allowMjpeg = v),
          ),
          _section('Content filtering'),
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 4),
            child: Text('Block categories', style: TextStyle(color: AppColors.cyber400, fontSize: 12)),
          ),
          ...ContentCategory.values.where((c) => c != ContentCategory.sample).map(
            (cat) => CheckboxListTile(
              title: Text(cat.name, style: const TextStyle(color: Colors.white)),
              value: _blocked.contains(cat),
              activeColor: AppColors.primary,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _blocked.add(cat);
                  } else {
                    _blocked.remove(cat);
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.void900,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Public camera streams are for observation only. Respect privacy, '
              'property, and local laws. Do not use feeds for surveillance or harassment.',
              style: TextStyle(color: AppColors.cyber400, fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _allowHls || _allowMjpeg ? _finish : null,
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(widget.fromSettings ? 'Save' : 'Start browsing'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.onSurfaceMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
