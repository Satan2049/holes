import 'package:flutter_test/flutter_test.dart';
import 'package:holes/models/camera.dart';
import 'package:holes/models/user_preferences.dart';
import 'package:holes/services/content_filter_service.dart';

void main() {
  const camHls = Camera(
    id: 'hls-1',
    name: 'Main St',
    streamUrl: 'https://example.com/live.m3u8',
    country: 'United States',
    city: 'Austin',
    streamType: StreamType.hls,
    category: ContentCategory.traffic,
  );

  const camMjpeg = Camera(
    id: 'mjpeg-1',
    name: 'Beach Cam',
    streamUrl: 'https://example.com/cam.jpg',
    country: 'United States',
    city: 'Miami',
    streamType: StreamType.mjpeg,
    category: ContentCategory.outdoor,
  );

  const camSample = Camera(
    id: 'sample-1',
    name: 'Demo',
    streamUrl: 'https://example.com/v',
    country: 'United States',
    city: 'Test',
    streamType: StreamType.youtube,
    category: ContentCategory.sample,
  );

  const camYoutube = Camera(
    id: 'yt-1',
    name: 'City Live',
    streamUrl: 'https://www.youtube.com/watch?v=abc123',
    country: 'Ireland',
    city: 'Dublin',
    streamType: StreamType.youtube,
    category: ContentCategory.skyline,
  );

  test('filters sample category always', () {
    final out = ContentFilterService().apply(
      all: [camSample, camHls],
      prefs: const UserPreferences(),
      active: const BrowseFilters(),
    );
    expect(out.map((c) => c.id), ['hls-1']);
  });

  test('respects allowHls and allowMjpeg prefs', () {
    final prefs = const UserPreferences(allowHls: false, allowMjpeg: true);
    final out = ContentFilterService().apply(
      all: [camHls, camMjpeg],
      prefs: prefs,
      active: const BrowseFilters(),
    );
    expect(out.map((c) => c.id), ['mjpeg-1']);
  });

  test('youtube allowed when both stream types disabled', () {
    final prefs = const UserPreferences(allowHls: false, allowMjpeg: false);
    final out = ContentFilterService().apply(
      all: [camYoutube, camHls],
      prefs: prefs,
      active: const BrowseFilters(),
    );
    expect(out.map((c) => c.id), ['yt-1']);
  });

  test('favoritesOnly filter', () {
    final out = ContentFilterService().apply(
      all: [camHls, camMjpeg],
      prefs: const UserPreferences(),
      active: const BrowseFilters(favoritesOnly: true),
      favoriteIds: {'mjpeg-1'},
    );
    expect(out.map((c) => c.id), ['mjpeg-1']);
  });

  test('blocklist callback', () {
    final out = ContentFilterService().apply(
      all: [camHls, camMjpeg],
      prefs: const UserPreferences(),
      active: const BrowseFilters(),
      isBlocked: (c) => c.id == 'hls-1',
    );
    expect(out.map((c) => c.id), ['mjpeg-1']);
  });

  test('search matches tags and city', () {
    final out = ContentFilterService().apply(
      all: [camHls, camMjpeg],
      prefs: const UserPreferences(),
      active: const BrowseFilters(query: 'miami'),
    );
    expect(out.map((c) => c.id), ['mjpeg-1']);
  });
}
