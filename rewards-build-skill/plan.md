# rewards-build — finalized plan

**Status:** approved design, updated for headless wallet capability.  
**Scope:** headless package extraction, in-memory sandbox, skill suite, commercial distribution.  
**UI Policy:** Headless capability only. Consumers build their own UI (using any architecture: Bloc, Riverpod, GetX, or vanilla Flutter). SDK provides pure Dart async APIs and raw QR string/verification primitives.  
**Does not change** the Rewards SDK's runtime behavior or security posture.

---

## 0. Decisions locked

| Decision | Choice |
| --- | --- |
| Skill shape | One **user-invoked** `rewards-build` skill. Stage files, not sibling skills. |
| UI Boundary | **Headless capability only**. The SDK does not dictate or supply the UI screens; the consumer creates presentation, state management, and navigation as they like. |
| SDK activation | `rewards_sdk` package, closed source, **vendored archive** + `path:` dependency. No tokens. |
| Enforcement | Gate scripts (`verify`, `bootstrap`, `seed-testnet`) that exit non-zero. Prose only instructs. |
| Sandbox | Built into the SDK package as `sandbox.dart`, reusing the injection surface already in `DefaultWalletSdk`. Complete in-memory activation, inspection, and transport fakes. |
| Money | Sandbox free; Act 2 (testnet) paid; Act 3 (production) gated and unsupported. |

## 1. What ships

Four artifacts:

1. `packages/rewards_sdk/` — the headless SDK package, extracted from `lib/wallet_sdk/`.
2. `packages/rewards_sdk/lib/sandbox.dart` — one public constructor `createSandboxWalletSdk()` wiring full in-memory fakes.
3. `templates/rewards_harness/` — a minimal reference harness and headless smoke-test suite (not a monolithic app copy) showing how to instantiate and call `WalletSdk`.
4. `skills/rewards-build/` — the skill, its stage files, gate scripts, and references (including UI integration recipes).

Plus two internal-only tools: `packages/rewards_sdk/tool/seed_testnet.dart` and a license check inside `verify`.

## 2. Findings that shaped the flow

These were verified in the code, and each removes an adoption barrier:

- **Headless UI Decoupling.** The entire Rewards wallet capability is already encapsulated in the `WalletSdk` interface (`lib/wallet_sdk/wallet_sdk.dart`). Methods take and return plain Dart objects and QR string primitives (`startActivation()`, `inspectActivationResponse(String qrValue)`, `prepareRewardsTransfer()`, `getRewardsBalance()`). Consumers are free to render QRs with `qr_flutter`, scan with `mobile_scanner`, or use manual input/deep links.
- **Activation does not need two devices.** Handshakes use standard string QR payloads. In sandbox or dual-role configurations, one device or emulator completes the handshake via string passing.
- **Act 2 does not need NOWNodes.** `ConfigurationPolicy` accepts `https://horizon-testnet.stellar.org` with an **empty API key** when the build passes `--dart-define=WALLET_PUBLIC_TESTNET_HORIZON=true` (`lib/wallet_sdk/src/configuration/configuration_policy.dart:16-51,64`). Production builds keep the NOWNodes-only rule.
- **The sandbox needs no SDK fork.** `DefaultWalletSdk` already accepts every collaborator by injection: `horizonHttpClient`, `transferAuthenticator`, `credentialStore`, `configurationStore`, `activeRewardsStore`, `rewardsSendStore`, `activationSubmissionStore`, `activationInspectionStore`, `configurationHandshakeStore` (`lib/wallet_sdk/src/default_wallet_sdk.dart:39-90`).
- **In-Memory Fakes Promotion & Completion.** While `test/support/wallet_flow_scenarios.dart` contains in-memory stores for post-activation (`_Credentials`, `_SendStore`, `_Active`, `_Submission`, `_Auth`, `MockClient`), activation flows (Flows 1–3) require fully mutable in-memory `SandboxActivationStore`, `SandboxInspectionStore`, and `SandboxHandshakeStore`. These are built directly into `packages/rewards_sdk/lib/src/sandbox/`.
- **Pre-Extraction Hygiene Baseline.** In `lib/wallet_sdk/src/default_wallet_sdk.dart:1381`, an unawaited Future in a try-block and flow-control brace lints must be formatted so `packages/rewards_sdk` starts 100% warning-free under `flutter analyze`.

