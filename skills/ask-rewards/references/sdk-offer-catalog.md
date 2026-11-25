# `rewards_sdk` Full Offer & Capability Catalog

`rewards_sdk` is a **pure headless Flutter/Dart SDK** for the BuilderPros Rewards Wallet on Stellar (`REWARD` asset). All `WalletSdk` operations are async (`Future<T>`) and throw typed `WalletSdkException(code, safeMessage, canRetry)`.

Entrypoint: `import 'package:rewards_sdk/rewards_sdk.dart';` → `final WalletSdk sdk = createWalletSdk();`

---

## 1. Complete Capability Domains (41 `WalletSdk` Methods)

### A. Builder Activation & Reconciliation (7 methods — Flows 1 & 3)
QR-based handshake between a Builder device and an App Master device:
- `getActivationStatus()` → `Future<WalletActivationStatus>` (`notActivated`, `pending`, `active`, `failed`, `uncertain`)
- `startActivation(BuilderIdentity builder)` → `Future<ActivationRequestView>` (generates `ACT-...` QR)
- `restoreActivationRequest()` → `Future<ActivationRequestView?>`
- `cancelActivation()` → `Future<void>`
- `inspectActivationResponse(String qrValue)` → `Future<ActivationReview>` (parses `RES-...` QR)
- `approveActivation(String responseId)` → `Future<ActivationOutcome>` (`submitted`, `rejected`, `uncertain`)
- `reconcileActivation()` → `Future<WalletActivationStatus>`

### B. App Master Authority & Builder Approval (7 methods — Flow 2)
Distributor authority management and Builder activation signing:
- `importDistributorSecret(String secret)` → `Future<DistributorAuthorityStatus>`
- `getDistributorAuthorityStatus()` → `Future<DistributorAuthorityStatus>`
- `removeDistributorAuthority()` → `Future<void>`
- `inspectBuilderRequest(String qrValue)` → `Future<ActivationRequestReview>`
- `restoreInspectedBuilderRequest()` → `Future<ActivationRequestReview?>`
- `approveBuilderRequest(String requestId)` → `Future<ActivationResponseView>` (generates `RES-...` QR)
- `getAppMasterOverview()` → `Future<AppMasterOverview>` (activation capacity, available rewards, service status)

### C. App Master Roster (1 method)
On-chain trustline roster query (no centralized backend required):
- `getAppMasterRoster({String? cursor, int limit = 20})` → `Future<AppMasterRosterPage>` (`BuilderAccessEntry` items with `BuilderAccessState`: `pending`, `active`, `suspended`)

### D. Provider & Handshake Configuration (7 methods)
Horizon endpoint, API key, funding/initial-rewards policy, and QR configuration sharing:
- `getProviderConfigurationStatus()` → `Future<ProviderConfigurationStatus>` (`notConfigured`, `pendingVerification`, `ready`)
- `saveAppMasterProviderConfiguration(ProviderConfigurationInput input)` → `Future<ProviderConfigurationOutcome>` (defaults: `activationFunding = '2.1'`, `initialRewards = '1'`)
- `createConfigurationRequest()` → `Future<ConfigurationRequestView>`
- `inspectConfigurationRequest(String qrValue)` → `Future<ConfigurationRequestReview>`
- `createConfigurationUpdate(String requestId)` → `Future<ConfigurationUpdateView>`
- `inspectConfigurationUpdate(String qrValue)` → `Future<ConfigurationReview>`
- `applyConfigurationUpdate(String updateId)` → `Future<ConfigurationOutcome>`

### E. Read Surfaces (3 methods — Flow 4)
- `getRewardsReceiveIdentity()` → `Future<RewardsReceiveView>` (public account + QR string + environment + assetCode)
- `getRewardsBalance()` → `Future<RewardsBalanceView>` (`total`, `available`, `observedAt`)
- `getRewardsHistory({String? cursor, int limit = 20})` → `Future<RewardsHistoryPage>` (`RewardsHistoryDirection`: `received`, `sent`, `self`)

### F. Transfers, Biometric Authorization & Pending Recovery (8 methods — Flow 5)
Prepare-then-authorize-then-submit transfer pipeline with uncertain-send reconciliation:
- `inspectRewardsRecipient(String publicAccount)` → `Future<RewardsRecipientView>` (checks recipient & `receivingCapacity`)
- `prepareRewardsTransfer({required String publicAccount, required String amount})` → `Future<RewardsTransferReview>` (immutable review with `maximumFee` & `expiresAt`)
- `getPreparedRewardsTransfer(String reviewId)` → `Future<RewardsTransferReview>`
- `authorizeRewardsTransfer(String reviewId)` → `Future<RewardsTransferAuthorization>` (triggers native biometric/passcode prompt)
- `cancelRewardsTransferAuthorization()` → `Future<void>`
- `approveRewardsTransfer(String reviewId)` → `Future<RewardsTransferOutcome>` (`confirmed`, `failed`, `cancelled`, `uncertain`)
- `getRewardsTransferStatus({bool reconcile = false})` → `Future<RewardsTransferOutcome?>`
- `resolvePendingRewardsTransfer({String? competingTransactionHash})` → `Future<RewardsTransferOutcome?>`

