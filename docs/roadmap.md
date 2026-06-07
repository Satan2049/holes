# Holes — Roadmap

## M0 — Flutter browser ✅

- Remove map; browse-only UI
- `assets/data/cameras.json` local pipeline
- Search, filters, prev / random next
- Onboarding + content settings
- OTC US import (`scripts/convert_otc.mjs`)

## M1 — Device & build ✅

- Android debug/release build (Maven mirrors, SDK workarounds)
- Web UI (limited HLS playback)
- App icon + theme polish

## M2 — Quality & UX (in progress)

See [improvement.md](./improvement.md).

| Item | Status |
|------|--------|
| Prune HLS-only dataset | Planned (DQ-1) |
| Blocklist + skip bad feed | Planned |
| MJPEG refresh cap | Planned |
| Open in browser (Android) | Planned |
| Favorites | Planned |
| Stream health badge | Planned |
| Remember last camera | Planned |
| HLS-default onboarding (Android) | Planned |

## M3 — Polish & release

- [ ] `flutter_native_splash` branded launch
- [ ] Release APK documented (`flutter build apk --release`)
- [ ] Empty states with Clear filters / Show HLS only
- [ ] Ethics note in settings
- [ ] Source attribution in camera metadata

## M4 — Scale (if list grows)

- [ ] Split `cameras.json` by region (`scripts/split-cameras.mjs`)
- [ ] Isolate JSON parse / lazy shard load
- [ ] Optional landscape fullscreen player

## M5 — Community (optional)

- [ ] CONTRIBUTING.md for `cameras.json` PRs
- [ ] CI (`flutter analyze`, `flutter test`)

## M6 — Streamers (v2, deferred)

Not in v1 — public webcams only. Planned when adding creator / IRL feeds.

| Item | Notes |
|------|--------|
| `streamers.json` shard | YouTube entries work today (`streamType: youtube`); manual JSON |
| Live-only list | Needs YouTube / Twitch API + refresh script or small backend |
| Twitch / Kick player | New `streamType` + embed WebView |
| In-app add streamer | Optional UI; catalog stays local-first |
| Broadcast from app | Separate product (RTMP/WebRTC ingest) — not planned |

Details: [improvement.md § v2 Streamers](./improvement.md#v2--streamer-feeds-deferred).

## Versioning

App version in `pubspec.yaml` (`0.2.0+1`). Bump when shipping prune, UX, or schema changes.
