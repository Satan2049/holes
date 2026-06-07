# Camera discovery — free sources (manual curation)

Holes does **not** use Shodan or live discovery APIs. Cameras are **bundled** in `assets/data/cameras.json`.

Use this guide when you want to **research and add** streams manually, then import via scripts or direct JSON edits.

## Current pipeline (in app)

| Step | Tool |
|------|------|
| Research | External sites below |
| Convert | `scripts/convert_otc.mjs` (OpenTrafficCamMap) |
| Prune | `scripts/prune-cameras.mjs` |
| Bundle | `assets/data/cameras.json` |
| Ship | Full app restart |

The app does **not** fetch remote lists on startup (removed for speed and reliability).

---

## OpenTrafficCamMap (primary US source)

Upstream: [AidanWelch/OpenTrafficCamMap](https://github.com/AidanWelch/OpenTrafficCamMap) (MIT).

| Item | Location |
|------|----------|
| Data | `OpenTrafficCamMap-master/cameras/USA.json` (~7k US traffic cams) |
| Converter | `scripts/convert_otc.mjs` |

### Format mapping

| OTC `format` | Holes `streamType` | Player |
|--------------|-------------------|--------|
| `M3U8`, `M3U9` | `hls` | `video_player` |
| `IMAGE_STREAM`, `IMAGE_STREAM_BY_EPOCH_IN_MILLISECONDS` | `mjpeg` | `Image.network` refresh |
| `UNIQUE_*` | skipped by default | Custom parsers upstream |

Cameras at `(0, 0)` are dropped.

### Convert examples

```bash
node scripts/convert_otc.mjs
node scripts/convert_otc.mjs --formats M3U8 --output assets/data/cameras.json
node scripts/convert_otc.mjs --max 300 --output assets/data/cameras.json
```

---

## Other free research tools (manual)

Use to find **public** feeds; verify terms of use before adding to JSON.

| Tool | Use |
|------|-----|
| [Insecam](http://www.insecam.org/) | Browse by country (curate carefully; many dead) |
| [EarthCam](https://www.earthcam.com/) | Commercial/public skylines — check linking policy |
| State DOT sites | Official traffic camera pages |
| GitHub search | `traffic camera json`, `opentrafficcam` forks |

**Do not** automate scraping of sites that prohibit it. Prefer official open data and projects with clear licenses.

---

## Remote feeds (not enabled)

Earlier versions used `discovery_config.json` and HTTP fetch on startup. That path was **removed**. To add community feeds in the future:

1. Download feed to JSON offline.
2. Merge into `cameras.json` or a shard file.
3. Document source in `attribution` field (planned).

---

## Quality tips when curating

1. Prefer **HLS (`.m3u8`)** over snapshot `IMAGE_STREAM`.
2. Prefer **HTTPS** URLs.
3. Drop feeds that show static images for minutes (check `updateRate` in OTC).
4. Maintain a **blocklist** of dead URLs — see [improvement.md](./improvement.md).

---

## Agent workflow

See [AGENT.md](../AGENT.md) for schema and merge rules.
