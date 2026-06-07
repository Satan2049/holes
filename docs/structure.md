# Holes — Repository structure

```
holes/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── camera.dart
│   │   └── user_preferences.dart
│   ├── screens/
│   │   ├── root_screen.dart          # Onboarding gate
│   │   ├── browse_screen.dart        # Main UI: player + search + controls
│   │   └── onboarding_screen.dart    # First-run + settings
│   ├── services/
│   │   ├── camera_data_service.dart  # Load cameras.json
│   │   ├── content_filter_service.dart
│   │   └── preferences_service.dart
│   ├── theme/
│   │   └── app_theme.dart            # Black / blue / white theme
│   ├── utils/
│   │   ├── platform_playback.dart
│   │   └── stream_utils.dart
│   └── widgets/
│       ├── filter_sheet.dart
│       └── stream_player.dart
├── assets/
│   ├── data/
│   │   └── cameras.json              # Bundled camera index
│   └── icon/
│       ├── app_icon.png              # Master launcher icon
│       └── app_icon_source.png       # Original upload (optional)
├── android/                          # Flutter Android host + launcher icons
├── web/                              # Flutter web + generated icons
├── scripts/
│   ├── convert_otc.mjs               # OTC → cameras.json
│   ├── prune-cameras.mjs             # Shrink dataset (HLS, HTTPS, max)
│   └── setup-android-sdk.ps1         # SDK junctions when Google CDN blocked
├── docs/
│   ├── improvement.md                # Detailed improvement plan
│   ├── architecture/
│   └── ...
├── test/
├── AGENT.md                          # Agent data instructions
├── pubspec.yaml
└── README.md
```

## Stack

| Layer | Technology |
|-------|------------|
| UI | Flutter / Material 3 |
| Data | Bundled JSON (`assets/data/cameras.json`) |
| Prefs | `shared_preferences` |
| Video | `video_player` (HLS), `Image.network` (MJPEG) |
| Icons | `flutter_launcher_icons` |

## Planned additions

See [improvement.md](./improvement.md):

- `assets/data/blocklist.json`
- `lib/services/blocklist_service.dart`
- `lib/services/favorites_service.dart`
