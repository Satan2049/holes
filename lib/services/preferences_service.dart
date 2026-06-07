import 'package:shared_preferences/shared_preferences.dart';

import '../models/camera.dart';
import '../models/user_preferences.dart';

class PreferencesService {
  static const _keyOnboarding = 'onboarding_complete';
  static const _keyAutoplay = 'autoplay';
  static const _keyHls = 'allow_hls';
  static const _keyMjpeg = 'allow_mjpeg';
  static const _keyBlockedCats = 'blocked_categories';
  static const _keyBlockedTags = 'blocked_tags';
  static const _keyLastCamera = 'last_camera_id';

  Future<UserPreferences> load() async {
    final p = await SharedPreferences.getInstance();
    final blockedCatNames = p.getStringList(_keyBlockedCats) ?? [];

    return UserPreferences(
      onboardingComplete: p.getBool(_keyOnboarding) ?? false,
      autoplayStreams: p.getBool(_keyAutoplay) ?? true,
      allowHls: p.getBool(_keyHls) ?? true,
      allowMjpeg: p.getBool(_keyMjpeg) ?? true,
      blockedCategories: blockedCatNames.map(_categoryFromName).toSet(),
      blockedTags: (p.getStringList(_keyBlockedTags) ?? []).toSet(),
    );
  }

  Future<void> save(UserPreferences prefs) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyOnboarding, prefs.onboardingComplete);
    await p.setBool(_keyAutoplay, prefs.autoplayStreams);
    await p.setBool(_keyHls, prefs.allowHls);
    await p.setBool(_keyMjpeg, prefs.allowMjpeg);
    await p.setStringList(
      _keyBlockedCats,
      prefs.blockedCategories.map((c) => c.name).toList(),
    );
    await p.setStringList(_keyBlockedTags, prefs.blockedTags.toList());
  }

  Future<String?> loadLastCameraId() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyLastCamera);
  }

  Future<void> saveLastCameraId(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyLastCamera, id);
  }

  static ContentCategory _categoryFromName(String name) {
    return ContentCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => ContentCategory.other,
    );
  }
}
