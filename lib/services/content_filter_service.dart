import '../models/camera.dart';
import '../models/user_preferences.dart';
import '../utils/platform_playback.dart';
import '../utils/stream_utils.dart';

class BrowseFilters {
  const BrowseFilters({
    this.query = '',
    this.country,
    this.category,
    this.streamTypeOnly,
    this.webFriendlyOnly = false,
    this.favoritesOnly = false,
  });

  final String query;
  final String? country;
  final ContentCategory? category;
  final StreamType? streamTypeOnly;
  /// HTTPS snapshot/MJPEG only — best chance on Flutter web.
  final bool webFriendlyOnly;
  final bool favoritesOnly;

  BrowseFilters copyWith({
    String? query,
    String? country,
    ContentCategory? category,
    StreamType? streamTypeOnly,
    bool? webFriendlyOnly,
    bool? favoritesOnly,
    bool clearCountry = false,
    bool clearCategory = false,
    bool clearStreamType = false,
  }) {
    return BrowseFilters(
      query: query ?? this.query,
      country: clearCountry ? null : (country ?? this.country),
      category: clearCategory ? null : (category ?? this.category),
      streamTypeOnly:
          clearStreamType ? null : (streamTypeOnly ?? this.streamTypeOnly),
      webFriendlyOnly: webFriendlyOnly ?? this.webFriendlyOnly,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      country != null ||
      category != null ||
      streamTypeOnly != null ||
      favoritesOnly ||
      webFriendlyOnly;
}

class ContentFilterService {
  List<Camera> apply({
    required List<Camera> all,
    required UserPreferences prefs,
    required BrowseFilters active,
    bool Function(Camera cam)? isBlocked,
    Set<String>? favoriteIds,
  }) {
    return all.where((cam) {
      if (isBlocked?.call(cam) ?? false) return false;
      if (!_allowedByPrefs(cam, prefs)) return false;
      if (!_matchesBrowseFilters(cam, active, favoriteIds)) return false;
      return true;
    }).toList();
  }

  static bool _allowedByPrefs(Camera cam, UserPreferences prefs) {
    if (cam.category == ContentCategory.sample) return false;
    if (prefs.blockedCategories.contains(cam.category)) return false;
    for (final tag in cam.tags) {
      if (prefs.blockedTags.contains(tag.toLowerCase())) return false;
    }
    if (isYoutubeStream(cam.streamType) || isEmbedStream(cam.streamType)) return true;
    final isHls = isHlsStream(cam.streamUrl, cam.streamType);
    if (isHls && !prefs.allowHls) return false;
    if (!isHls && !prefs.allowMjpeg) return false;
    return true;
  }

  static bool _matchesBrowseFilters(
    Camera cam,
    BrowseFilters f,
    Set<String>? favoriteIds,
  ) {
    if (f.favoritesOnly && !(favoriteIds?.contains(cam.id) ?? false)) {
      return false;
    }
    if (f.country != null &&
        cam.country.toLowerCase() != f.country!.toLowerCase()) {
      return false;
    }
    if (f.category != null && cam.category != f.category) return false;
    if (f.streamTypeOnly != null) {
      if (isYoutubeStream(cam.streamType) || isEmbedStream(cam.streamType)) {
        return false;
      }

      final isHls = isHlsStream(cam.streamUrl, cam.streamType);
      if (f.streamTypeOnly == StreamType.hls && !isHls) return false;
      if (f.streamTypeOnly == StreamType.mjpeg && isHls) return false;
    }
    if (f.webFriendlyOnly && !PlatformPlayback.isWebFriendly(cam)) return false;
    final q = f.query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final hay = '${cam.name} ${cam.city} ${cam.country} ${cam.tags.join(' ')}'.toLowerCase();
    return hay.contains(q);
  }

  static List<String> countries(List<Camera> cameras) {
    final set = cameras.map((c) => c.country).where((c) => c.isNotEmpty).toSet();
    final list = set.toList()..sort();
    return list;
  }
}
