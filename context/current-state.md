# Current State

Last synchronized: 2026-10-03

Documentation sync notes and a fuller mismatch analysis live in
`docs/walletsub-feature01/analysis-report.md`.

## Repository

- Primary branch: `main`
- Canonical repository: `https://github.com/theBuilderPros/TheFlutterBuilderProsApp.git`
- Dart package: `the_builder_pros`
- Android application ID: `com.thebuilderpros.thebuilderpros`
- Product name: `theBuilderPros`

## Runtime

The app currently runs as a Flutter Material 3 application using GetX for routing,
dependency injection, and reactive state.

The initial route opens the wallet-owned not-activated Rewards screen. Explicit
role-switch controls expose App Master surfaces for dual-role testing. The
production SDK facade lives under `lib/wallet_sdk/`; feature code imports only its
safe public API.

Wallet SDK Steps 1–16 are implemented. Steps 1–9 are device verified. Steps 10–16
pass automated checks. The two-physical-device testnet gate and independent security
approval remain open before production/mainnet.

### First-time activation (implemented)

The Builder Rewards flow under `lib/app/features/wallet/` and App Master under
`lib/app/features/app_master/` run the phone-to-phone activation handshake through
`WalletSdk`:

- Builder start/restore/cancel of a protected local activation request with a real
  request QR, request ID, and expiry
- App Master camera/gallery acquisition, SDK request inspection, live overview
  capacity/Rewards availability, approval, and a real activation response QR
- Builder response acquisition, SDK inspection, approval, direct submission, and
  reconciliation into active Rewards state
- App Master Advanced NOWNodes configuration (health-checked, protected) and
  direct distributor-secret import with masked safe status only
- Startup restoration and reconciliation of pending/uncertain activation without
  blind resubmission

Private SDK services own Ed25519 key generation, SEP-23 StrKey, XDR activation
subset, device-bound provider encryption, Horizon HTTP, credentials, and
persistence. There is no `stellar_flutter_sdk` dependency.

`WalletController` is application-scoped because it owns text controllers shared
across wallet routes. This prevents GetX route replacement from disposing those
controllers while a replacement wallet screen is being built.

Provider-configuration rotation APIs and Flutter flows are implemented. An active
Builder can create a device-bound request, scan or import an App Master update,
review its safe environment/version/host summary, and apply it. App Master
Advanced can scan or import the request, review it, and create the protected update
QR. Physical two-device verification remains open.

### Post-activation Rewards (partially SDK-backed)

New activation finalization persists a protected versioned active-account record
with the verified account, activation asset, credential reference, transaction
identity, and verification time before publishing verified status. It checks
credential ownership and submission binding. Identity-write failures retain an
unresolved activation outcome; final-status failures can retry against the retained
identity. This does not implement daily Rewards APIs. Migration of previously
verified installations is now performed lazily when balance or Receive needs an
active record. Their legacy activation status is preserved on migration failure.
The transport-only APK verification above predates this change.

Receive now loads the public account through `getRewardsReceiveIdentity()`, renders
its actual account-address QR, and copies the exact public account. It requires
verified submission evidence matching the protected active record. Existing
installations lacking that record migrate only when retained authorized activation
and live ledger evidence validate. Missing, altered, or unavailable evidence gives
a safe unavailable state and preserves recovery material. Network and asset are derived from App Master-
authorized activation rather than fixed application settings.

Overview now loads `getRewardsBalance()` automatically and supports guarded refresh.
The SDK reads the exact activated account/asset using protected provider settings,
returns exact decimal totals and available Rewards, and checks the active identity
again after the read. Available Rewards subtract selling liabilities and are zero
for an unauthorized trustline. Missing/malformed account or asset data is unavailable,
not a fabricated zero. Previously checked data stays visibly stale on refresh failure;
identity/configuration mismatch clears it. This is not a guarantee that a transfer
can succeed; fees and send authorization remain future work.

History now loads paginated confirmed direct payments in the activated Rewards
asset through the SDK. It validates cursor scope/order, exact amounts, payment
participants, and ledger success, and shows loading, empty pages, load-more,
refresh/retry, and retained stale data. Other assets and non-direct-payment operations
are filtered; local pending attempts, path payments, and full account activity are
not included. Cache is in memory only. Physical verification remains open.

