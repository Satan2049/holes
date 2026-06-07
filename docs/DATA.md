# Camera data — v1 bundle

Holes loads **local JSON shards** at startup (no network).

## Shards (v1 complete)

| File | Role | Enabled (approx.) |
|------|------|-------------------|
| `assets/data/cameras.json` | Main index — HTTPS HLS traffic + outdoor | ~4,678 |
| `assets/data/giraffe_cameras.json` | Zoo wildlife — HLS + YouTube only | 7 |
| `assets/data/wind_cameras.json` | Alpine wind/surf — direct HTTPS MJPEG | 27 |

**Total in app:** ~4,712 live streams (HTTPS HLS, YouTube, fast MJPEG).

Rebuild + filter:

```bash
node scripts/build-v1-dataset.mjs    # import, merge, then auto-filters
# or filter existing data only:
node scripts/filter-live-only.mjs
```

Then **full restart** the app (not hot reload).

## v1 sources (main shard)

| Source | Content |
|--------|---------|
| OpenTrafficCamMap | US traffic HLS (HTTPS, pruned) |
| Live-Environment-Streams | Global DOT HLS, outdoor, YouTube |
| seeallthethings | SCDOT HLS + DC TrafficLand MJPEG |
| ValThorensWebcams | French ski resort cams |
| webcam_app | VIU hydromet wilderness cams (BC) |

Experimental shards: **giraffe-webcams**, **windspotter**.

## Categories

| `category` | Use |
|------------|-----|
| `traffic` | Road / DOT cameras |
| `outdoor` | Nature, ski, hydromet, wildlife (HLS) |
| `skyline` | Urban / city views |
| `sample` | Embeds, demos, experimental |
| `indoor` | Interior (often blocked in onboarding) |
| `other` | Unclassified |

## Stream types

| `streamType` | Player |
|--------------|--------|
| `hls` | `video_player` (best on Android) |
| `mjpeg` | `Image.network` refresh |
| `youtube` | YouTube embed player |
| `embed` | WebView / external page |
| `auto` | Inferred from URL |

## JSON schema (per camera)

```json
{
  "id": "unique-stable-id",
  "name": "Human-readable title",
  "streamUrl": "https://....m3u8",
  "country": "United States",
  "city": "City, State",
  "category": "traffic",
  "streamType": "hls",
  "latitude": 38.8,
  "longitude": -77.5,
  "tags": ["les", "vdot"],
  "updateRateMs": 5000,
  "attribution": "Virginia DOT via Live-Environment-Streams",
  "enabled": true
}
```

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/build-v1-dataset.mjs` | **Rebuild v1** from temp imports + shards |
| `scripts/convert_otc.mjs` | OTC USA.json → cameras (standalone) |
| `scripts/filter-live-only.mjs` | **Keep decent live streams + dedupe all shards** |
| `scripts/prune-cameras.mjs` | Simple HLS/HTTPS/max filter (single file) |
| `scripts/convert-windspotter.mjs` | Windspotter Scala → wind_cameras.json |
| `scripts/import-shared.mjs` | Shared import helpers |

### Prune only (no new URLs)

```bash
node scripts/prune-cameras.mjs --hls-only --https-only
```

## Sort order

Cameras are sorted at build time and on load:

**country → city → category → name**

## Ethics

Only **documented public** streams you may link.
