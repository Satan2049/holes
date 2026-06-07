# Agent instructions — placing camera data

The user provides camera data; **you** write it into the project. The app does **not** fetch remote lists or show a map.

## Single source of truth

**File:** `assets/data/cameras.json`

**v1 complete.** Rebuild all shards:

```bash
node scripts/build-v1-dataset.mjs
```

Main shard ~6.3k cameras (OTC + Live-Environment-Streams + seeallthethings + Val Thorens + VIU). Plus `giraffe_cameras.json` and `wind_cameras.json`.

After editing, run `flutter pub get` (if pubspec changed) and **full restart** the app (not hot reload).

## JSON schema

```json
{
  "version": 1,
  "cameras": [
    {
      "id": "unique-stable-id",
      "name": "Human-readable title",
      "streamUrl": "https://....m3u8 or image URL",
      "country": "Country",
      "city": "City or region",
      "category": "traffic | outdoor | indoor | skyline | sample | other",
      "streamType": "hls | mjpeg | auto",
      "updateRateMs": 2000,
      "tags": ["optional", "labels"],
      "enabled": true
    }
  ]
}
```

| Field | Required | Notes |
|-------|----------|--------|
| `id` | yes | Unique; used for player key |
| `streamUrl` | yes | HLS `.m3u8` or MJPEG/snapshot URL |
| `country`, `city` | yes | Search + filters |
| `category` | no | Content filter (`sample` hidden if user enabled hide samples) |
| `streamType` | no | `hls` / `mjpeg` / `auto` |
| `updateRateMs` | no | MJPEG refresh interval |
| `enabled` | no | `false` drops entry without deleting |
| `latitude`, `longitude` | no | Optional metadata only (no map) |

## Converting external data

- **Full v1 rebuild:** `node scripts/build-v1-dataset.mjs` (OTC + LES + seeallthethings + Val Thorens + VIU)
- **OTC only:** `node scripts/convert_otc.mjs --output assets/data/cameras.json`
- **Prune:** `node scripts/prune-cameras.mjs --hls-only --https-only`
- **Windspotter shard:** `node scripts/convert-windspotter.mjs`

### Optional attribution fields (planned UI)

| Field | Example |
|-------|---------|
| `source` | `"OpenTrafficCamMap"` |
| `sourceUrl` | `"https://github.com/AidanWelch/OpenTrafficCamMap"` |
| `attribution` | `"Alabama DOT via OTC"` |

### Blocklist (planned)

`assets/data/blocklist.json` — ids/urls to exclude. See `docs/improvement.md` §1.2.

## Do not

- Re-enable map or remote `openTrafficCam` feeds without user request
- Add thousands of cameras without user asking (performance)
- Include private or unauthorized streams

## App behavior (for context)

- First launch: onboarding (stream types, blocked categories)
- Main UI: one live stream, search, filters, previous / random next
- Only **one** stream decoded at a time

## Docs

| Doc | Purpose |
|-----|---------|
| `docs/DATA.md` | Schema, prune scripts |
| `docs/improvement.md` | Feature plan (no new cameras) |
| `docs/todo.md` | Short task checklist |