Recipient inspection is SDK-backed: camera/gallery/manual public addresses are
checked against the activated asset through the current provider. Exact receiving
capacity subtracts buying liabilities. Invalid, self, missing, unauthorized, full,
memo-routed, and issuer-return destinations are unavailable in this slice. The
result is a read observation, not a prepared transfer or authorization.
Recipient slice checks passed dependency resolution, static analysis, and all
117 tests on 2026-10-03. Camera/gallery behavior still requires physical-device
verification; the earlier APK predates this implementation.

Send amount and review are SDK-backed preparations. Amounts use exact seven-decimal
integer units; fresh recipient capacity and Rewards funds are checked. Native fee
funds subtract selling liabilities and the current ledger reserve adjusted for
sponsorship. The single-operation fee bid is the maximum of ledger base fee,
fee-stats base fee, and recent charged p95, shown as exact XLM in the review.
One private intent is retained in memory for two minutes, bound to identity,
configuration, recipient, asset, amount, sender sequence, and fee. Preparation itself neither signs nor submits; restart requires new preparation. Failed/replacement preparations
invalidate the prior review. Analysis and all 123 tests passed on 2026-10-03.

The normal Send flow reaches an immutable review with native per-transfer device
authentication (biometric or device PIN/passcode fallback). The SDK rereads funds,
recipient capacity, sequence, and fee before and after the prompt. Approval binds
the exact private review, is single-use and expires within 30 seconds or the
review expiry. Cancellation, replacement, backgrounding, and changed state revoke
approval. Public authorization results are informational and cannot authorize
signing. Confirm and send now invokes SDK-owned testnet signing, a durable
pre-submit hash/public-intent record, one POST, and ledger reconciliation. Repeated
approval returns saved status without another POST. Restart restoration uses only
hash lookups; pending evidence blocks another transfer. Confirmed/failed outcomes
require the exact signed ledger envelope. A 404 or timeout remains uncertain even
after expiry; resolving never-ingested/pruned transactions needs a later recovery
policy. Production sends remain blocked. Lock/session and local access removal
are SDK-backed under the retention policy below. App Master “Builder access” rows
remain mock. Native authentication still requires physical-device verification.
Authorization verification previously passed dependency resolution, static analysis,
all 130 tests, and Android debug APK build. The subsequent testnet-send slice passed
dependency resolution, clean analysis, all 140 tests, and a fresh Android debug APK
build, including signed-intent, durability, concurrency, restart, and SDK/UI
coverage. The current artifact/hash is recorded in
`docs/walletsub-feature01/two-device-verification-3oct.md`; native device evidence
and independent review remain open. Apple/Windows native builds were not run.

## Implemented Behavior

### Controlled app integration closeout

The same two complete daily-flow scenarios run through `test/wallet_flow_test.dart`
and `integration_test/wallet_flow_test.dart`: verified-fixture startup, Receive,
real SDK/transport/signing/reconciliation, refreshed balance/history, lock/removal/
restoration, and uncertain-send reconstruction without another POST. Authentication,
network and storage are controlled in memory. This does not verify actual activation,
real native prompts, durable OS storage, process kill or two-device testnet behavior.
Android integration targets/generated test listeners use a separate `.integration`
app package; the ordinary package is preserved.

Dependency resolution, clean analysis and all 153 headless tests passed. Ordinary
and isolated Android APKs built, and their distinct package IDs were verified.
Device execution was blocked by
`INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`; neither scenario ran on
the device. Windows execution lacks Visual Studio's C++ toolchain. The release
review package is `docs/walletsub-feature01/release-closeout-3oct.md`. Independent
security approval and real-device release gates remain open; production stays blocked.

### Local Rewards lock and retained-material removal

`getRewardsAccessState`, `lockRewards`, `unlockRewards`, and `removeRewardsAccess`
replace the mock security flows. Sessions start locked on restart and expire in
five minutes. Explicit lock/background invalidates reviews, pending preparation,
and approval; it cannot undo a POST already sent. Native unlock restores local
session access, not payment authorization. Public reads remain available while
locked; every send independently authenticates its exact review.

