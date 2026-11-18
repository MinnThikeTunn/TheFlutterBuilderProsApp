import 'package:rewards_sdk/rewards_sdk.dart';
import 'package:rewards_sdk/src/sandbox/seedable_sandbox.dart';

export 'package:rewards_sdk/src/sandbox/seedable_sandbox.dart'
    show SeedableSandbox;

WalletSdk createSandboxWalletSdk({String? seed, SeedableSandbox? sandbox}) {
  final instance = sandbox ?? SeedableSandbox(seed: seed);
  return instance.createWalletSdk();
}
