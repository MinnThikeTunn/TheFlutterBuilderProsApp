param(
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    Write-Host "Running Rewards Reference Harness (all 6 headless flows)..." -ForegroundColor Cyan
    if ($Verbose) {
        flutter test test/smoke_test.dart -r expanded
    } else {
        flutter test test/smoke_test.dart
    }
} finally {
    Pop-Location
}
