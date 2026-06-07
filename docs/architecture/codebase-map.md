# Codebase map — Holes (Flutter)

## Entry points

| Entry | Path |
|-------|------|
| `main()` | `lib/main.dart` |
| First screen | `lib/screens/root_screen.dart` |
| Main UI | `lib/screens/browse_screen.dart` |

## Critical paths

| Concern | Path |
|---------|------|
| Load cameras | `lib/services/camera_data_service.dart` |
| Filter + search | `lib/services/content_filter_service.dart` |
| User prefs | `lib/services/preferences_service.dart` |
| Playback | `lib/widgets/stream_player.dart` |
| Filters UI | `lib/widgets/filter_sheet.dart` |
| Theme | `lib/theme/app_theme.dart` |
| Data file | `assets/data/cameras.json` |
| Prune script | `scripts/prune-cameras.mjs` |

## Trace: app launch → first stream

```
main()
  → RootScreen
  → (onboarding?) OnboardingScreen → BrowseScreen
  → CameraDataService.loadAll()
  → ContentFilterService.apply()
  → StreamPlayer(camera, autoplay: prefs.autoplayStreams)
  → HLS: VideoPlayerController.initialize()
     MJPEG: Timer + Image.network
```

## Trace: random next

```
IconButton shuffle → _next()
  → Random index ≠ _index
  → setState(_index)
  → StreamPlayer new ValueKey(camera.id)
  → _disposePlayer() + _initPlayer()
```

## Trace: filter change

```
FilterSheet Apply → BrowseFilters
  → _applyFilters()
  → ContentFilterService.apply()
  → rebuild list + clamp index
```

## Documentation map

| Doc | Purpose |
|-----|---------|
| [improvement.md](../improvement.md) | What to build next (detailed) |
| [todo.md](../todo.md) | Short checklist |
| [DATA.md](../DATA.md) | JSON schema + scripts |
| [instructions.md](../instructions.md) | Run / build |

## Planned paths (not yet in repo)

- `lib/services/blocklist_service.dart`
- `lib/services/favorites_service.dart`
- `assets/data/blocklist.json`
