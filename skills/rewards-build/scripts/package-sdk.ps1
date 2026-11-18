# Packaging script for Rewards SDK
[CmdletBinding()]
param(
    [string]$RepoRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = (Get-Item "$PSScriptRoot\..\..\..").FullName
}

Write-Host "=== Rewards SDK Distribution Packager ===" -ForegroundColor Cyan

# 1. Generate normalized hashes & license.json
Write-Host "`n1. Generating normalized file hashes and license.json..." -ForegroundColor Yellow
Push-Location "$RepoRoot\packages\rewards_sdk"
try {
    $dartExe = (Get-Command flutter).Source -replace "flutter.bat", "cache\dart-sdk\bin\dart.exe"
    if (Test-Path $dartExe) {
        & $dartExe run tool/package_release.dart
    } else {
        dart run tool/package_release.dart
    }
} finally {
    Pop-Location
}

# 2. Build Release Archive
Write-Host "`n2. Packaging release archive..." -ForegroundColor Yellow
$distDir = Join-Path $RepoRoot "build\dist"
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

$zipPath = Join-Path $distDir "rewards_sdk-0.1.0.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

$tempPkg = Join-Path $distDir "rewards_sdk"
if (Test-Path $tempPkg) {
    Remove-Item $tempPkg -Recurse -Force
}

New-Item -ItemType Directory -Path $tempPkg -Force | Out-Null
Copy-Item -Path "$RepoRoot\packages\rewards_sdk\lib" -Destination $tempPkg -Recurse
Copy-Item -Path "$RepoRoot\packages\rewards_sdk\pubspec.yaml" -Destination $tempPkg
Copy-Item -Path "$RepoRoot\packages\rewards_sdk\analysis_options.yaml" -Destination $tempPkg
Copy-Item -Path "$RepoRoot\packages\rewards_sdk\README.md" -Destination $tempPkg
Copy-Item -Path "$RepoRoot\packages\rewards_sdk\license.json" -Destination $tempPkg

Compress-Archive -Path "$tempPkg\*" -DestinationPath $zipPath -Force
Remove-Item $tempPkg -Recurse -Force

Write-Host "`n[SUCCESS] Packaged to: $zipPath" -ForegroundColor Green
