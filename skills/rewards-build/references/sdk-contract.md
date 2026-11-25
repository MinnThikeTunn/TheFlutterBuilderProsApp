# Rewards SDK API Contract

The `rewards_sdk` is a pure headless library offering async Dart APIs (`41` methods on `WalletSdk`). All operations are non-blocking and return immutable views or throw typed `WalletSdkException`s.

## Interface: `WalletSdk`

### Flow 1: Activation Request
```dart
Future<WalletActivationStatus> getActivationStatus();
Future<ActivationRequestView> startActivation(BuilderIdentity builder);
Future<ActivationRequestView?> restoreActivationRequest();
Future<void> cancelActivation();
```

### Flow 2: App Master Authority & Roster
```dart
Future<DistributorAuthorityStatus> importDistributorSecret(String secret);
Future<DistributorAuthorityStatus> getDistributorAuthorityStatus();
Future<void> removeDistributorAuthority();
Future<ActivationRequestReview> inspectBuilderRequest(String qrValue);
Future<ActivationRequestReview?> restoreInspectedBuilderRequest();
Future<ActivationResponseView> approveBuilderRequest(String requestId);
Future<AppMasterOverview> getAppMasterOverview();
Future<AppMasterRosterPage> getAppMasterRoster({String? cursor, int limit = 20});
```

### Flow 3: Activation Completion
```dart
Future<ActivationReview> inspectActivationResponse(String qrValue);
Future<ActivationOutcome> approveActivation(String responseId);
Future<WalletActivationStatus> reconcileActivation();
```

### Provider & Handshake Configuration
```dart
Future<ProviderConfigurationStatus> getProviderConfigurationStatus();
Future<ProviderConfigurationOutcome> saveAppMasterProviderConfiguration(
  ProviderConfigurationInput input,
);
Future<ConfigurationRequestView> createConfigurationRequest();
Future<ConfigurationRequestReview> inspectConfigurationRequest(String qrValue);
Future<ConfigurationUpdateView> createConfigurationUpdate(String requestId);
Future<ConfigurationReview> inspectConfigurationUpdate(String qrValue);
Future<ConfigurationOutcome> applyConfigurationUpdate(String updateId);
```

### Flow 4: Read Surfaces
```dart
Future<RewardsReceiveView> getRewardsReceiveIdentity();
Future<RewardsBalanceView> getRewardsBalance();
Future<RewardsHistoryPage> getRewardsHistory({String? cursor, int limit = 20});
```

### Flow 5: Transfer, Authorization & Pending Recovery
```dart
Future<RewardsRecipientView> inspectRewardsRecipient(String publicAccount);
Future<RewardsTransferReview> prepareRewardsTransfer({
  required String publicAccount,
  required String amount,
});
Future<RewardsTransferReview> getPreparedRewardsTransfer(String reviewId);
Future<RewardsTransferAuthorization> authorizeRewardsTransfer(String reviewId);
Future<void> cancelRewardsTransferAuthorization();
Future<RewardsTransferOutcome> approveRewardsTransfer(String reviewId);
Future<RewardsTransferOutcome?> getRewardsTransferStatus({bool reconcile = false});
Future<RewardsTransferOutcome?> resolvePendingRewardsTransfer({
  String? competingTransactionHash,
});
```

### Flow 6: Access & Recovery
```dart
Future<RewardsAccessState> getRewardsAccessState();
Future<void> lockRewards();
Future<void> unlockRewards();
Future<void> removeRewardsAccess();
Future<String> createRewardsBackup(String password);
Future<void> confirmRewardsBackup(String backup, String password);
Future<void> restoreRewardsBackup(String backup, String password);
Future<void> eraseRewardsFromDevice();
```
