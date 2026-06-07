# Dependencies — Holes (Flutter)

## Runtime (`pubspec.yaml`)

| Package | Purpose |
|---------|---------|
| `flutter` | UI framework |
| `video_player` | HLS playback (Android, iOS; limited web) |
| `youtube_player_iframe` | Zoo YouTube live cams in-app |
| `webview_flutter` | Zoo embed players (EarthCam, HDOnTap, etc.) |
| `shared_preferences` | Onboarding + user prefs |
| `url_launcher` | Open stream URL in external browser (fallback) |

## Dev

| Package | Purpose |
|---------|---------|
| `flutter_test` | Widget tests |
| `flutter_lints` | Analysis rules |
| `flutter_launcher_icons` | Generate Android/web launcher icons from `assets/icon/app_icon.png` |

## Planned dev

| Package | Purpose |
|---------|---------|
| `flutter_native_splash` | Branded launch screen (improvement plan §5.1) |

## Removed (do not re-add without user request)

| Package | Was used for |
|---------|----------------|
| `flutter_map` | OSM map (removed — lag) |
| `latlong2` | Map coordinates |
| `http` | Remote camera fetch on startup |
| `google_maps_flutter` | Earlier scaffold |

## External services

None at runtime. Optional build-time / dev:

- Aliyun Maven mirror (Android Gradle, when `dl.google.com` blocked)
- `storage.flutter-io.cn` (Flutter engine artifacts mirror via `gradlew`)

No Shodan, no Google Maps API.