Removal authenticates and writes/read-verifies a protected disabled-access marker.
It blocks local Rewards reads and Builder activation/signing after restart, while
preserving credentials, identity/configuration and reconciliation evidence.
Pending/uncertain transfers block removal. No account is closed, no Rewards move,
and no seed is erased. Native account-bound restoration re-enables access. A partial
write can already have disabled access despite an error; inspect stored state.
Corrupt/unavailable state fails closed. Startup routes disabled access to restoration.
General off-device recovery and permanent credential erasure remain undesigned.
Device lifecycle/storage behavior and independent security review remain open.
Verification: formatted Dart, dependency resolution, clean analysis, all 151 tests,
and Android debug APK build passed. Apple/Windows builds and physical lifecycle
tests were not run; the device execution record contains the current APK hash.

### Activation and App Master (SDK-backed)

- Validate Builder name and phone, prevent duplicate activation taps, and show
  safe loading/failure states.
- Generate, restore, and cancel a protected activation request; render its real
  QR; copy the opaque SDK value.
- App Master: scan or import a request, inspect through the SDK, review safe
  Builder details, approve, and show a real response QR.
- App Master Advanced: masked NOWNodes save/health/status; masked distributor
  secret import, status, and confirmed removal.
- App Master Overview: live estimated activation capacity, Rewards availability,
  service status, and refresh time from the SDK.
- Builder: scan or import the response, inspect, approve, submit, reconcile, and
  route verified activation to Rewards overview.
- Builder and App Master: complete the provider-configuration request/update QR
  flow through the existing Step 15 SDK APIs, with distinct rotation routes,
  duplicate-action guards, safe review models, and transactional SDK application.

### Daily Rewards surfaces

- SDK-backed balance refresh, public-account Receive QR/copy, and paginated direct
  Rewards payment history.
- Scan/import/enter a public recipient address and inspect receiving capacity via
  the SDK. Address edits clear the prior observation; failed checks show safe errors.
- Prepare an exact transfer amount and fee with SDK validation; render immutable
  review values without entering mock authentication/outcome navigation.
- Authenticate an exact transfer review through the SDK's native device prompt;
  safe failure/cancellation, expiry, and lifecycle checks revoke approval.
- Lock/removal and legacy send outcome routes remain presentations.

## Current Limitations

Activation request, inspection, submission, and active-state records are persisted
through the SDK’s protected and ordinary stores as designed for Steps 1–14.
Day-to-day Rewards interaction state outside activation remains in memory or mock.

The app currently has no:

- general application login or wallet unlock session (per-transfer device
  authentication is implemented separately)
- general application backend client
- production Rewards transfers, general wallet sessions, and recovery/removal policy
- Provider-configuration rotation UI is not yet verified across two physical
  devices
- dedicated Activation Progress route (progress/outcome remain on review)
- working notification action
- broad loading, network, offline, or unauthenticated product states outside
  activation paths
- production-grade identity or phone verification
- `integration_test/` suite
- bundled Inter font assets (family is declared in theme only)

Production/mainnet remains blocked pending the two-physical-device testnet gate and
independent security approval. See `docs/walletsub-feature01/stepbystep.md`.

The Profile feature contains the reusable Builder identity card used by activation.
Automated coverage includes Wallet SDK lifecycle, protocol, transport, hardening,
import-boundary, and related widget tests.

## Branding Assets

- Source logo: `assets/images/the_builder_pros_logo.png`
- Android launcher icons: branded density-specific PNGs
- Web favicon: branded PNG

Platform configuration contains the theBuilderPros identity described in the latest decision log entry.

## Verification Record

History passed `flutter pub get`, `flutter analyze`, and all 111 tests on 2026-10-03.
No native/dependency changes or new APK; device/security gates remain open.

Legacy migration passed `flutter pub get`, `flutter analyze`, and all 105 tests on
2026-10-03. Physical verification and independent security approval remain open.

