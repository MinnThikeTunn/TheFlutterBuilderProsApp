# Stage 00: Preflight & Environment Setup

This stage establishes repository hygiene, toolchain verification, and isolated branch setup for the Builder Rewards build.

## Prerequisites

- **Flutter SDK**: `>=3.24.0` (Stable channel).
- **Dart SDK**: `^3.5.0` (Included with Flutter).
- **Git**: Working tree clean or isolated to feature development.
- **PowerShell**: ExecutionPolicy configured to allow script execution.

## Step 1: Branch Isolation

Create or checkout your dedicated working branch:

```powershell
git checkout -b feature/rewards-build
```

Verify that you are on the correct branch:

```powershell
git rev-parse --abbrev-ref HEAD
```

## Step 2: Bootstrap Toolchains and Dependencies

Run the automated bootstrap script from the repository root:

```powershell
.\skills\rewards-build\scripts\bootstrap.ps1
```

This script verifies:
1. Flutter and Dart installation.
2. Active git branch name.
3. Dependencies resolution across `packages/rewards_sdk`, `templates/rewards_harness`, and the host app.

## Step 3: Architecture Boundaries

Remember the headless rules:
- `packages/rewards_sdk/` must contain zero UI, GetX, or Bloc imports.
- Presentation code in `lib/` interacts solely through `rewards_sdk.dart` models and public interfaces.
- `sandbox.dart` is strictly for tests and local emulation; it is never exported by `rewards_sdk.dart`.
