# Wallet Sub-Feature 01 — Implementation Plan for 2 October 2026

Status (2026-10-03): Phases 0–2 are implemented in Flutter and covered by
automated analysis/widget checks. Phases 3–4 remain external release gates. Phase
5 remains planned product and SDK work.

## Purpose

Turn the remaining findings in `analysis-report.md` into independently verifiable
delivery slices while preserving the public Wallet SDK boundary and the current
activation behavior.

The report is an analysis snapshot. Its documentation corrections were already
applied on 20 September 2026, so this plan does not reopen those items unless a
fresh code-to-documentation check finds a new mismatch.

## Current baseline

- Wallet SDK Steps 1–16 are implemented.
- Steps 1–9 have physical-device verification; Steps 10–16 have automated
  verification.
- First-time activation is SDK-backed through the public
  `lib/wallet_sdk/wallet_sdk.dart` facade.
- Provider-configuration rotation APIs exist in the SDK but have no Flutter UI.
- Balance, receive, send, and history are presentation-only and need a new public
  SDK contract before their mock behavior can be replaced safely.
- Production/mainnet remains blocked by the two-physical-device testnet gate and
  independent security approval.

## Scope and priority

Work in this order:

1. Reconfirm the baseline and protect existing behavior.
2. Implement the provider-configuration rotation UI using the existing SDK APIs.
3. Run the two-device testnet activation and rotation gate.
4. Complete independent security review and address its findings.
5. Design and implement post-activation Rewards operations as separate slices.
6. Add physical-device integration coverage and synchronize owned documentation.

Production/mainnet enablement is not part of an earlier phase and must not occur
until Phases 3 and 4 pass.

## Phase 0 — Baseline verification

### Work

- Inspect the current working tree and preserve unrelated changes.
- Verify that `lib/app/` imports only `lib/wallet_sdk/wallet_sdk.dart`, never
  `lib/wallet_sdk/src/`.
- Confirm the five rotation methods and their safe public models still match the
  written SDK specification:
  - `createConfigurationRequest()`
  - `inspectConfigurationRequest(qrValue)`
  - `createConfigurationUpdate(requestId)`
  - `inspectConfigurationUpdate(qrValue)`
  - `applyConfigurationUpdate(updateId)`
- Run the existing test suite before implementation so new failures can be
  separated from pre-existing ones.
- Recheck the documentation items listed in analysis-report Section 8. Only edit
  them if they have drifted again.

### Exit criteria

- Baseline analysis and tests are recorded.
- No unresolved contract mismatch blocks the rotation UI.
- Existing activation behavior remains unchanged.

## Phase 1 — Builder configuration-request flow

### Product flow

Add a Settings entry available only for an active Builder Rewards installation:

```text
Rewards Settings
  -> Create configuration request
  -> Show request QR, request ID, and expiry
  -> Scan/import App Master update
  -> Review safe environment/version summary
  -> Confirm and apply
  -> Show success or safe retryable failure
```

### Implementation

- Add focused Builder configuration screens under the Wallet feature rather than
  expanding activation screens with unrelated state.
- Add centralized routes and GetX page registrations for request, scan, review,
  and outcome states.
- Extend `WalletController` only with application-level orchestration and safe
  public SDK models. Keep QR parsing, authorization, decryption, health checks,
  rollback, and persistence inside the SDK.
- Reuse the existing camera/gallery acquisition adapter and forward the exact
  opaque QR value to `inspectConfigurationUpdate()`.
- Use explicit in-flight guards for create, inspect, and apply actions.
- Render only safe fields returned by the SDK: IDs, expiry, environment,
  configuration version, status, and safe messages.
- On apply failure, retain the prior working configuration and expose retry only
  when the SDK result permits it.
- Do not place provider keys, decrypted configuration, raw QR payloads, or private
  SDK errors in controller state, logs, analytics, clipboard labels, or ordinary
  preferences.

### Tests

- Controller tests for create, restoration if supported by the current SDK
  contract, duplicate taps, inspect, apply, retryable failure, and navigation.
