# Work around blocked dl.google.com by symlinking SDK versions the build expects
# to versions already installed locally. Safe to re-run.

$sdk = $env:ANDROID_HOME
if (-not $sdk) {
    $sdk = "$env:LOCALAPPDATA\Android\Sdk"
}

function Ensure-Junction([string]$Link, [string]$Target) {
    if (Test-Path $Link) {
        Write-Host "OK: $Link"
        return
    }
    if (-not (Test-Path $Target)) {
        Write-Warning "Skip: target missing $Target"
        return
    }
    cmd /c mklink /J "$Link" "$Target" | Out-Null
    Write-Host "Linked: $Link -> $Target"
}

$buildTools = Join-Path $sdk "build-tools"
$cmake = Join-Path $sdk "cmake"
$ndk = Join-Path $sdk "ndk"

if (Test-Path (Join-Path $buildTools "36.1.0")) {
    Ensure-Junction (Join-Path $buildTools "35.0.0") (Join-Path $buildTools "36.1.0")
}
if (Test-Path (Join-Path $cmake "4.1.2")) {
    Ensure-Junction (Join-Path $cmake "3.22.1") (Join-Path $cmake "4.1.2")
}

$ndkInstalled = Get-ChildItem $ndk -Directory -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending |
    Select-Object -First 1
if ($ndkInstalled) {
    $ndkTarget = $ndkInstalled.FullName
    foreach ($version in @("27.0.12077973", "28.2.13676358")) {
        Ensure-Junction (Join-Path $ndk $version) $ndkTarget
    }
}

Write-Host "Done. SDK root: $sdk"
