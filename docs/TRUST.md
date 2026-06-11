# Trust & release verification

Holes publishes pre-built release artifacts on [GitHub Releases](https://github.com/Satan2049/holes/releases). Because Android APKs are sideloaded outside the Play Store, you should verify every download before installing.

This guide explains how to check **SHA256 checksums** and optionally scan files with **VirusTotal**.

---

## Why verify?

- Confirms the file you downloaded matches what the project published
- Detects accidental corruption during transfer
- Adds an independent malware scan layer (VirusTotal)

Verification does **not** replace reading the [source code](https://github.com/Satan2049/holes) or building the APK yourself — but it is a practical baseline for release users.

---

## Published checksums

Official hashes live in the repository root:

**[SHA256.txt](../SHA256.txt)**

Each line follows the standard format:

```
<lowercase-sha256-hex>  <filename>
```

Example (Holes v1.0.0 `app-release.apk`):

```
9ec0d369aca28e0b981c453a9c08f18094cba762ce437aba1945d3e176983fe5  app-release.apk
```

Maintainers regenerate this file with:

```powershell
.\scripts\generate-sha256.ps1
```

---

## Verify SHA256 on your machine

Download the release asset from GitHub, then compute its hash locally and compare.

### Windows (PowerShell)

```powershell
Get-FileHash -Path .\app-release.apk -Algorithm SHA256
```

The `Hash` value (case-insensitive) must match the line in `SHA256.txt` for that filename.

One-liner check against the published hash:

```powershell
$expected = "9ec0d369aca28e0b981c453a9c08f18094cba762ce437aba1945d3e176983fe5"
$actual = (Get-FileHash -Path .\app-release.apk -Algorithm SHA256).Hash.ToLower()
if ($actual -eq $expected) { "OK — hash matches" } else { "MISMATCH — do not install" }
```

### macOS / Linux

```bash
shasum -a 256 app-release.apk
# or
sha256sum app-release.apk
```

Compare the output with `SHA256.txt`.

### certutil (Windows, alternative)

```cmd
certutil -hashfile app-release.apk SHA256
```

---

## Scan with VirusTotal

[VirusTotal](https://www.virustotal.com) aggregates scans from many antivirus engines. It is useful as a **second opinion**, not a guarantee of safety.

### Option A — Look up a known release

The v1.0.0 release APK has been submitted and shows **no malicious detections**:

**https://www.virustotal.com/gui/file/9ec0d369aca28e0b981c453a9c08f18094cba762ce437aba1945d3e176983fe5?nocache=1**

If your file's SHA256 matches the one above, you are looking at the same binary VirusTotal analyzed.

### Option B — Upload or search yourself

1. Go to [virustotal.com](https://www.virustotal.com).
2. Click **Search** and paste your file's SHA256 hash, **or** upload the APK directly.
3. Review the detection ratio and community comments.
4. Prefer files whose hash matches [SHA256.txt](../SHA256.txt) **and** show a clean or expected scan profile.

**Note:** New or uncommon files may trigger false positives on one or two engines. A hash match to the official release plus a stable VirusTotal report is stronger than either check alone.

---

## Build from source (maximum trust)

If you prefer not to trust pre-built binaries:

```bash
git clone https://github.com/Satan2049/holes.git
cd holes
flutter pub get
flutter build apk --release
```

Your APK will be at `build/app/outputs/flutter-apk/app-release.apk`. You can hash it yourself; it will differ from release builds signed with the maintainer's key unless you use the same signing configuration.

---

## For maintainers

When cutting a release:

1. Build artifacts (`flutter build apk --release`, plus any `.exe` / `.zip` assets).
2. Copy files to `releases/` or pass `-IncludeBuildOutputs` to the script.
3. Run `.\scripts\generate-sha256.ps1` and commit `SHA256.txt`.
4. Attach the same files to the GitHub release.
5. Optionally upload the APK to VirusTotal and link the report in the release notes.

---

## Related

- [SHA256.txt](../SHA256.txt) — published checksums
- [SECURITY.md](../SECURITY.md) — report security issues
- [instructions.md](./instructions.md) — build from source