Legacy migration uses the current provider configuration (preserving rotated keys),
revalidates response/device/transaction bindings, verifies ledger state, and checks
signing credential ownership before protected persistence. Expired retained QR
evidence is accepted only for migration of already-verified activation; this does
not permit new activation approval. A current balance of zero is allowed after
spending. Migration never generates an account, submits a transaction, or deletes
retained recovery evidence. Concurrent callers share one migration attempt per SDK
instance, and failures can retry. Device/security review remains open.

The balance slice passed `flutter pub get`, `flutter analyze`, and all 98 tests on
2026-10-03. The prior APK predates this Dart-only slice; no new APK was built.

Active identity and Receive checks on 2026-10-03: dependency resolution and analysis
passed, and all 91 tests passed (including failure/retry and Receive widget coverage).
No updated APK was built for this subsequent slice; the APK below is the earlier
transport-only artifact. Physical and independent-security gates remain open.

The shared Horizon transport refactor passed `flutter pub get`,
`flutter analyze`, and all 79 tests on 2026-10-03 (69 existing regression tests
and 10 new transport/composition tests). The five default Horizon consumers now
share one private transport/client. Shared phase deadlines are 5 seconds;
reconciliation additionally has a 15-second operation deadline. Public SDK
methods and operation result mappings remain unchanged. Physical verification
of the refactored build and independent security approval remain open.
`flutter build apk --debug` also passed, producing
`build/app/outputs/flutter-apk/app-debug.apk` for the pending device gate.

The Step 4 App Master provider-configuration integration passed automated checks on
2026-09-18:

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

Step 4 was subsequently confirmed working on a physical device.

Step 5 now creates a separate X25519 device-configuration identity in protected
storage. Activation request v2 exposes only its opaque device ID and public key,
uses a bounded canonical envelope with an alteration checksum, and is strictly
validated during restore. Legacy v1 pending requests are invalidated and their
activation credentials removed. Step 5 automated checks pass; its physical-device
create/restore/second-phone QR check passed on 2026-09-19.

The Step 5 verification record on 2026-09-19 is `flutter analyze`, all 32 tests,
and `flutter build apk --debug` passing.

Step 6, device verified on 2026-09-19, adds real App Master camera scanning and
QR-image selection behind a focused
adapter. It forwards the decoded value byte-for-byte, rejects multiple distinct
codes, and distinguishes cancellation, unreadable input, and camera denial with
safe UI states. Camera/photo access is requested only by the related action. The
opaque value is retained transiently for the Step 7 SDK inspection call; request
schema parsing remains absent from widgets and controllers.

Step 7 now sends the opaque value to `WalletSdk.inspectBuilderRequest()`. The SDK
strictly validates the request, checks its consumed-request store, protects the
pending raw request for restoration, and returns a safe review containing only the
Builder identity, request ID, expiry, and plain-language setup steps. The App Master
review screen no longer contains mock Builder details.

The Step 7 verification record on 2026-09-19 is `flutter analyze`, all 43 tests,
and `flutter build apk --debug` passing.

Step 7 was subsequently confirmed working on a physical device. Step 8 now uses an
approved LOBSTR-style direct import in App Master Advanced. The SDK validates the
Stellar secret, derives the account, verifies it through the protected active
provider configuration, saves only after success, restores masked status, supports
confirmed removal, and keeps failed replacements from overwriting the prior secret.

The Step 8 verification record on 2026-09-19 is `flutter analyze`, all 47 tests,
and `flutter build apk --debug` passing. Step 8 was subsequently device verified.

Step 9 now loads the protected distributor account and fee state directly from
Horizon, parses balances, liabilities, subentries, sequence, trustlines, and fee
percentiles privately, and exposes only estimated activation capacity, safe Rewards
availability, service status, and refresh time. App Master Overview and Advanced no
longer use mock capacity or Rewards totals.

Capacity is currently a conservative estimate using a private 0.5 base-reserve
assumption, retained safety margin, current subentry count/liabilities, three p95
fees, and 2.1 units of activation funding per Builder. Until the Rewards asset code
and issuer are configured, a numeric Rewards amount is shown only when exactly one
non-native balance exists; otherwise the safe result is `Not available` or `Needs
review`.

