# Core logic — Holes (Flutter)

## Stream detection (`lib/utils/stream_utils.dart`)

| Condition | Player |
|-----------|--------|
| `streamType == hls` or URL contains `.m3u8` | `VideoPlayerController` |
| `streamType == mjpeg` or default | `Image.network` + periodic cache-bust |

`mjpegRefreshUri(url, tick)` appends query param to force reload.

### MJPEG refresh (current)

```dart
final ms = cam.updateRateMs ?? 1500;
final interval = Duration(milliseconds: ms < 800 ? 800 : ms);
```

### Planned

Cap max interval (~10s) when upstream `updateRateMs` is minutes/hours — see [improvement.md](../improvement.md) §3.1.

## Content filtering (`lib/services/content_filter_service.dart`)

**Prefs gate** (`_allowedByPrefs`):

- Always hide `sample` category (removed from dataset and UX)
- Drop `blockedCategories` and `blockedTags`
- Require `allowHls` / `allowMjpeg` per stream type

**Browse gate** (`_matchesBrowseFilters`):

- Country, category, stream type, `webFriendlyOnly` (web)
- Case-insensitive substring search on name, city, country, tags

## Random next (`browse_screen.dart`)

Picks random index ≠ current when `filtered.length > 1`. Previous remains sequential.

## Platform playback (`lib/utils/platform_playback.dart`)

- `isWeb` → HLS unsupported in `video_player` on Chrome
- `isWebFriendly` → HTTPS + non-HLS (for web auto-filter)
- `errorHint` / `webWarning` → user-facing copy

## Theme (`lib/theme/app_theme.dart`)

Black background, blue primary/accent, white primary text. Legacy color names (`neonCyan`, `void950`) alias to new tokens for gradual migration.

## Planned core logic

| Feature | Location |
|---------|----------|
| Blocklist merge | `BlocklistService` + filter pipeline |
| Favorites filter | `FavoritesService` + `BrowseFilters.favoritesOnly` |
| Last camera restore | `PreferencesService` + browse init |
| Health state machine | `StreamPlayer` → badge widget |
