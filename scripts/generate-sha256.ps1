# Generate SHA256.txt for Holes release artifacts (.apk, .exe, .zip).
# Safe to re-run after placing new files in releases/ or building locally.
#
# Usage:
#   .\scripts\generate-sha256.ps1
#   .\scripts\generate-sha256.ps1 -IncludeBuildOutputs
#   .\scripts\generate-sha256.ps1 -InputDir .\releases -ReleaseUrl "https://github.com/Satan2049/holes/releases/tag/v1.1.0"

param(
    [string]$InputDir = "",
    [string]$OutputFile = "SHA256.txt",
    [string]$ReleaseUrl = "",
    [switch]$IncludeBuildOutputs
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$extensions = @(".apk", ".exe", ".zip")

function Get-ReleaseAssets {
    param([string[]]$Paths)

    $found = @()
    foreach ($path in $Paths) {
        if (-not (Test-Path $path)) {
            continue
        }
        foreach ($ext in $extensions) {
            $found += Get-ChildItem -Path $path -Filter "*$ext" -File -Recurse -ErrorAction SilentlyContinue
        }
    }
    return $found | Sort-Object FullName -Unique
}

$searchPaths = @()
if ($InputDir) {
    $resolved = Resolve-Path -Path $InputDir
    $searchPaths += $resolved.Path
} else {
    $searchPaths += Join-Path $Root "releases"
}

if ($IncludeBuildOutputs) {
    $searchPaths += @(
        (Join-Path $Root "build\app\outputs\flutter-apk"),
        (Join-Path $Root "build\app\outputs\apk\release"),
        (Join-Path $Root "build\windows\x64\runner\Release"),
        (Join-Path $Root "build\windows\runner\Release")
    )
}

$files = Get-ReleaseAssets -Paths $searchPaths

if ($files.Count -eq 0) {
    Write-Warning @"
No release assets found (.apk, .exe, .zip).

Place files in releases/ or build first, then re-run:
  flutter build apk --release
  .\scripts\generate-sha256.ps1 -IncludeBuildOutputs
"@
    exit 1
}

$lines = @()
$lines += "# SHA256 checksums for Holes release assets"
if ($ReleaseUrl) {
    $lines += "# $ReleaseUrl"
}
$lines += "# Generated: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss')) UTC"
$lines += "# Regenerate: .\scripts\generate-sha256.ps1"
$lines += "# Verify:     docs/TRUST.md"
$lines += ""

foreach ($file in $files) {
    $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash.ToLower()
    $lines += "$hash  $($file.Name)"
}

$outputPath = Join-Path $Root $OutputFile
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($outputPath, $lines, $utf8NoBom)

Write-Host "Wrote $($files.Count) hash(es) to $outputPath"
foreach ($file in $files) {
    Write-Host "  $($file.Name)"
}
