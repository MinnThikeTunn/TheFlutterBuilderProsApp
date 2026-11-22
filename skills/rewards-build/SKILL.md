---
name: rewards-build
description: Autonomous integration suite for the Builder Rewards headless SDK. Automatically configures dependencies, patches native biometrics, scaffolds state management UI, and runs sandbox verification.
---

# Rewards Build Skill Suite

A deterministic, turnkey workflow guide and automation suite for integrating, testing, and deploying the headless `rewards_sdk` across Sandbox, Testnet, and Production environments.

## Autonomous Agent Instructions (Turnkey Zero-Setup Mode)

When the user asks to integrate, install, or build with Builder Rewards in a Flutter application, **the AI agent must handle the entire setup autonomously without asking the user to manually configure dependencies or native files**:

### Phase 1: Automated Dependency Resolution & Self-Download
1. Inspect the host `pubspec.yaml`:
   - If `packages/rewards_sdk` exists locally, link via `path: packages/rewards_sdk`.
   - If not yet installed, automatically run:
     ```bash
     flutter pub add "rewards_sdk@{git:{url: https://github.com/MinnThikeTunn/TheFlutterBuilderProsApp.git, ref: v0.1.0, path: packages/rewards_sdk}}"
     ```
   - (Or if published to pub.dev: `flutter pub add rewards_sdk`)
2. Alternatively, executing `.\scripts\bootstrap.ps1` (or `bootstrap.sh`) will automatically detect missing dependencies and auto-inject the Git package.
3. Run `flutter pub get`.

### Phase 2: Native Configuration & Permissions Auto-Patch
1. **Android Setup**:
   - Check `android/app/src/main/AndroidManifest.xml`: Ensure `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>` is declared.
   - Check `MainActivity`: Ensure it extends `io.flutter.embedding.android.FlutterFragmentActivity` instead of `FlutterActivity` (required for biometric authentication).
   - Check `minSdkVersion`: Ensure `minSdkVersion >= 23` in `android/app/build.gradle`.
2. **iOS Setup**:
   - Check `ios/Runner/Info.plist`: Ensure `<key>NSFaceIDUsageDescription</key>` is present with a clear prompt string.

### Phase 3: Architecture Detection & UI Scaffolding
1. Detect the project's state management library from `pubspec.yaml`:
   - **GetX**: Follow [ui-recipes.md#getx](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/references/ui-recipes.md) to generate a controller extending `BaseController` or `GetxController`.
   - **Riverpod**: Follow [ui-recipes.md#riverpod](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/references/ui-recipes.md) to generate StateNotifier / AsyncNotifier providers.
   - **Bloc**: Follow [ui-recipes.md#bloc](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/references/ui-recipes.md) to generate Events and States.
   - **Vanilla Flutter**: Generate a clean `StatefulWidget` using `ValueNotifier`.
2. Generate the Rewards view and link it to the host app navigation.

### Phase 4: Instant In-Memory Sandbox Verification
1. Run a 1-second in-memory test using `SeedableSandbox` (`package:rewards_sdk/sandbox.dart`) to confirm all 6 flows execute without network latency.
2. Report success to the user with a preview of their new Rewards screen.

---

## Core Architecture & Principles

1. **Headless Only**: `rewards_sdk` exposes pure Dart async APIs (`Future`, `Stream`), models, and error codes. No presentation, UI, or state management frameworks exist inside the SDK package.
2. **Deterministic Sandbox**: `SeedableSandbox` implements pure in-memory cryptographic and transport emulation for all 6 flows without physical networks.
3. **Fail-Closed Security**: Every public method validates state invariants, credentials, and network responses before mutating stores.

---

## Guided Stages

- [00-preflight.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/stages/00-preflight.md): Environment verification, toolchain checks, and repository branch setup.
- [01-sandbox.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/stages/01-sandbox.md): Walking through all 6 headless flows in-memory with zero network calls.
- [02-testnet.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/stages/02-testnet.md): Live Stellar Testnet integration, Friendbot funding, and authority seeding.
- [03-ui-integration.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/stages/03-ui-integration.md): Binding custom presentation layers (GetX, Bloc, Riverpod) to headless SDK APIs.
- [04-production.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/stages/04-production.md): Mainnet custody, multi-signature policies, security hardening, and production gates.

---

## Automation Scripts

- `.\scripts\bootstrap.ps1`: Automated toolchain detection, branch hygiene, and dependency resolution.
- `.\scripts\verify.ps1 -Act 1`: Comprehensive verification gate checking analysis, formatting, unit tests, sandbox verification, and harness smoke tests.
- `.\scripts\seed-testnet.ps1`: Automated Testnet keypair generation, Friendbot funding, and token distribution.

---

## Technical References

- [sdk-contract.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/references/sdk-contract.md): Complete public API reference for all 6 flows.
- [failure-codes.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/references/failure-codes.md): Exhaustive failure catalog for `WalletSdkFailureCode`.
- [native-setup.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/references/native-setup.md): Android KeyStore and iOS Keychain configuration guidelines.
- [ui-recipes.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/references/ui-recipes.md): Perplexity-inspired UI integration patterns preserving GetX and presentation layers.
- [test-plan.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/references/test-plan.md): Comprehensive step-by-step test plan and gate matrix across Acts 0 through 3.
