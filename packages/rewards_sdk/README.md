# Rewards SDK

Headless Flutter capability for the BuilderPros Rewards Wallet.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  rewards_sdk:
    git:
      url: https://github.com/MinnThikeTunn/TheFlutterBuilderProsApp.git
      path: packages/rewards_sdk
      ref: v0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:rewards_sdk/rewards_sdk.dart';

// Create SDK instance
final WalletSdk sdk = createWalletSdk();

// Check status
final status = await sdk.getActivationStatus();

// Query balance
final balance = await sdk.getRewardsBalance();
print('Rewards: ${balance.available} ${balance.assetCode}');
```

## In-Memory Testing Sandbox

For unit or widget testing without physical network calls:

```dart
import 'package:rewards_sdk/rewards_sdk.dart';
import 'package:rewards_sdk/sandbox.dart';

void main() async {
  final sandbox = SeedableSandbox(seed: 'test-seed');
  final sdk = sandbox.createWalletSdk();
  
  // Executes all 6 flows in memory in < 1 second
}
```

## AI Agent Skills

This package comes with a turnkey AI agent skill suite in `skills/` (`rewards-build` and `ask-rewards`). Install all skills together via `npx skills`:

```bash
# Interactive: discovers and installs all skills in the repo
npx skills add MinnThikeTunn/TheFlutterBuilderProsApp

# Or non-interactive (all skills across all detected agents)
npx skills add MinnThikeTunn/TheFlutterBuilderProsApp --all
```
