# Data storage — Holes

## No SQL database

Holes uses bundled assets + `shared_preferences` only.

## Primary stores (v1 complete)

| Asset | ~Enabled |
|-------|----------|
| `assets/data/cameras.json` | 5,930 |
| `assets/data/giraffe_cameras.json` | 14 |
| `assets/data/wind_cameras.json` | 45 |

Loaded via `CameraDataService.loadAll()` from registered `pubspec.yaml` assets. Rebuild: `node scripts/build-v1-dataset.mjs`.

### Root shape

```json
{
  "version": 1,
  "cameras": [ /* Camera[] */ ]
}
```

### Camera fields

See [DATA.md](../DATA.md). Optional `enabled: false` soft-deletes without removing row.

### Planned: `assets/data/blocklist.json`

```json
{
  "version": 1,
  "urls": ["https://..."],
  "ids": ["otc-..."],
  "reasons": { "id": "note" }
}
```

## User persistence: `shared_preferences`

| Key area | Stored today | Planned |
|----------|--------------|---------|
| Onboarding complete | yes | — |
| Stream type toggles | yes | HLS-default on Android |
| Blocked categories | yes | — |
| Autoplay / preload | yes | — |
| Last camera id | no | yes |
| Favorite ids | no | yes |
| User blocklist ids | no | yes |

## Future (if list grows)

| Store | Use case |
|-------|----------|
| Sharded JSON | `assets/data/cameras/*.json` by region |
| Isolate parse | `compute()` for large single file |
| SQLite | Only if tens of thousands + search index needed |

## Migrations

Bump `version` in JSON when schema changes. Handle in `CameraDataService` with clear error if unsupported version.