The Step 9 verification record on 2026-09-19 is `flutter analyze`, all 49 tests,
and `flutter build apk --debug` passing.

Step 9 was subsequently confirmed working on a physical device. Step 10 now adds a
private, fail-closed Stellar classic-transaction protocol core without a Stellar
SDK. It is pinned to official Stellar XDR `v27.0` commit
`68fa1ac55692f68ad2a2ca549d0a283273554439`, with a committed activation-subset
schema, deterministic generator, and generated constants.

The Step 10 boundary implements RFC 4506 primitives and canonical padding, classic
V1 envelopes, Ed25519 accounts, optional time bounds, no memo, extension v0,
alpha-num-4/12 credit assets, and only `createAccount`, `changeTrust`, and `payment`.
It performs network-passphrase transaction hashing, Ed25519 signing and verification,
signature hints, and signature preservation. Unsupported envelope, account, asset,
memo, precondition, extension, or operation variants are rejected. This layer is
not yet connected to App Master approval or live submission.

The Step 10 verification record on 2026-09-19 is deterministic generator execution,
`flutter analyze`, and all 58 tests passing. No native dependency or platform
configuration changed, so this step does not require a replacement Android build.

Step 11 connects App Master approval to live account and fee reads, the limited
protocol core, protected distributor signing, device-bound provider-configuration
encryption, complete-response authorization, and a real activation QR. The request
remains pending and is not consumed. Builder response inspection, local approval,
submission, and reconciliation remain Steps 12-14.

The Step 11 verification record on 2026-09-19 is `flutter analyze` and all 60
tests passing. No native build input changed.

Step 12 adds Builder camera/gallery response acquisition and SDK-only inspection.
It validates authorization, local request/device binding, expiry/replay,
authenticated provider decryption, exact transaction policy, and the App Master
signature. It stores the verified opaque response for Step 13 but does not commit
configuration, sign, submit, or mark Rewards active.

The Step 12 verification record on 2026-09-19 is `flutter analyze` and all 60
tests passing. No native build input changed.

Step 13 revalidates the protected inspected response, signs the exact transaction
with the protected Builder key, persists its hash and submitting state first, and
makes one direct authenticated Horizon submission. Durable state prevents blind
resubmission and distinguishes accepted, definite rejection, and uncertain results.
Accepted still means pending Step 14 authoritative verification.

The Step 13 verification record on 2026-09-19 is `flutter analyze` and all 63
tests passing. No native build input changed.

Step 14 adds bounded direct transaction/account reconciliation, verifies the exact
Builder account and starting Rewards balance, health-checks and promotes the
device-bound provider candidate, and persists active state. Startup restores and
reconciles pending/uncertain state without resubmission, routing verified activation
to Rewards.

The Step 14 verification record on 2026-09-19 is `flutter analyze` and all 64
tests passing. No native build input changed.

Step 15 adds distinct configuration request/update QR payloads, device-bound
authenticated encryption, App Master authorization, expiry/replay/downgrade
checks, candidate health validation, and atomic configuration promotion.

The Step 15 verification record on 2026-09-19 is `flutter analyze` and all 64
tests passing. No native build input changed.

Step 16 adds configuration-handshake abuse coverage, SDK import-boundary
enforcement, reviewed mobile QR permissions, and the provider operations SOP. The
existing suites cover XDR mutation, redaction, protected-storage rollback,
submission timeout, and duplicate prevention. Production remains blocked pending
the two-device testnet gate and independent security approval.

The Step 16 automated verification record on 2026-09-19 is `flutter analyze` and
all 67 tests passing.

The Step 6 verification record on 2026-09-19 is `flutter analyze`, all 38 tests,
and `flutter build apk --debug` passing. Android disables Kotlin incremental
compilation because Flutter plugin sources and the project occupy different Windows
drive roots, which otherwise corrupts Kotlin's relative-path cache.

See `progress-tracker.md` for completed work and the active backlog.
## Latest implementation slice — verification deferred

