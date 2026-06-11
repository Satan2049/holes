# Contributing to Holes

Thanks for your interest in Holes — a live public camera browser built with Flutter.

## Development setup

```bash
flutter pub get
flutter run          # Android (recommended for HLS)
flutter run -d chrome # Web UI (limited HLS playback)
```

After changing files under `assets/data/`, do a **full restart** (not hot reload).

See [docs/instructions.md](docs/instructions.md) for Android SDK setup, icon regeneration, and network workarounds.

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
3. Ensure `flutter test` and `flutter analyze` pass locally (CI runs the same checks).
4. Describe what changed and how you tested it.

## Release checksums

When preparing a release with new binaries:

```powershell
# Place .apk / .exe / .zip in releases/, or build first:
flutter build apk --release
.\scripts\generate-sha256.ps1 -IncludeBuildOutputs
```

Commit the updated [SHA256.txt](SHA256.txt) and document verification steps in [docs/TRUST.md](docs/TRUST.md).

## Reporting issues

Include: device/OS, Flutter version (`flutter --version`), steps to reproduce, and whether the stream plays in an external browser.

Use GitHub Issues for bugs and feature requests.

## Security

Do **not** open public issues for exploitable vulnerabilities. See [SECURITY.md](SECURITY.md).

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
