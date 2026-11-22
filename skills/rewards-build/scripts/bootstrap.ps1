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

if (Test-Path "$RepoRoot\packages\rewards_sdk") {
    Write-Host "  -> Found local packages/rewards_sdk" -ForegroundColor Gray
    Push-Location "$RepoRoot\packages\rewards_sdk"
    try {
        flutter pub get
    } finally {
        Pop-Location
    }
} else {
    $pubspecPath = Join-Path $RepoRoot "pubspec.yaml"
    if (Test-Path $pubspecPath) {
        $pubspecContent = Get-Content $pubspecPath -Raw
        if ($pubspecContent -notmatch "rewards_sdk") {
            Write-Host "  -> rewards_sdk not found in pubspec.yaml. Auto-installing from Git (v0.1.0)..." -ForegroundColor Cyan
            Push-Location $RepoRoot
            try {
                flutter pub add "rewards_sdk@{git:{url: https://github.com/MinnThikeTunn/TheFlutterBuilderProsApp.git, ref: v0.1.0, path: packages/rewards_sdk}}"
            } finally {
                Pop-Location
            }
        }
    }
}

if (Test-Path "$RepoRoot\templates\rewards_harness") {
    Write-Host "  -> templates/rewards_harness" -ForegroundColor Gray
    Push-Location "$RepoRoot\templates\rewards_harness"
    try {
        flutter pub get
    } finally {
        Pop-Location
    }
}

Write-Host "  -> Host application ($RepoRoot)" -ForegroundColor Gray
Push-Location $RepoRoot
try {
    flutter pub get
} finally {
    Pop-Location
}

# 4. Save Installation State
$rewardsDir = Join-Path $RepoRoot ".rewards"
if (-not (Test-Path $rewardsDir)) {
    New-Item -ItemType Directory -Path $rewardsDir -Force | Out-Null
}
$installedJson = @{
    installedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    packagePath = "packages/rewards_sdk"
    version = "0.1.0"
} | ConvertTo-Json
Set-Content -Path (Join-Path $rewardsDir "installed.json") -Value $installedJson

Write-Host "`n[BOOTSTRAP COMPLETE] All dependencies resolved and toolchains ready." -ForegroundColor Green