### G. Device Access Lock & Encrypted Backup / Recovery (8 methods — Flow 6)
- `getRewardsAccessState()` → `Future<RewardsAccessState>` (`locked`, `unlocked`, `removed`)
- `lockRewards()` → `Future<void>`
- `unlockRewards()` → `Future<void>`
- `removeRewardsAccess()` → `Future<void>` (disables local Rewards access via marker)
- `createRewardsBackup(String password)` → `Future<String>` (`BRB1.` AES-256-GCM + PBKDF2 HMAC-SHA256)
- `confirmRewardsBackup(String backup, String password)` → `Future<void>`
- `restoreRewardsBackup(String backup, String password)` → `Future<void>`
- `eraseRewardsFromDevice()` → `Future<void>` (deletes local signing key; account & points remain on ledger)

---

## 2. Additional SDK Exports

- **Drop-in Recovery UI (`package:rewards_sdk/rewards_recovery_page.dart`)**:
  - `RewardsRecoveryPage({required WalletSdk sdk, required Future<void> Function() onChanged})` — SDK-owned Flutter screen for `BRB1.` backup creation, verification, restore, and device credential erasure (keeps recovery material out of app controllers).
- **Deterministic In-Memory Sandbox (`package:rewards_sdk/sandbox.dart`)**:
  - `createSandboxWalletSdk({String? seed, SeedableSandbox? sandbox})` → `WalletSdk`
  - `SeedableSandbox({String? seed})` with `reset()`, `failNext(WalletSdkFailureCode)`, `advanceTime(Duration)`, `nowUtc()`, and test constants (`defaultDistributorAccount`, `defaultDistributorSecret`, `defaultIssuerAccount`, `defaultAssetCode`).
  - **Strict Isolation Rule**: Never import `sandbox.dart` in production `lib/` code (`verify.ps1 -Act 3` enforces this).

---

## 3. Complete `WalletSdkFailureCode` Inventory (49 Codes)

- **Roster**: `rosterNotConfigured`, `rosterAccessDenied`, `rosterUnavailable`
- **Access & Lock**: `rewardsAccessRemoved`, `rewardsAccessUnavailable`
- **Transfers & Authorization**: `rewardsSendUnavailable`, `rewardsTransferPending`, `rewardsAuthorizationUnavailable`, `rewardsAuthorizationDenied`, `invalidRewardsTransferReview`, `invalidRewardsAmount`, `insufficientRewardsFunds`, `insufficientRewardsFeeFunds`, `rewardsTransferPreparationUnavailable`, `invalidRewardsRecipient`, `rewardsRecipientUnavailable`
- **Read Surfaces**: `rewardsIdentityUnavailable`, `rewardsBalanceUnavailable`, `rewardsHistoryUnavailable`, `invalidRewardsHistoryCursor`
- **Activation & Setup**: `invalidBuilder`, `secureSetupFailed`, `requestCreationFailed`, `cancellationFailed`, `invalidActivationRequest`, `activationRequestExpired`, `activationRequestAlreadyUsed`, `activationApprovalFailed`, `activationPolicyUnavailable`, `invalidActivationResponse`, `activationResponseExpired`, `activationSubmissionFailed`
- **Distributor Authority**: `invalidDistributorSecret`, `distributorAccountUnavailable`, `distributorAuthoritySaveFailed`
- **Provider & Network**: `invalidProviderConfiguration`, `providerConfigurationSaveFailed`, `providerConfigurationRequired`, `providerUnauthorized`, `providerRateLimited`, `providerServiceUnavailable`, `providerNetworkMismatch`, `providerInvalidResponse`, `providerTimeout`, `unavailable`
- **Config Handshake**: `invalidConfigurationRequest`, `invalidConfigurationUpdate`, `configurationUpdateExpired`, `configurationUpdateAlreadyUsed`

---

## 4. What `rewards_sdk` Intentionally Does NOT Offer

1. **No Full App UI Screens**: Aside from `RewardsRecoveryPage`, the SDK is 100% headless. Host apps build their own Builder/App Master screens, QR scanners, and state management (GetX, Riverpod, Bloc, or Vanilla Flutter).
2. **No Backend / Central Roster Server**: All activation handshakes, config updates, and trustline rosters run via QR payloads and direct Stellar Horizon queries.
3. **No Fiat On/Off-Ramps or Multi-Asset Swaps**: Scoped strictly to the single configured `REWARD` Stellar asset and native XLM fee/reserve management.
4. **No Mainnet Custody Bypass**: Production mainnet deployment (`Act 3` / `04-production.md`) is gated behind independent security review, cold-storage Issuer key custody, and dedicated Horizon credentials (NOWNodes).
