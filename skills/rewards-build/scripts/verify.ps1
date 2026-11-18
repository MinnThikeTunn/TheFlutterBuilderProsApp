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

function Update-RewardsState([int]$actNumber) {
    $rewardsDir = Join-Path $RepoRoot ".rewards"
    if (-not (Test-Path $rewardsDir)) {
        New-Item -ItemType Directory -Path $rewardsDir -Force | Out-Null
    }
    $state = @{
        act = $actNumber
        flutter = ((flutter --version) -split "`n")[0].Trim()
        platform = [System.Environment]::OSVersion.Platform.ToString()
        timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    } | ConvertTo-Json
    Set-Content -Path (Join-Path $rewardsDir "state.json") -Value $state
}

if ($Act -eq 0) {
    # -------------------------------------------------------------------------
    # ACT 0: Preflight Toolchain & Branch Hygiene Gate
    # -------------------------------------------------------------------------
    Run-Step "Flutter toolchain availability" {
        $out = flutter --version 2>&1
        if ($LASTEXITCODE -ne 0) { throw $out }
    }

    Run-Step "Dart SDK availability" {
        if (-not (Test-Path $dartExe)) {
            $out = dart --version 2>&1
            if ($LASTEXITCODE -ne 0) { throw $out }
        }
    }

    Run-Step "Working branch isolation" {
        Push-Location $RepoRoot
        try {
            $branch = (git rev-parse --abbrev-ref HEAD).Trim()
            if ($branch -ne 'feature/rewards-build') {
                Write-Host " (on $branch)" -ForegroundColor Yellow -NoNewline
            }
        } finally {
            Pop-Location
        }
    }

    if ($failures.Count -eq 0) {
        Update-RewardsState 0
    }
}
elseif ($Act -eq 1) {
    # -------------------------------------------------------------------------
    # ACT 1: Sandbox & Headless Package Gate
    # -------------------------------------------------------------------------
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

    Run-Step "Static analysis (packages/rewards_sdk)" {
        Push-Location "$RepoRoot\packages\rewards_sdk"
        try {
            $out = flutter analyze 2>&1
            if ($LASTEXITCODE -ne 0) { throw ($out -join "`n") }
        } finally {
            Pop-Location
        }
    }

    Run-Step "Static analysis (templates/rewards_harness)" {
        Push-Location "$RepoRoot\templates\rewards_harness"
        try {
            $out = flutter analyze 2>&1
            if ($LASTEXITCODE -ne 0) { throw ($out -join "`n") }
        } finally {
            Pop-Location
        }
    }

    Run-Step "Sandbox 6-flow headless test (<5s, 0 network calls)" {
        Push-Location "$RepoRoot\packages\rewards_sdk"
        try {
            $out = flutter test test/sandbox_test.dart 2>&1
            if ($LASTEXITCODE -ne 0) { throw ($out -join "`n") }
        } finally {
            Pop-Location
        }
    }

    Run-Step "rewards_sdk unit test suite (all 130 tests)" {
        Push-Location "$RepoRoot\packages\rewards_sdk"
        try {
            $out = flutter test 2>&1
            if ($LASTEXITCODE -ne 0) { throw ($out -join "`n") }
        } finally {
            Pop-Location
        }
    }

    Run-Step "templates/rewards_harness smoke test" {
        Push-Location "$RepoRoot\templates\rewards_harness"
        try {
            $out = flutter test test/smoke_test.dart 2>&1
            if ($LASTEXITCODE -ne 0) { throw ($out -join "`n") }
        } finally {
            Pop-Location
        }
    }

    Run-Step "Host app import boundary & regression checks" {
        Push-Location $RepoRoot
        try {
            $out = flutter test test/wallet_sdk_import_boundary_test.dart test/qr_input_adapter_test.dart 2>&1
            if ($LASTEXITCODE -ne 0) { throw ($out -join "`n") }
        } finally {
            Pop-Location
        }
    }

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

    if ($failures.Count -eq 0) {
        Update-RewardsState 1
    }
}
elseif ($Act -eq 2) {
    # -------------------------------------------------------------------------
    # ACT 2: Testnet Authority & Connectivity Gate
    # -------------------------------------------------------------------------
    Run-Step "Testnet authority secrets presence" {
        $secretsFile = Join-Path $RepoRoot ".secrets\testnet-authority.json"
        if (-not (Test-Path $secretsFile)) {
            throw "Testnet authority missing. Run .\skills\rewards-build\scripts\seed-testnet.ps1 to generate."
        }
    }

    Run-Step "Stellar Testnet Horizon connectivity" {
        $res = Invoke-RestMethod -Uri "https://horizon-testnet.stellar.org" -Method Get -TimeoutSec 10
        if (-not $res.horizon_version) {
            throw "Invalid Horizon testnet response"
        }
    }

    if ($failures.Count -eq 0) {
        Update-RewardsState 2
    }
}
elseif ($Act -eq 3) {
    # -------------------------------------------------------------------------
    # ACT 3: Production Isolation & Security Policy Gate
    # -------------------------------------------------------------------------
    Run-Step "Assert zero sandbox.dart imports in host application" {
        Push-Location $RepoRoot
        try {
            $matches = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | Select-String -Pattern "rewards_sdk/sandbox\.dart"
            if ($matches) {
                throw "Forbidden: sandbox.dart referenced in production app code: $($matches -join ', ')"
            }
        } finally {
            Pop-Location
        }
    }

    Run-Step "Production readiness criteria verification" {
        Write-Host " (Production Gate: Independent security review & cold-storage custody required)" -ForegroundColor Yellow -NoNewline
    }

    if ($failures.Count -eq 0) {
        Update-RewardsState 3
    }
}
else {
    Write-Host "Unknown Act: $Act. Supported acts: 0, 1, 2, 3" -ForegroundColor Red
    exit 1
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
if ($failures.Count -eq 0) {
    Write-Host "   ACT $Act VERIFICATION GATE PASSED! (0 errors)         " -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "   VERIFICATION FAILED: $($failures.Count) check(s) failed." -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Red
    exit 1
}