## 3. Repository layout after extraction

```text
packages/rewards_sdk/
  pubspec.yaml                 name: rewards_sdk (sdk: flutter; local_auth, flutter_secure_storage, cryptography, http)
  lib/rewards_sdk.dart         public headless facade (exports WalletSdk, models, failure codes)
  lib/sandbox.dart             NEW: createSandboxWalletSdk({String? seed})
  lib/rewards_recovery_page.dart optional drop-in presentation helper (or headless recovery APIs)
  lib/app_master_roster.dart   roster models
  lib/src/...                  moved SDK internals
  lib/src/sandbox/             NEW: complete in-memory stores, fake Horizon transport, auto auth
  tool/seed_testnet.dart       NEW: issuer + distributor setup on testnet
  test/...                     SDK unit tests & sandbox scenario tests

templates/rewards_harness/
  pubspec.yaml                 minimal test harness depending on rewards_sdk via path
  lib/main.dart                headless capability demo & manual testing harness
  test/smoke_test.dart         headless verification of all 6 flows

skills/rewards-build/
  SKILL.md
  stages/00-preflight.md .. 04-production.md
  scripts/bootstrap.ps1, bootstrap.sh
  scripts/verify.ps1, verify.sh
  scripts/seed-testnet.ps1, seed-testnet.sh
  references/sdk-contract.md
  references/failure-codes.md
  references/native-setup.md
  references/ui-recipes.md     NEW: copy-paste UI wiring snippets (GetX, Riverpod, Bloc, qr_flutter)
```

The existing `theBuilderPros` app keeps `lib/wallet_sdk/wallet_sdk.dart` as a re-export shim during migration, then switches to the package dependency.

## 4. The flow, act by act

Each act has a gate that either passes or stops the run. No act is skippable.

### Act 0 — preflight

Checks, in order: 
1. `flutter --version` satisfies Dart `^3.9.2`.
2. Target project has required native configurations:
   - Android: `minSdkVersion >= 23`, `android.permission.USE_BIOMETRIC`, and `MainActivity` extends `FlutterFragmentActivity`.
   - iOS: `NSFaceIDUsageDescription` in `Info.plist`.
3. If running on device/emulator: a lock-screen credential exists for native biometrics/PIN fallback.

Gate: `scripts/verify.ps1 -Act 0` exits 0. It writes `.rewards/state.json` with `{act: 0, flutter, platform, deviceId}`.

### Act 1 — install and run the sandbox

Steps:
1. `scripts/bootstrap.ps1` unpacks `rewards_sdk-<version>.zip` into the target app's `third_party/rewards_sdk/`, adds the `path` dependency, applies native config, verifies package integrity, and writes `.rewards/installed.json`.
2. App wires `createSandboxWalletSdk()` (zero network calls, instant in-memory responses).
3. The consumer builds their custom UI against the SDK methods.

Walked flows (headless capability), in this order:

| # | Flow | SDK calls, in order |
| --- | --- | --- |
| 1 | Activation request | `getActivationStatus` → `startActivation` → `restoreActivationRequest` |
| 2 | App Master approval | `inspectBuilderRequest` → `approveBuilderRequest` |
| 3 | Activation completion | `inspectActivationResponse` → `approveActivation` → `reconcileActivation` |
| 4 | Read surfaces | `getRewardsReceiveIdentity` → `getRewardsBalance` → `getRewardsHistory` |
| 5 | Send | `inspectRewardsRecipient` → `prepareRewardsTransfer` → `authorizeRewardsTransfer` → `approveRewardsTransfer` → `getRewardsTransferStatus` |
| 6 | Access and recovery | `getRewardsAccessState` → `lockRewards` → `unlockRewards` → `createRewardsBackup` → `removeRewardsAccess` → `restoreRewardsBackup` |

