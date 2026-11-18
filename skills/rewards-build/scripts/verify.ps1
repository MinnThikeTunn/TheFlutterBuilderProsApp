# Deterministic Verification Gate for Rewards Build
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [int]$Act = 1,
    [string]$RepoRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $RepoRoot = (Get-Item "$PSScriptRoot\..\..\..").FullName
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   REWARDS BUILD VERIFICATION GATE (Act $Act)            " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Root: $RepoRoot`n"

$dartExe = (Get-Command flutter).Source -replace "flutter.bat", "cache\dart-sdk\bin\dart.exe"
$failures = @()

function Run-Step([string]$name, [scriptblock]$action) {
    Write-Host "[CHECK] $name..." -NoNewline
    try {
        & $action
        Write-Host " [PASS]" -ForegroundColor Green
    } catch {
        Write-Host " [FAIL]" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        $script:failures += $name
    }
}

# 1. Formatting Check
Run-Step "Dart format validation (packages/rewards_sdk)" {
    if (Test-Path $dartExe) {
        & $dartExe format --output=none --set-exit-if-changed "$RepoRoot\packages\rewards_sdk"
    } else {
        dart format --output=none --set-exit-if-changed "$RepoRoot\packages\rewards_sdk"
    }
}

Run-Step "Dart format validation (templates/rewards_harness)" {
    if (Test-Path $dartExe) {
        & $dartExe format --output=none --set-exit-if-changed "$RepoRoot\templates\rewards_harness"
    } else {
        dart format --output=none --set-exit-if-changed "$RepoRoot\templates\rewards_harness"
    }
}

# 2. Static Analysis
Run-Step "Static analysis (packages/rewards_sdk)" {
    Push-Location "$RepoRoot\packages\rewards_sdk"
    try {
        $out = flutter analyze 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw ($out -join "`n")
        }
    } finally {
        Pop-Location
    }
}

Run-Step "Static analysis (templates/rewards_harness)" {
    Push-Location "$RepoRoot\templates\rewards_harness"
    try {
        $out = flutter analyze 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw ($out -join "`n")
        }
    } finally {
        Pop-Location
    }
}

# 3. Sandbox 6-Flow Test
Run-Step "Sandbox 6-flow headless test (<5s, 0 network calls)" {
    Push-Location "$RepoRoot\packages\rewards_sdk"
    try {
        $out = flutter test test/sandbox_test.dart 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw ($out -join "`n")
        }
    } finally {
        Pop-Location
    }
}

# 4. Full SDK Unit Test Suite
Run-Step "rewards_sdk unit test suite (all 130 tests)" {
    Push-Location "$RepoRoot\packages\rewards_sdk"
    try {
        $out = flutter test 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw ($out -join "`n")
        }
    } finally {
        Pop-Location
    }
}

# 5. Harness Smoke Test
Run-Step "templates/rewards_harness smoke test" {
    Push-Location "$RepoRoot\templates\rewards_harness"
    try {
        $out = flutter test test/smoke_test.dart 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw ($out -join "`n")
        }
    } finally {
        Pop-Location
    }
}

# 6. Host Import Boundary & Flow Compatibility
Run-Step "Host app import boundary & regression checks" {
    Push-Location $RepoRoot
    try {
        $out = flutter test test/wallet_sdk_import_boundary_test.dart test/qr_input_adapter_test.dart 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw ($out -join "`n")
        }
    } finally {
        Pop-Location
    }
}

# 7. Signed License & Hash Integrity Check
Run-Step "Signed license & LF-normalized file hash integrity check" {
    $licensePath = "$RepoRoot\packages\rewards_sdk\license.json"
    if (-not (Test-Path $licensePath)) {
        throw "license.json not found at $licensePath"
    }
    $licenseData = Get-Content $licensePath -Raw | ConvertFrom-Json
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    foreach ($entry in $licenseData.fileHashes.PSObject.Properties) {
        $filePath = Join-Path "$RepoRoot\packages\rewards_sdk" ($entry.Name -replace '/', '\')
        if (-not (Test-Path $filePath)) {
            throw "License file missing: $($entry.Name)"
        }
        $rawText = [System.IO.File]::ReadAllText($filePath)
        $normalizedText = $rawText.Replace("`r`n", "`n")
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalizedText)
        $hashBytes = $sha256.ComputeHash($bytes)
        $computedHash = [System.BitConverter]::ToString($hashBytes).Replace('-', '').ToLowerInvariant()
        if ($computedHash -ne $entry.Value.ToLowerInvariant()) {
            throw "Hash mismatch for $($entry.Name) (tampering detected)"
        }
    }
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
if ($failures.Count -eq 0) {
    Write-Host "   ALL VERIFICATION GATES PASSED! (0 errors)            " -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "   VERIFICATION FAILED: $($failures.Count) check(s) failed." -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Red
    exit 1
}
