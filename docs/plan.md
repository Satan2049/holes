# Holes — Project Plan

## Vision

Open-source **live public camera browser** — search, filter, skip. One stream at a time. **No map.** No remote feeds on startup.

Users (or agents) maintain a bundled `assets/data/cameras.json`. The app loads it locally, applies content preferences, and plays HLS or MJPEG streams.

## Principles

- **Local-first data** — bundled JSON; full restart after data changes
- **User control** — onboarding blocks categories/stream types; filters for country/category
- **Platform honesty** — web cannot play most HLS; Android recommended for live video
- **Public streams only** — documented feeds you may link; no unauthorized surveillance
- **Performance** — one player at a time; optional preload off by default; prune large lists

## Stack

| Layer | Technology |
|-------|------------|
| UI | Flutter / Material 3 |
| Theme | Black / blue / white (`lib/theme/app_theme.dart`) |
| Data | `assets/data/cameras.json` (+ planned `blocklist.json`) |
| Prefs | `shared_preferences` |
| Video | `video_player` (HLS), `Image.network` (MJPEG) |
| External | `url_launcher` (open stream in browser) |

## Removed (by design)

| Removed | Reason |
|---------|--------|
| Google Maps / `flutter_map` | Lag; map not core to browsing |
| Remote OTC fetch on startup | Slow/unreliable; bundled JSON instead |
| `discovery_config.json` | Replaced by local data pipeline |
| Shodan | Ethics + cost; manual curation only |

## Current focus

See **[improvement.md](./improvement.md)** — data quality (HLS prune, blocklist), browsing UX (favorites, skip bad feed), playback polish, release APK.
