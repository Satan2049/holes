# Holes

Live **public camera browser** for Android and web — search, filter, favorites, random skip. No map. No remote catalog fetch at startup.

[![CI](https://github.com/Satan2049/holes/actions/workflows/ci.yml/badge.svg)](https://github.com/Satan2049/holes/actions/workflows/ci.yml)

## Features

- **~4,700** bundled HTTPS live streams (HLS, YouTube, MJPEG)
- Search by name, city, country, tags
- Filters: country, category, stream type, favorites
- Random next / previous, skip & hide bad feeds, blocklist
- Stream health badge, fullscreen, open in browser
- Onboarding: choose HLS/MJPEG, block categories
- Remembers last camera and favorites locally

## Screenshots

_Add screenshots after first release._

## Quick start

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable)
- Android SDK for device builds

### Run (development)

```bash
flutter pub get
flutter run                  # Android — recommended for HLS video
flutter run -d chrome        # Web — landing page + app (HLS limited in Chrome)
```

### GitHub Pages (project homepage)

The **landing page** is a static site in **`docs/index.html`** — it explains the project and links to the APK. It is **not** the Flutter app.

1. Replace `YOUR_USERNAME` in `docs/index.html` with your GitHub username.
2. Create a release and attach `app-release.apk` (from `flutter build apk --release`).
3. On GitHub: **Settings → Pages → Build from branch `main` → folder `/docs`**.
4. Your site will be at `https://YOUR_USERNAME.github.io/holes/`

| What | Where | Purpose |
|------|--------|---------|
| **GitHub Pages site** | `docs/index.html` | Public homepage — download APK, read about the app |
| **Flutter web app** | `web/index.html` → `build/web/` | Optional; HLS mostly broken in Chrome anyway |
| **Android app** | `app-release.apk` | What users actually install and use |

**After changing `assets/data/*.json`:** stop the app and full restart (not hot reload).

### Install release APK (no dev machine)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

Copy to your phone and install. On Xiaomi/MIUI, enable **Install via USB** in Developer options if sideloading fails.

## App icon & splash

Icon: `assets/icon/app_icon.png` (1024×1024). Regenerate:

```bash
python scripts/generate_app_icon.py   # optional: redraw from script
dart run flutter_launcher_icons
```

Native splash is pre-generated under `android/app/src/main/res/`. To regenerate, see [docs/instructions.md](docs/instructions.md).

## Data

| File | Role |
|------|------|
| `assets/data/cameras.json` | Main index (~4,678 streams) |
| `assets/data/giraffe_cameras.json` | Wildlife shard (optional) |
| `assets/data/wind_cameras.json` | Wind/outdoor shard (optional) |
| `assets/data/blocklist.json` | Bundled URL/id blocklist |

Rebuild dataset:

```bash
node scripts/build-v1-dataset.mjs
```

See [docs/DATA.md](docs/DATA.md) and [AGENT.md](AGENT.md).

## Android build notes (restricted networks)

If Google Maven (`dl.google.com`) is blocked, this project uses Aliyun mirrors via `android/init.gradle` and `gradlew.bat`. See [docs/instructions.md](docs/instructions.md).

## Ethics

Only **documented public** streams you may link. Use feeds for observation only — respect privacy, property, and local laws.

## Docs

- [docs/README.md](docs/README.md) — documentation index
- [docs/instructions.md](docs/instructions.md) — developer setup
- [docs/improvement.md](docs/improvement.md) — improvement backlog
- [CONTRIBUTING.md](CONTRIBUTING.md)

## License

MIT — see [LICENSE](LICENSE). Camera stream rights remain with their respective owners; this app only links to public URLs documented in the dataset.
