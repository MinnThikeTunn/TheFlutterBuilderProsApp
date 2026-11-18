# Rewards SDK API Contract

The `rewards_sdk` is a pure headless library offering async Dart APIs. All operations are non-blocking and return immutable views or throw typed `WalletSdkException`s.

## Interface: `WalletSdk`

### Flow 1: Activation Request
```dart
Future<WalletActivationStatus> getActivationStatus();
Future<ActivationRequestView> startActivation(BuilderIdentity builder);
Future<ActivationRequestView?> restoreActivationRequest();
Future<void> cancelActivation();
```

### Flow 2: App Master Authority
```dart
Future<void> importDistributorSecret(String secretSeed);
Future<BuilderRequestReview> inspectBuilderRequest(String qrValue);
Future<ActivationResponseView> approveBuilderRequest(String requestId);
Future<AppMasterRosterPage> getAppMasterRoster({String? cursor, int limit = 20});
```

### Flow 3: Activation Completion
```dart
Future<ActivationReview> inspectActivationResponse(String qrValue);
Future<ActivationOutcome> approveActivation(String responseId);
Future<WalletActivationStatus> reconcileActivation();
```

### Flow 4: Read Surfaces
```dart
Future<RewardsReceiveView> getRewardsReceiveIdentity();
Future<RewardsBalanceView> getRewardsBalance();
Future<RewardsHistoryPage> getRewardsHistory({String? cursor, int limit = 20});
```

### Flow 5: Transfer & Send
```dart
Future<RewardsRecipientView> inspectRewardsRecipient(String publicAccount);
Future<RewardsTransferReview> prepareRewardsTransfer({
  required String publicAccount,
  required String amount,
});
Future<TransferAuthorizationOutcome> authorizeRewardsTransfer(String reviewId);
Future<RewardsTransferOutcome> approveRewardsTransfer(String reviewId);
Future<RewardsTransferOutcome?> getRewardsTransferStatus({bool reconcile = false});
Future<void> cancelRewardsTransferAuthorization();
```

### Flow 6: Access & Recovery
```dart
Future<RewardsAccessState> getRewardsAccessState();
Future<void> lockRewards();
Future<void> unlockRewards();
Future<String> createRewardsBackup(String password);
Future<void> confirmRewardsBackup(String backup, String password);
Future<void> restoreRewardsBackup(String backup, String password);
Future<void> eraseRewardsFromDevice();
```