Gate: `scripts/verify.ps1 -Act 1` runs `flutter analyze` on `packages/rewards_sdk`, its unit tests, and a 100% headless execution of the six flows through `createSandboxWalletSdk()` in under 5 seconds.

### Act 2 — testnet, real ledger

Prerequisites, automated by `scripts/seed-testnet.ps1`:
1. Create issuer keypair A and distributor keypair B.
2. Fund both via `https://friendbot.stellar.org` (with retry on rate limits).
3. B submits `changeTrust` to `REWARD:A`.
4. A submits `payment` of `100000 REWARD` to B.

The distributor ends with **exactly one** non-native balance (`activation_response_service.dart:59`).

In the consumer's app or harness:
- Configure endpoint: `https://horizon-testnet.stellar.org`, environment `test`, **empty API key**, version `1`, funding `2.1`, initial Rewards `1`. Import B's secret.
- Run with `--dart-define=WALLET_PUBLIC_TESTNET_HORIZON=true`.

Gate: `verify -Act 2` asserts a real activation reaches `WalletActivationState.active` on testnet, a real send reaches `RewardsTransferState.confirmed`, and `getRewardsHistory` returns the payment. (Interactive on emulator/device, or via automated test authenticator).

### Act 3 — production

The skill ends here. It states that production requires an independent security review, NOWNodes credentials, and a funded mainnet distributor, and that the vendor gates this act. No instructions to improvise.

## 5. The skill

`SKILL.md` frontmatter: `name: rewards-build`, `disable-model-invocation: true`, human-facing description ("Guided integration of the BuilderPros Rewards Wallet capability into any Flutter app").

Body: state the act sequence, the state file, and the rule that each act opens by running `verify` and stops on failure. Stage detail lives in `stages/`.

References include `references/ui-recipes.md` to help consumers quickly bind their custom UI to the headless SDK calls.

Second skill, added later: `rewards-troubleshoot`, model-invoked, triggers on "send stuck", "uncertain", "activation failed", "locked out". It carries the `WalletSdkFailureCode` vocabulary from `references/failure-codes.md`.

## 6. Sandbox contract

`lib/sandbox.dart` exports exactly:

- `createSandboxWalletSdk({String? seed})` → `WalletSdk`
- `SeedableSandbox` with `reset()`, `failNext(WalletSdkFailureCode)`, `advanceTime(Duration)`

Internals under `lib/src/sandbox/`:
`SandboxCredentials`, `SandboxActivationStore`, `SandboxConfigurationStore`, `SandboxActiveRewardsStore`, `SandboxSendStore`, `SandboxSubmissionStore`, `SandboxInspectionStore`, `SandboxHandshakeStore`, `SandboxAuthenticator`, `SandboxTransport`.

`SandboxTransport` implements the HTTP callbacks the SDK's clients expect and serves the six Horizon endpoints the SDK reads: accounts, fee_stats, transactions, transaction-by-hash, submit, and health.

Rule: `rewards_sdk.dart` never exports `sandbox.dart`. A project in sandbox mode imports `package:rewards_sdk/sandbox.dart`; a production project imports only `package:rewards_sdk/rewards_sdk.dart`. `verify -Act 3` fails if `sandbox.dart` is referenced.

## 7. Native configuration the bootstrap owns

Applied by `bootstrap.ps1` and checked by `verify`:

- Android: `minSdkVersion >= 23` in `android/app/build.gradle`, `USE_BIOMETRIC` permission in `AndroidManifest.xml`, and `MainActivity` extending `FlutterFragmentActivity`.
- iOS: `NSFaceIDUsageDescription` in `ios/Runner/Info.plist`.
- Camera: Optional recommendation documented in `references/native-setup.md` for consumers choosing camera QR scanning (`CAMERA` / `NSCameraUsageDescription`).
- Emulator: Device lock credential for biometric fallback.

## 8. Distribution and licensing

