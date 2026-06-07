import 'package:flutter/foundation.dart';

import 'camera.dart';

/// Saved on first launch — keeps the app light on weak devices.
class UserPreferences {
  const UserPreferences({
    this.onboardingComplete = false,
    this.autoplayStreams = true,
    this.allowHls = true,
    this.allowMjpeg = true,
    this.blockedCategories = const {},
    this.blockedTags = const {},
  });

  final bool onboardingComplete;
  final bool autoplayStreams;
  final bool allowHls;
  final bool allowMjpeg;
  final Set<ContentCategory> blockedCategories;
  final Set<String> blockedTags;

  UserPreferences copyWith({
    bool? onboardingComplete,
    bool? autoplayStreams,
    bool? allowHls,
    bool? allowMjpeg,
    Set<ContentCategory>? blockedCategories,
    Set<String>? blockedTags,
  }) {
    return UserPreferences(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      autoplayStreams: autoplayStreams ?? this.autoplayStreams,
      allowHls: allowHls ?? this.allowHls,
      allowMjpeg: allowMjpeg ?? this.allowMjpeg,
      blockedCategories: blockedCategories ?? this.blockedCategories,
      blockedTags: blockedTags ?? this.blockedTags,
    );
  }

  /// First-run defaults — HLS-only on Android for smoother playback.
  static UserPreferences platformDefaults() {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return UserPreferences(
      autoplayStreams: true,
      allowHls: true,
      allowMjpeg: !isAndroid,
    );
  }

  static const categoryKeys = {
    ContentCategory.traffic: 'traffic',
    ContentCategory.outdoor: 'outdoor',
    ContentCategory.indoor: 'indoor',
    ContentCategory.skyline: 'skyline',
    ContentCategory.sample: 'sample',
    ContentCategory.other: 'other',
  };
}
