# Architecture overview — Holes

Client-only Flutter app. No backend. No map.

```
assets/data/cameras.json
        → CameraDataService.loadAll()
        → ContentFilterService.apply(prefs + BrowseFilters)
        → BrowseScreen
        → StreamPlayer (HLS | MJPEG)
```

User preferences (`shared_preferences`) gate stream types and blocked categories at filter time.

## Layers

| Layer | Responsibility |
|-------|----------------|
| **Screens** | UI orchestration (`root`, `browse`, `onboarding`) |
| **Services** | Data load, filter, preferences |
| **Widgets** | Player, filter sheet |
| **Models** | `Camera`, `UserPreferences` |
| **Utils** | Stream type detection, platform playback hints |

## Planned extensions

See [../improvement.md](../improvement.md):

- `BlocklistService` — bundled + session blocked ids
- `FavoritesService` — starred cameras in prefs
- Optional sharded JSON under `assets/data/cameras/`

## Platform notes

| Platform | HLS in app | MJPEG |
|----------|------------|-------|
| Android | Yes (`video_player`) | Yes (`Image.network`) |
| Web | No (Chrome limitation) | HTTPS only; auto web-friendly filter |

Discovery research uses external OSINT (documented in `docs/discovery.md`); data is imported as JSON, not live API calls.
