# Holes — Developer instructions

## What it is

Live **public camera browser** — no map. Bundled data shards under `assets/data/` (v1 complete).

- One stream at a time
- Search, filters, previous / random next
- Onboarding for stream types and blocked categories

## Prerequisites

- Flutter SDK (stable)
- Android SDK for device builds
- Node.js (optional, for `scripts/`)

## Run

```bash
flutter pub get
flutter run                  # Android — recommended for HLS video
flutter run -d chrome        # Web UI — most HLS will not play in Chrome
```

**After changing `cameras.json`:** stop app and full restart (not hot reload).

## App icon

1. Edit `assets/icon/app_icon.png` (1024×1024 PNG).
2. Regenerate:

```bash
dart run flutter_launcher_icons
```

## Native splash

Splash images are already generated under `android/app/src/main/res/`. The
`flutter_native_splash` **config** stays in `pubspec.yaml`; the **package** is
not kept as a dependency (its Android plugin breaks builds when Google Maven is
blocked).

To regenerate after changing the icon:

```bash
flutter pub add --dev flutter_native_splash
dart run flutter_native_splash:create
flutter pub remove flutter_native_splash
```

Then full restart the app.

## Release APK (no terminal for daily use)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Copy to phone and install. Debug builds from `flutter run` require a connected dev session; release APK does not.

## Data pipeline

| Task | Command |
|------|---------|
| **Rebuild v1 dataset** | `node scripts/build-v1-dataset.mjs` |
| Import OTC only | `node scripts/convert_otc.mjs` |
| Prune to live video | `node scripts/prune-cameras.mjs --hls-only --https-only` |

See [DATA.md](./DATA.md) and [AGENT.md](../AGENT.md).

## Android: blocked Google CDN

If Gradle cannot resolve `com.android.application` or Flutter engine downloads fail:

1. Project includes Maven mirrors in `android/init.gradle` and `gradlew`.
2. Run once: `.\scripts\setup-android-sdk.ps1` (SDK junctions for build-tools / cmake / ndk).
3. Optional user env vars:

```powershell
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
```

## Architecture entry points

| Path | Role |
|------|------|
| `lib/main.dart` | App entry, theme |
| `lib/screens/root_screen.dart` | Onboarding vs browse |
| `lib/screens/browse_screen.dart` | Player + search + controls |
| `lib/services/camera_data_service.dart` | Load JSON |
| `lib/services/content_filter_service.dart` | Search + filters + prefs |
| `lib/services/preferences_service.dart` | Saved user choices |
| `lib/widgets/stream_player.dart` | HLS / MJPEG playback |

Full map: [architecture/codebase-map.md](./architecture/codebase-map.md).

## Performance rules

- No network on startup (local JSON only)
- One `VideoPlayer` at a time (`ValueKey` per camera id)
- Optional preload off by default
- Keep `cameras.json` as small as practical; see [improvement.md](./improvement.md)

## What to build next

See **[improvement.md](./improvement.md)** and [todo.md](./todo.md).
