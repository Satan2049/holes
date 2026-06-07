# Data flow — Holes (Flutter)

## Startup

```
main()
  → HolesApp (theme)
  → RootScreen
      → PreferencesService.load()
      → if !onboardingComplete → OnboardingScreen
      → else → BrowseScreen._loadCameras()
            → CameraDataService.loadAll()  // rootBundle cameras.json
            → ContentFilterService.apply(all, prefs, filters)
            → setState(_filtered, _index)
```

No network I/O on startup.

## Browse / filter

```
User types search / opens FilterSheet / changes settings
  → BrowseFilters updated
  → ContentFilterService.apply()
  → _filtered list rebuilt
  → _index clamped
  → StreamPlayer(key: camera.id) rebuilt if camera changed
```

### Filter order (current)

1. User prefs: `blockedCategories`, `blockedTags`, `allowHls` / `allowMjpeg`
2. Browse filters: country, category, stream type, web-friendly, search query

### Planned

3. Blocklist: bundled `blocklist.json` + session blocked ids ([improvement.md](../improvement.md))

## Playback

```
StreamPlayer._initPlayer()
  → isHlsStream(url, streamType)?
      → yes: VideoPlayerController.networkUrl → play
      → no:  Timer.periodic → Image.network(mjpegRefreshUri)
```

### Error path (current)

- Web + HLS → immediate error + “Open in browser”
- Web + HTTP → error
- Initialize failure → error overlay

### Planned

- Open in browser on Android
- Stream health badge (loading / live / snapshot / error)
- MJPEG refresh cap when `updateRateMs` very large

## Preferences persistence

```
OnboardingScreen._finish() / settings save
  → UserPreferences → PreferencesService.save()
  → shared_preferences JSON
```

### Planned

- `lastCameraId` restore on launch
- `favoriteCameraIds` set
- Session / persistent blocklist ids

## Data file change

```
Edit cameras.json → stop app → flutter run (full restart)
```

Hot reload does **not** reload assets.
