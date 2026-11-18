# Rewards SDK

Headless Flutter capability for the BuilderPros Rewards Wallet.

## Usage

```yaml
dependencies:
  rewards_sdk:
    path: third_party/rewards_sdk
```

```dart
import 'package:rewards_sdk/rewards_sdk.dart';

final WalletSdk sdk = createWalletSdk();
final status = await sdk.getActivationStatus();
```