App Master dashboard and Advanced Builder-access rows now use the public SDK roster API instead of sample data. A host-injected provider must authorize each request and supply real records. No provider is configured by default; the UI reports unavailable configuration without fabricating rows. Pages are validated and cursors bind the environment, authority account, configuration version and page size. This slice has not been analyzed, tested or built, at the user's request; the earlier 153-test result predates it. Off-device recovery and permanent credential erasure remain unimplemented.
## Activation settings and asset-based Builder list — 2026-10-03

App Master Advanced now edits account funding and initial Rewards points with the service configuration. The SDK parses up to seven decimal places, requires account funding of at least 1.5 and positive initial Rewards, persists both in protected configuration, provisions them in the encrypted activation response, and verifies the signed operations against that response's policy. Existing configurations retain defaults of 2.1 funding and 1 point. Capacity considers both available funding and Rewards. Saving requires the service settings/API key and performs the existing service health check.

The Builder list now queries the configured network for accounts with the distributor's single Rewards asset trustline, using the existing SDK transport. It displays public account references, actual Rewards balances and restricted status derived from asset authorization. No membership backend or host roster provider is required. All matching trustlines are listed, not only accounts activated through this app; names/phone numbers are not inferred from public accounts. Pagination binds network, configuration version, authority and exact asset. The earlier host-provider design and its backend requirement are superseded.

Implementation is unverified: tests, analysis and builds are deferred at the user's request. Recovery export/permanent erasure and release gates remain outstanding.
## Send configuration policy update — 2026-10-03

Removed the test-only Send restriction from both the facade and private send service. Send uses the existing App Master-provisioned environment for signing and transaction hashing; reconciliation already uses the record's environment. Identity, review and configuration must agree. Native authentication, funds/recipient validation, exact-review approval and durable duplicate-send protection remain enforced. Security review/testing are release work, not an SDK production-network switch. Earlier statements that production sending is blocked are superseded. Added fixture coverage for production signing and network mismatch; it has not been run. Verification remains deferred by user instruction.

Remaining feature gaps: off-device recovery/backup and permanent credential erasure need the concrete authorized vault and custody policy. Uncertain sends reconcile by original hash and remain pending without authoritative resolution; a terminal recovery/support path for never-confirmed sends is not implemented. GitHub push remains paused at the user's instruction. No network-settings decision is needed for this change.
## Agreed remaining scope — user-held recovery (2026-10-03)

The user selected a lightweight non-custodial design: Back up Rewards, Restore Rewards and Remove from this device. A Builder keeps their own backup; no external vault or App Master custody of Builder keys is required. Existing random-key accounts must keep the same identity. Backup confirmation precedes permanent local removal; removal does not destroy the account or its points. Implement through a dedicated SDK-controlled backup boundary rather than exposing keys through ordinary feature models. Uncertain-send recovery remains a separate implementation item.

These are planned features, not completed functionality. The obsolete vault dependency is removed. The earlier automatic rejection of unspecified seed export/erasure is historical and has not itself been overturned. No additional product-policy answer is needed to prepare the concrete user-held implementation; any new tool rejection must be handled on its actual terms. Verification remains deferred. The detailed remaining scope is maintained in `docs/walletsub-feature01/remaining-features-implementation-3oct.md`.
## Recovery implementation update — 2026-10-03

User-held encrypted BRB1 backup creation, same-key backup confirmation/import, authenticated permanent device removal with durable disabled markers, and ledger-proof pending-send resolution are now implemented in SDK and app UI. Recovery fields live in an SDK-owned page and no plaintext signing key enters feature state. Fresh restores can request App Master settings with initial version zero; service/API credentials are not exported. Native authentication and current-backup verification protect removal; public account/evidence remain for restoration. Unavailable/unsupported ledger proof keeps sends pending. The earlier vault dependency is obsolete.

Verification is deferred. The user explicitly authorized a user-triggered Copy encrypted backup button; it now copies only encrypted BRB1 text, never the plaintext signing key or password. The earlier clipboard approval blocker is resolved for this exact action. The implemented scope and remaining checks are maintained in `docs/walletsub-feature01/remaining-features-implementation-3oct.md`. Earlier planned/unimplemented recovery descriptions are superseded. GitHub push remains paused.
