---
name: rewards-build
description: Guided workflow suite for building, testing, verifying, and shipping the headless Builder Rewards SDK.
disable-model-invocation: true
---

# Rewards Build Skill Suite

A deterministic, multi-stage workflow guide and automation suite for integrating, testing, and deploying the headless `rewards_sdk` across Sandbox, Testnet, and Production environments.

## Architecture & Principles

1. **Headless Only**: `rewards_sdk` exposes pure Dart async APIs (`Future`, `Stream`), models, and error codes. No presentation, UI, or state management frameworks (GetX, Bloc, Provider) exist inside the SDK package.
2. **Deterministic Sandbox**: `SeedableSandbox` implements pure in-memory cryptographic and transport emulation for all 6 flows without physical networks.
3. **Fail-Closed Security**: Every public method validates state invariants, credentials, and network responses before mutating stores.

## Guided Stages

- [00-preflight.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/stages/00-preflight.md): Environment verification, toolchain checks, and repository branch setup.
- [01-sandbox.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/stages/01-sandbox.md): Walking through all 6 headless flows in-memory with zero network calls.
- [02-testnet.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/stages/02-testnet.md): Live Stellar Testnet integration, Friendbot funding, and authority seeding.
- [03-production.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/stages/03-production.md): Mainnet custody, multi-signature policies, security hardening, and production gates.

## Automation Scripts

- `.\scripts\bootstrap.ps1`: Automated toolchain detection, branch hygiene, and dependency resolution.
- `.\scripts\verify.ps1 -Act 1`: Comprehensive verification gate checking analysis, formatting, unit tests, sandbox verification, and harness smoke tests.
- `.\scripts\seed-testnet.ps1`: Automated Testnet keypair generation, Friendbot funding, and token distribution.

## Technical References

- [sdk-contract.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/references/sdk-contract.md): Complete public API reference for all 6 flows.
- [failure-codes.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/references/failure-codes.md): Exhaustive failure catalog for `WalletSdkFailureCode`.
- [native-setup.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/references/native-setup.md): Android KeyStore and iOS Keychain configuration guidelines.
- [ui-recipes.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/references/ui-recipes.md): Perplexity-inspired UI integration patterns preserving GetX and presentation layers.
