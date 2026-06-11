# Holes — Task backlog

Full improvement plan: **[improvement.md](./improvement.md)**

## Done

- [x] v1 camera dataset — `node scripts/build-v1-dataset.mjs`
  - OTC + Live-Environment-Streams + seeallthethings + Val Thorens + VIU
  - Giraffe + wind shards categorized and fixed
  - ~4,712 live streams after `filter-live-only.mjs`
- [x] Browse-only app (search, filter, prev/random next)
- [x] Android build + theme + app icon
- [x] Import scripts: `build-v1-dataset.mjs`, `import-shared.mjs`, `prune-cameras.mjs`
- [x] Blocklist JSON + skip & hide bad feed (session + undo)
- [x] Favorites (star + filter)
- [x] Stream health badge on player
- [x] Remember last camera
- [x] MJPEG refresh cap (~10s max)
- [x] Open in browser + fullscreen controls
- [x] HLS-only default on Android + empty-state actions
- [x] Ethics note + attribution fields in UI
- [x] JSON parse in isolate for large shards
- [x] Native splash (generated assets; package not kept as dependency)
- [x] Release APK documented (`flutter build apk --release`)
- [x] GitHub release prep (README, LICENSE, CI, CONTRIBUTING, unit tests)

## v2 — Streamers (deferred)

See [improvement.md § v2 Streamers](./improvement.md#v2--streamer-feeds-deferred).

- [ ] `streamers.json` shard — YouTube IRL / streamer channels (static URLs)
- [ ] Live-only filter — YouTube Data API + Twitch Helix (`isLive` / refresh script)
- [ ] `streamType: twitch` — Twitch embed player (like YouTube)
- [ ] Kick / other platforms — embed or HLS where allowed
- [ ] In-app “add streamer” UI (optional; today = edit JSON + rebuild)
- [ ] In-app broadcasting — out of scope unless product pivots

## Data (v2+)

- [ ] Curate blocklist from browsing dead feeds
- [ ] Split main JSON by region if cold start slows
