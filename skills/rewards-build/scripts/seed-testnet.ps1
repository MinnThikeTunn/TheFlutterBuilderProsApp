# Automated Testnet Seeding Script
[CmdletBinding()]
param(
    [string]$RepoRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = (Get-Item "$PSScriptRoot\..\..\..").FullName
}

Write-Host "=== Stellar Testnet Seeding Automation ===" -ForegroundColor Cyan
Write-Host "Repository root: $RepoRoot"

Push-Location "$RepoRoot\packages\rewards_sdk"
try {
    $dartExe = (Get-Command flutter).Source -replace "flutter.bat", "cache\dart-sdk\bin\dart.exe"
    if (Test-Path $dartExe) {
        & $dartExe run tool/seed_testnet.dart
    } else {
        dart run tool/seed_testnet.dart
    }

    $secretsPath = Join-Path $RepoRoot ".secrets\testnet-authority.json"
    if (Test-Path $secretsPath) {
        Write-Host "`n[SUCCESS] Authority secrets saved to: $secretsPath" -ForegroundColor Green
    } else {
        Write-Warning "Secrets file was not found at expected location: $secretsPath"
    }
} finally {
    Pop-Location
}
