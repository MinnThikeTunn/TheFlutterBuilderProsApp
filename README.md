# theBuilderPros App & Rewards Capability

theBuilderPros is a high-performance Flutter mobile application and headless Rewards capability designed for Builders and App Masters.

- **Repository**: [https://github.com/MinnThikeTunn/TheFlutterBuilderProsApp](https://github.com/MinnThikeTunn/TheFlutterBuilderProsApp)
- **Primary Branch**: `feature/rewards-build` / `main`
- **Release Tag**: `v0.1.0`

---

## ⚡ Quick Start: Rewards Build Skill (Autonomous AI Agent)

The repository provides the **Rewards Build Skill**, a turnkey workflow suite that enables any AI coding assistant (Claude Code, Cursor, Windsurf, Antigravity) to automatically install, configure, and scaffold the headless Rewards SDK into any Flutter project with **zero manual setup**.

### 1. Install the Skill via `npx skills`
Install the skill directly into your AI agent environment from this repository:

```bash
npx skills add MinnThikeTunn/TheFlutterBuilderProsApp --skill rewards-build
```

### 2. Prompt Your AI Agent
Simply prompt your AI assistant:
> *"Add Builder Rewards to my Flutter app."*

The skill guides the agent to autonomously:
1. **Auto-Install SDK**: Adds `rewards_sdk` to `pubspec.yaml` and executes `flutter pub get`.
2. **Auto-Patch Native Biometrics**:
   - Injects `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>` into `AndroidManifest.xml`.
   - Switches `MainActivity` to `FlutterFragmentActivity`.
   - Adds `NSFaceIDUsageDescription` to iOS `Info.plist`.
3. **Auto-Scaffold UI & Controller**: Detects your state management architecture (**GetX**, **Riverpod**, **Bloc**, or **Vanilla Flutter**) and generates ready-to-run UI components from built-in recipes.
4. **Instant In-Memory Verification**: Boots `SeedableSandbox` and verifies all 6 core flows in `< 1.0s` with zero network calls.

---

## 📦 Direct SDK Installation (Manual)

If you prefer to integrate the headless SDK directly without the agent skill, add the Git dependency to your `pubspec.yaml`:

```yaml
dependencies:
  rewards_sdk:
    git:
      url: https://github.com/MinnThikeTunn/TheFlutterBuilderProsApp.git
      path: packages/rewards_sdk
      ref: v0.1.0
```

Then resolve dependencies:

```bash
flutter pub get
```

### Basic Usage

```dart
import 'package:rewards_sdk/rewards_sdk.dart';

// Create a production or testnet SDK instance
final WalletSdk sdk = createWalletSdk();

// 1. Check activation status
final status = await sdk.getActivationStatus();

// 2. Query available Rewards balance
final balance = await sdk.getRewardsBalance();
print('Balance: ${balance.available} ${balance.assetCode}');

// 3. Query paginated confirmed transaction history
final history = await sdk.getRewardsHistory();
```

---

## 🧪 Deterministic Sandbox & Reference Harness

The SDK includes a pure in-memory cryptographic and transport emulation layer (`SeedableSandbox`), allowing all 6 flows to run in `< 1.0 second` with zero network latency.

### Run the Reference Harness:
```powershell
cd templates/rewards_harness
.\run.ps1
```

Or run via Flutter test:
```powershell
cd templates/rewards_harness
flutter test test/smoke_test.dart
```

---

## 🚀 Live Stellar Testnet Seeding

To seed a live testnet Issuer and Distributor authority with 100,000 `REWARD` tokens:

```powershell
powershell -File .\skills\rewards-build\scripts\seed-testnet.ps1
```

The script automatically:
- Generates Ed25519 keypairs for Issuer & Distributor.
- Funds both via Friendbot with exponential retry on HTTP 429 rate limits.
- Sets up the `REWARD` asset trustline and mints 100,000 units.
- Saves credentials to strictly gitignored `.secrets/testnet-authority.json`.

---

## 🛡️ Verification Gates

Deterministic gate verification is enforced via `verify.ps1`:

```powershell
# Act 0: Preflight (Toolchain & native config checks)
powershell -File .\skills\rewards-build\scripts\verify.ps1 -Act 0

# Act 1: Sandbox & Integrity (Analysis, formatting, 130 tests, license checksums)
powershell -File .\skills\rewards-build\scripts\verify.ps1 -Act 1

# Act 3: Production Isolation (Zero sandbox imports in host app)
powershell -File .\skills\rewards-build\scripts\verify.ps1 -Act 3
```

---

## 📐 Project Structure

```text
TheFlutterBuilderProsApp/
├── packages/
│   └── rewards_sdk/                  # Standalone headless pure-Dart SDK (130 unit tests)
├── skills/
│   └── rewards-build/                # AI Agent skill suite (stages, recipes, verification scripts)
├── templates/
│   └── rewards_harness/              # Minimal standalone reference integration harness
├── lib/
│   ├── app/features/wallet/          # Builder Rewards mobile experience
│   └── app/features/app_master/      # Distributor dashboard and activation management
```
