# Modules — Holes (Flutter)

| Module | Role |
|--------|------|
| `lib/main.dart` | App entry, `MaterialApp`, theme |
| `lib/screens/root_screen.dart` | Onboarding complete? → browse or setup |
| `lib/screens/browse_screen.dart` | Search, filters, player, prev/random next |
| `lib/screens/onboarding_screen.dart` | First-run + content settings |
| `lib/widgets/stream_player.dart` | HLS (`video_player`) / MJPEG (`Image.network`) |
| `lib/widgets/filter_sheet.dart` | Country, category, stream type filters |
| `lib/services/camera_data_service.dart` | Parse `assets/data/cameras.json` |
| `lib/services/content_filter_service.dart` | Prefs + browse filters + search |
| `lib/services/preferences_service.dart` | `shared_preferences` read/write |
| `lib/models/camera.dart` | Camera model, categories, stream types |
| `lib/models/user_preferences.dart` | Onboarding choices |
| `lib/theme/app_theme.dart` | Black / blue / white `ThemeData` |
| `lib/utils/stream_utils.dart` | HLS detection, MJPEG cache-bust URI |
| `lib/utils/platform_playback.dart` | Web warnings, HTTPS checks |

## Planned modules

| Module | Role |
|--------|------|
| `lib/services/blocklist_service.dart` | Dead URL / id blocklist |
| `lib/services/favorites_service.dart` | Starred camera ids |

## Scripts (not Dart modules)

| Script | Role |
|--------|------|
| `scripts/convert_otc.mjs` | OTC → `cameras.json` |
| `scripts/prune-cameras.mjs` | Shrink dataset |
| `scripts/setup-android-sdk.ps1` | Android SDK junctions |