- Widget tests for QR rendering, exact-value acquisition, safe review content,
  confirmation, success, expiry, wrong-device, downgrade, replay, and health-check
  failure presentations.
- Boundary tests proving feature code imports no private SDK implementation.
- Regression tests proving a failed update leaves the prior healthy
  configuration usable.

### Exit criteria

- An active Builder can create a device-bound request and apply a valid newer
  configuration through the public facade.
- Failure paths expose no protected values and preserve the last healthy
  configuration.

## Phase 2 — App Master configuration-update flow

### Product flow

Add a distinct rotation action to App Master Advanced:

```text
App Master Advanced
  -> Scan/import Builder configuration request
  -> Review Builder/device-safe request details
  -> Create configuration update
  -> Show update QR and expiry
  -> Finish and return to Advanced
```

Activation QR and configuration QR flows must remain visually and logically
distinct.

### Implementation

- Add focused App Master rotation screens, controller state, and centralized
  routes.
- Reuse the QR acquisition adapter, forwarding the opaque value only to
  `inspectConfigurationRequest()`.
- Call `createConfigurationUpdate(requestId)` only after explicit review and
  approval.
- Require an installed healthy provider configuration and a strictly newer
  version before update creation; display only the safe SDK failure otherwise.
- Render the returned opaque update QR without parsing or modifying it.
- Prevent duplicate inspection and creation calls.
- Keep NOWNodes credentials confined to the existing masked Advanced input and
  protected SDK storage.

### Tests

- Controller and widget coverage for scan and image import, cancellation,
  malformed/expired/consumed requests, wrong environment, missing healthy
  configuration, non-newer version, duplicate taps, update creation, and exact QR
  rendering.
- Cross-flow tests proving activation QR values are rejected by rotation flows and
  configuration QR values are rejected by activation flows.
- Secret-retention checks proving provider credentials never appear after submit
  or in generated UI state.

### Exit criteria

- App Master can inspect a valid Builder request and generate one authorized,
  expiring, device-bound update QR.
- Activation and rotation workflows cannot be confused or substituted.

## Phase 3 — Two-physical-device testnet gate

### Test matrix

Use disposable testnet accounts and non-production provider credentials supplied
outside source control. Test clean install, restart, interruption, expiry, camera
scan, gallery import, duplicate scan, wrong device, wrong environment, replay,
provider health-check failure, and successful retry.

Run on two physical devices:

1. Configure App Master and verify masked restored status.
2. Complete first-time activation from Builder request through reconciliation.
3. Confirm restart restores active Builder state without resubmission.
4. Create a newer App Master provider configuration while retaining the old key
   during the overlap window.
5. Complete the Builder-request/App-Master-update rotation handshake.
6. Confirm the new configuration is healthy and active.
7. Confirm invalid, downgraded, replayed, expired, and wrong-device updates fail
   while the previous healthy configuration remains usable.
8. Revoke the old provider key only after the migration checks pass.

Record device models, OS versions, app build identifier, environment, test cases,
and redacted outcomes. Never record seeds, API keys, signed envelopes, or decoded
protected payloads.

### Exit criteria

- Activation and rotation pass across two physical devices on testnet.
- Interrupted and ambiguous states recover without blind resubmission.
- The prior healthy configuration survives every failed rotation case.
- Any defect found is fixed and the affected matrix is rerun.

## Phase 4 — Independent security approval

### Review package

- Public facade and safe models.
- QR schemas, canonicalization, authorization, expiry, replay, and device binding.
- XDR subset generation and fail-closed parsing.
- Protected-storage boundaries and rollback behavior.
- Horizon transport, credential injection, redaction, timeouts, and bounded retry.
- Transaction construction, signature verification, submission, and
  reconciliation.
- Provider rotation overlap and revocation procedure.
- Physical-device test evidence from Phase 3.

### Required outcome

