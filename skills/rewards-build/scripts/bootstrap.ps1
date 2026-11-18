# Bootstrap script for rewards-build environment
[CmdletBinding()]
param(
    [string]$RepoRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = (Get-Item "$PSScriptRoot\..\..\..").FullName
}

Write-Host "=== Rewards SDK Bootstrap ===" -ForegroundColor Cyan
Write-Host "Repository root: $RepoRoot"

# 1. Verify Flutter & Dart
Write-Host "`n1. Verifying Toolchains..." -ForegroundColor Yellow
$flutterVersion = flutter --version
Write-Host ($flutterVersion -split "`n")[0]

# 2. Verify Git Branch
Write-Host "`n2. Verifying Working Branch..." -ForegroundColor Yellow
Push-Location $RepoRoot
try {
    $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
    Write-Host "Current git branch: $currentBranch"
    if ($currentBranch -ne 'feature/rewards-build') {
        Write-Warning "Recommended branch is 'feature/rewards-build'. You are on '$currentBranch'."
    }
} finally {
    Pop-Location
}

# 3. Resolve Dependencies
Write-Host "`n3. Resolving Dependencies across packages..." -ForegroundColor Yellow

Write-Host "  -> packages/rewards_sdk" -ForegroundColor Gray
Push-Location "$RepoRoot\packages\rewards_sdk"
try {
    flutter pub get
} finally {
    Pop-Location
}

Write-Host "  -> templates/rewards_harness" -ForegroundColor Gray
Push-Location "$RepoRoot\templates\rewards_harness"
try {
    flutter pub get
} finally {
    Pop-Location
}

Write-Host "  -> Root host application" -ForegroundColor Gray
Push-Location $RepoRoot
try {
    flutter pub get
} finally {
    Pop-Location
}

Write-Host "`n[BOOTSTRAP COMPLETE] All dependencies resolved and toolchains ready." -ForegroundColor Green
