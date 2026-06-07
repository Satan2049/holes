# Contributing to Holes

Thanks for your interest in Holes — a live public camera browser built with Flutter.

## Development setup

```bash
flutter pub get
flutter run          # Android (recommended for HLS)
flutter run -d chrome # Web UI (limited HLS playback)
```

After changing files under `assets/data/`, do a **full restart** (not hot reload).

## Code style

- Run `flutter analyze` before opening a PR.
- Keep changes focused; match existing patterns in `lib/services/` and `lib/screens/`.
- See [AGENT.md](AGENT.md) for architecture rules used in this repo.

## Camera data

- Bundled shards live in `assets/data/`.
- Rebuild pipeline: `node scripts/build-v1-dataset.mjs`
- Only add **documented public** streams you may link. See [docs/DATA.md](docs/DATA.md).

## Pull requests

1. Fork and create a branch from `main`.
2. Add or update tests when changing filter or playback logic.
3. Ensure `flutter test` and `flutter analyze` pass.
4. Describe what changed and how you tested it.

## Reporting issues

Include: device/OS, Flutter version (`flutter --version`), steps to reproduce, and whether the stream plays in an external browser.