- Build artifact: `rewards_sdk-<version>.zip` containing `lib/`, `pubspec.yaml`, and a README. Built by `dart pub publish --dry-run` plus a zip step in CI.
- No `pub.dev`, no private pub host, no git tokens. The bootstrap unpacks and writes `path: third_party/rewards_sdk`.
- License: a signed `license.json` with `{customer, version, fileHashes}`. `verify` recomputes hashes and fails on mismatch or expired licence.
- **Cross-Platform Hash Normalization:** File hashes are computed with normalized line endings (`\r\n` converted to `\n`) so Windows checkouts and `dart format` do not trigger false tampering alarms.
- Marketing surface: `rewards_sdk` stays publicly readable on GitHub. The paid product is the guided skill, the seeded testnet tooling, and the gated production path.

## 9. Verification commands

Run independently, from `packages/rewards_sdk`:

```powershell
flutter pub get
flutter analyze
flutter test
```

Per act, from the host project:

```powershell
.\skills\rewards-build\scripts\verify.ps1 -Act 0
.\skills\rewards-build\scripts\verify.ps1 -Act 1
.\skills\rewards-build\scripts\verify.ps1 -Act 2
```

## 10. Execution order

1. **Step 1: Baseline Hygiene & Branching:**
   - Fix unawaited return in `lib/wallet_sdk/src/default_wallet_sdk.dart:1381` and brace lints.
   - Format with `dart format`.
   - Branch `feature/rewards-build`.
2. **Step 2: Package Extraction:**
   - Extract `lib/wallet_sdk/` → `packages/rewards_sdk/`.
   - Setup `pubspec.yaml` with required dependencies (`cryptography`, `flutter_secure_storage`, `http`, `local_auth`).
   - Mechanical import rewrite; update boundary tests.
   - Gate: `flutter analyze` and `flutter test` clean on `packages/rewards_sdk`.
3. **Step 3: Sandbox Completion:**
   - Implement mutable in-memory stores in `lib/src/sandbox/` (`SandboxActivationStore`, `SandboxInspectionStore`, `SandboxHandshakeStore`, `SandboxTransport`).
   - Expose `lib/sandbox.dart` with `createSandboxWalletSdk()`.
   - Gate: `packages/rewards_sdk/test/sandbox_test.dart` passes all six flows.
4. **Step 4: Minimal Reference Harness:**
   - Create `templates/rewards_harness/` with headless smoke test verifying consumer wiring.
5. **Step 5: Testnet Automation:**
   - Write `packages/rewards_sdk/tool/seed_testnet.dart` and `scripts/seed-testnet.ps1` with Friendbot retry logic.
   - Run Act 2 on testnet once to confirm on-chain token creation and transfer.
6. **Step 6: Skill Suite:**
   - Write `SKILL.md`, stage files (`00-preflight.md` .. `04-production.md`), `scripts/bootstrap.ps1`, `scripts/verify.ps1`, and `references/ui-recipes.md`.
   - Gate: Clean machine runs Act 0 → Act 1 without manual intervention.
7. **Step 7: Packaging & CI:**
   - Package zip, line-ending normalized hash generator, license file, and CI workflow.

## 11. Risks & Mitigations

- **Sandbox Drift:** Fakes diverging from Horizon transport. Mitigation: Shared mock payloads and contract tests ensuring sandbox mirrors real testnet responses.
- **Biometric Automation in Act 2:** Native OS prompts cannot be clicked by headless scripts. Mitigation: `verify.ps1 -Act 2` supports an interactive emulator prompt mode or an injected test-authenticator hook.
- **Stellar Friendbot Flakiness:** Public testnet rate limits (HTTP 429). Mitigation: `seed-testnet.ps1` incorporates exponential backoff and balance inspection before requesting funds.
- **Cross-Platform Checksum Mismatches:** Windows CRLF checkout altering hashes. Mitigation: In-memory LF normalization during SHA-256 calculation.

## 12. Out of scope

- Dictating or supplying consumer UI screens or state management libraries.
- Changing SDK security behavior, custody, or the send policy.
- Applying for production/mainnet access.
- A hosted provisioning service (Act 2 as SaaS).
- Multi-tenant, multi-asset, or non-Stellar support.
