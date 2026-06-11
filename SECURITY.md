# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | Yes       |
| < 1.0   | No        |

## Reporting a vulnerability

If you discover a security issue in **Holes** (the app, its build pipeline, or this repository), please report it responsibly.

**Do not** open a public GitHub issue for exploitable vulnerabilities.

Instead:

1. Open a **[GitHub Security Advisory](https://github.com/Satan2049/holes/security/advisories/new)** (preferred), or
2. Email the maintainers via the contact method listed on the repository profile.

Include:

- A clear description of the issue and its impact
- Steps to reproduce (proof-of-concept if available)
- Affected version(s) and platform(s)
- Any suggested fix or mitigation

We aim to acknowledge reports within **7 days** and will coordinate disclosure once a fix is available.

## Release integrity

Users installing pre-built APKs should verify downloads before installing:

- Compare SHA256 checksums against [SHA256.txt](SHA256.txt)
- Follow [docs/TRUST.md](docs/TRUST.md) for step-by-step verification and optional VirusTotal scanning

## Scope

**In scope**

- The Holes Android app and its bundled assets
- Build scripts and CI configuration in this repository
- Privacy or data-handling issues in local storage (`shared_preferences`)

**Out of scope**

- Security of third-party camera stream hosts (the app links to external public URLs)
- Social engineering or physical device access
- Issues in upstream Flutter/Dart dependencies (report those to the respective projects)

## Safe use

Holes links to **public** live streams documented in the dataset. Do not use the app to access private, unauthorized, or protected feeds. Report problematic URLs via issues so they can be removed from the blocklist or dataset.