- Track each finding with severity, owner, fix, and retest evidence.
- Repeat relevant automated and device tests after changes.
- Record approval and any accepted residual risk in the decision log.
- Keep production/mainnet disabled until all release-blocking findings close.

## Phase 5 — Post-activation Rewards operations

This is a new SDK capability, not a UI-only fix. Plan and deliver each operation as
an independently reviewed slice.

### 5A — Public contracts and policy

- Define immutable, data-minimized models for balance, receive identity, history,
  transfer intent/review, transfer outcome, and reconciliation status.
- Define stable error codes and safe retry rules.
- Decide authentication, authorization, amount precision, fee presentation,
  recipient validation, asset allow-list, transaction limits, lock behavior, and
  removal semantics before implementing signing UX.
- Add fake SDK support before changing screens.

### 5B — Read-only operations

- Implement SDK-backed Rewards balance and receive identifier.
- Implement paginated history with typed private Horizon parsing and bounded
  responses.
- Replace overview, receive, and history mocks only after their SDK methods and
  tests pass.
- Add loading, empty, offline, stale-data, and unauthenticated states.

### 5C — Send operation

- Add inspect/prepare/review/approve/submit/reconcile methods behind the facade.
- Require explicit user approval of recipient, asset, amount, and fee before
  signing.
- Persist pre-submit state and reconcile ambiguous submissions without rebuilding
  or blindly resubmitting.
- Replace the mock send screens incrementally; do not expose private transaction,
  signing, provider, or credential concepts to Flutter.

### 5D — Lock and removal

- Define what lock protects and how authentication is established; do not ship a
  cosmetic lock as security.
- Define removal backup/recovery consequences and require explicit confirmation.
- Delete protected material transactionally and verify the resulting inactive
  state.

### Exit criteria

- No post-activation screen displays mock financial data or simulates a transfer.
- All sensitive work stays behind the public SDK facade.
- Automated tests cover success, rejection, interruption, expiry, replay,
  offline behavior, and uncertain submission reconciliation.
- High-risk send, lock, and removal behavior has security approval and physical-
  device verification before production use.

## Phase 6 — Integration coverage and documentation closeout

### Automation

- Add `integration_test/` coverage for the highest-value navigation and lifecycle
  paths that can run without real secrets.
- Keep provider/Horizon contract tests deterministic with fakes or controlled
  test services; keep real credential checks in the documented manual gate.
- Add regression coverage for app restart during request, review, pre-submit,
  uncertain, and post-apply states.

### Documentation ownership

Update only the files that own changed facts:

- Runtime behavior and limitations: `context/current-state.md`
- Architecture or boundary changes: `context/architecture.md`
- Durable security/product decisions: `context/decision-log.md`
- Completed checks and remaining backlog: `context/progress-tracker.md`
- UI rules, if navigation or shared components change: `context/ui-context.md`
- Detailed step gates: `docs/walletsub-feature01/stepbystep.md`
- Public SDK contract: `docs/walletsub-feature01/walletSDKspec.md`
- Screen inventory: `docs/walletsub-feature01/01-screen-list.md`

Do not rewrite `analysis-report.md`; it remains the dated analysis snapshot.

## Verification for every implementation phase

Run from the repository root as independent commands:

```powershell
dart format <changed Dart files>
flutter pub get
flutter analyze
flutter test
```

Also run `flutter build apk --debug` when a phase changes dependencies, permissions,
plugins, native configuration, or release packaging. Run focused tests during
development, then the full relevant suite before marking a phase complete.

## Overall definition of done

- Provider rotation is fully wired through Builder and App Master Flutter flows
  using only the public Wallet SDK facade.
- Two-device testnet activation and rotation evidence is complete.
- Independent security approval is recorded and release-blocking findings are
  closed.
- Post-activation balance, receive, history, and send are either genuinely
  SDK-backed or still clearly labeled as unimplemented; no mock behavior is
  described as production functionality.
- Context, progress, SDK contract, and screen documentation match the verified
  implementation.
- No credential, seed, signed envelope, private account data, or protected QR
  payload is committed or exposed through presentation state.
