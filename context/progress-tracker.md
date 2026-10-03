# Progress Tracker

Last synchronized: 2026-10-03

Current runtime facts and limitations are maintained in `current-state.md`.
Doc/code mismatch analysis: `docs/walletsub-feature01/analysis-report.md`.

## Completed

### Controlled wallet app integration coverage (2026-10-03)

- Added reusable real-app/controller/SDK/transport scenarios, a headless runner,
  SDK integration-test entry point, and an isolated Android integration package.
  Disposable generated accounts, native-auth adapter, network and storage are
  controlled; activation is a verified fixture and reconstruction is not OS restart.
- Covered Receive, exact single signed send, ledger evidence, balance/history,
  lock/removal/restoration, uncertain reconstruction, and blocked resend/removal.
- Dependency resolution, clean analysis and all 153 headless tests passed. Isolated
  Android APK built and its package was verified. Device installation was rejected
  with `INSTALL_FAILED_USER_RESTRICTED`; device scenarios remain unexecuted.
- Prepared `docs/walletsub-feature01/release-closeout-3oct.md` for independent review.
  Real native/storage/two-device evidence and security approval remain open.

### SDK local lock and retained-material access removal (2026-10-03)

- Replaced mock passcode/security navigation with native SDK access methods.
  Sessions start locked, expire after five minutes, and revoke on background or
  explicit lock. Lock cancels prepared/in-flight reviews and approval. Every send
  still independently authenticates; general unlock never approves a payment.
- Added protected read-verified disabled marker, pending-send removal blocking,
  account-bound native restoration, startup routing, and derived UI-data cleanup.
  Custody and transaction evidence remain protected; no seed deletion or ledger
  account closure is implemented. Corrupt/partial writes fail closed.
- Hardened activation cancellation/expiry cleanup to preserve active/unresolved
  credentials; new activation cannot replace active/unresolved custody.
- Added lifecycle, concurrency, interruption, storage-corruption, SDK restart,
  pending-transfer, and UI coverage. Physical-device/security gates remain open.
  Dependency resolution, clean analysis, all 151 tests, and Android debug APK
  build passed. The artifact hash is recorded in the device execution record.
  Off-device recovery and permanent key erasure remain separate policy work.
  Phase 8 integration is next.

### Testnet transfer signing and durable reconciliation (2026-10-03)

- Added private exact single-payment signing, source signing-weight checks,
  credential ownership verification, and durable hash/public-intent storage before
  one POST. Consume native approval at the submission boundary.
- Pending evidence blocks new transfers. Repeated review approval and restart
  restoration never POST again. Hash lookups require matching signed ledger
  evidence; 404/timeout/mismatch remain uncertain, including after expiry.
- Connected Confirm and send, safe outcome states, and latest-transfer status.
  Removed mock send outcomes. Production sending remains blocked.
- Dependency resolution, clean analysis, all 140 tests, and Android debug APK build
  passed. Tests cover
  signing intent, persistence failure, cancellation, duplicate calls, uncertainty,
  restart recovery, production rejection, and facade/UI integration.
- Physical-device/security gates remain open. Never-ingested/pruned transactions
  need an explicit recovery policy. Local lock/removal shipped in the next slice.

### Protected transfer authorization (2026-10-03)

- Added native biometric/device-credential authentication through a private SDK
  adapter, exact intent revalidation before/after prompt, and expiring one-use
  private grants. Cancellation/background/late-result/expiry/replay fail closed.
- The authorization slice initially left sending disabled; the subsequent testnet
  send slice now consumes this private gate. Mock authentication routes cannot create SDK approval.
- Added Android FragmentActivity, biometric permission/AppCompat themes, iOS
  Face ID usage description, compatible local_auth dependency/registrants.
- Formatted Dart; dependency resolution, clean analysis, all 130 tests, and Android
  debug APK build passed. Artifact hash is recorded in the device execution record.
  Physical prompt and Apple/Windows native builds/validation remain open.
  Signing, durable submission and reconciliation were completed in the later
  testnet send slice below.

### SDK-backed transfer preparation and review (2026-10-03)

- Added fresh recipient/funds checks, exact amount validation, dynamic native
  fee/reserve/sponsorship checks, and one private expiring intent.
- Replaced mock amount/review screens with SDK-backed preparation and immutable
  review data. Testnet submission was connected in the subsequent send slice.
- Formatted Dart; dependency resolution, clean analysis, and all 123 tests passed.
  Tests cover precision, funds/capacity, fees/reserves, duplicate preparation,
  replacement/expiry, and immutable review rendering. No native/package changes.
- Protected authorization and testnet signing/submission/reconciliation subsequently
  shipped. Physical-device and independent security gates remain open.

### SDK-backed recipient inspection (2026-10-03)

- Added exact activated-asset trustline/capacity checks and safe public observations.
- Connected camera, gallery, and manual-address input; removed the sample-recipient
  path from the normal Send entry. The screen stops before mocked transfer approval.
- Added private parser, facade boundary, and widget verification. Transfer
  preparation, fees, authentication, signing/submission/recovery remain next work.
- Device verification and independent security review remain open.
- Verification: formatted Dart, `flutter pub get`, clean `flutter analyze`, and
  all 117 tests passed. No native configuration/dependency changes or new APK.

### SDK-backed Rewards history (2026-10-03)

- Added scoped opaque pagination and bounded direct-payment history reads through
  the shared transport, with exact activated-asset and account validation.
- Replaced mock History rows with loading/empty/load-more/refresh/retry and stale
  retained-row states. No private identity directory or raw provider links exposed.
- `flutter pub get`, `flutter analyze`, and all 111 tests passed; changed Dart files
  formatted. Four SDK pagination/parsing tests and two widget tests were added.
- Current scope is confirmed direct Rewards payments. Path payments, local
  pending/rejected attempts, device verification, and security review remain open.
- No native/dependency changes; the prior APK predates this slice.

### Legacy active identity migration (2026-10-03)

- Added lazy migration for balance/Receive on already-verified installations with
  missing protected active identity, using retained cryptographic activation and
  live ledger evidence through the current provider settings.
- Preserved provider rotation, legacy status, credentials, and recovery evidence;
  added shared in-flight migration and safe retry without account creation/submission.
- `flutter pub get`, `flutter analyze`, and all 105 tests passed. Seven new tests
  cover expiry, concurrency, rotated configuration, binding/tamper rejection,
  missing credentials, offline recovery, and protected-store failure.
- Changed Dart files were formatted. No dependency/native changes or new APK.
  Physical-device and independent security review remain open.

### Daily Rewards balance (2026-10-03)

- Added `getRewardsBalance()` with safe immutable models and a private client using
  shared Horizon transport, protected provider settings, and the activated asset.
- Added exact decimal parsing/subtraction, authorization/liability handling,
  account/asset and network checks, bounded reads, and safe failures.
- Replaced Overview's mock amount and refresh action with automatic loading,
  guarded refresh, observation time, and stale/error/retry behavior.
- `flutter pub get`, `flutter analyze`, and all 98 tests passed. Seven additional
  tests cover amount parsing, trustline/account failures, facade configuration,
  redaction, and Overview refresh/retry. Changed Dart files were formatted.
- No native configuration or dependency changes; no new APK built. Physical-device
  verification, legacy migration, history, and sensitive lifecycle work remain open.

### Active identity and Receive slice (2026-10-03)

- Added versioned protected active identity and ordered activation finalization
  with credential ownership, submission binding, and conflict checks.
- Retained durable identity after final-status write failure for idempotent retry.
- Added `getRewardsReceiveIdentity()` and SDK-backed Receive loading, exact public
  account QR/copy, safe failure, and retry states.
- Network and asset follow verified App Master-authorized activation; no fixed
  network/code/issuer was introduced.
- `flutter pub get`, `flutter analyze`, and all 91 tests pass; changed Dart files
  were formatted. Added 10 persistence/Receive SDK tests and 2 Receive widget tests.
- Legacy migration, balance/history, protected send, lock/removal, and device/security
  gates remain open. The earlier debug APK predates this slice.

### Shared Horizon transport (2026-10-03)

- Added a private streaming transport shared by all five default Horizon consumers,
  preserving whole-service fakes and raw-client compatibility injection.
- Centralized request construction, headers, response caps, decoding, and typed
  low-level failures; retained consumer-owned parsing and safe result mappings.
- Added shared 5-second phase deadlines and a 15-second reconciliation operation
  budget. Deferred rate-limit/classification/polling policy changes remain open.
- Preserved the public Wallet SDK facade and all 69 existing test expectations.
- `flutter pub get`, `flutter analyze`, and all 79 tests passed; changed Dart
  files were formatted. Two-device and independent security gates remain open.
- Delivery sequence: `docs/masterimplementationpaln3oct.md`.
- `flutter build apk --debug` passed and produced the refactored device-test APK
  at `build/app/outputs/flutter-apk/app-debug.apk`.

### Documentation sync (2026-09-20)

- Added `docs/walletsub-feature01/analysis-report.md`.
- Synced `context/current-state.md`, `context/decision-log.md`,
  `context/progress-tracker.md`, `context/architecture.md`, and
  `context/ui-context.md` with the implemented activation boundary.
- Refreshed `docs/QRhandshakespec.md` status, `stepbystep.md` baseline,
  `01-screen-list.md`, `walletSDKspec.md`, activation/user-story/plan specs,
  and `analysis-report.md` follow-up notes.

### Repository and Branding

- Renamed the project and package to theBuilderPros / `the_builder_pros`.
- Configured the Android application ID as `com.thebuilderpros.thebuilderpros`.
- Configured the canonical repository and `main` branch.
- Added the official source logo.
- Replaced Android launcher icons and the web favicon.
- Updated repository documentation for the mobile product.

### UI Prototype

- Added the presentation-only Rewards wallet flow under `lib/app/features/wallet/` from the wallet sub-feature screen specification.
- Refactored Builder identity into a reusable shared card used by the Rewards activation entry screen.
- Added mock screens for activation, authentication, wallet overview, receive, send scan/amount/review/outcome, history, locked state, and wallet removal.
- Added an App Master feature with activation capacity, Rewards availability, Builder access, activation-request scan/image-import actions, activation review, and activation-QR preview. Capacity, request inspection, and response QR were later replaced by SDK-backed behavior; Builder-access rows remain mock.
- Removed provider-specific terminology from Builder-facing and ordinary App Master UI. NOWNodes configuration is the sole App Master Advanced exception; Advanced now saves through the Wallet SDK and clears the key after submit.
- Added explicit switching between the App Master and shared Builder Rewards surfaces for testing both roles.
- Split route-level Wallet screens into one implementation file per screen, grouped by user journey with export-only barrels.
- Centralized reusable Wallet presentation components under the Wallet feature.

### Functional Wallet SDK Slice

- Added the public `WalletSdk` facade with safe Builder and activation-request models.
- Implemented Start activation with validation, duplicate-tap prevention, safe progress, and safe failures.
- Added protected local setup, persisted 15-minute pending requests, restoration, cancellation, and rollback behavior behind the SDK.
- Replaced the mock request icon and ID with a real generated QR, request ID, expiry, and exact copy action.
- Added production SDK lifecycle tests and injected a fake SDK into widget tests.
- Replaced `stellar_flutter_sdk` with generic Ed25519 key generation and a private
  SEP-23 StrKey codec.
- Split activation QR encoding, protected credentials, pending-request persistence,
  time, and token generation into private SDK services.
- Added official-vector, invalid-input, deterministic key derivation, expiry cleanup,
  and persistence-rollback tests.
- Added safe provider-configuration facade models, strict NOWNodes candidate
  validation, protected pending storage, safe status restoration, explicit clearing,
  and transactional rollback when safe metadata persistence fails.
- Wired confirmed Builder activation cancellation to SDK cleanup and added safe,
  retryable failure behavior.
- Made `WalletController` application-scoped to prevent disposed text controllers
  from being reused during wallet route replacement on physical devices.
- Added a private direct Horizon HTTP health client with NOWNodes header injection,
  network-identity checks, bounded response parsing, safe failure mapping, total and
  phase deadlines, and bounded transient retry with jitter.
- Added atomic pending-to-active configuration promotion and verified that failed
  replacement health checks preserve the previous working configuration.
- Connected App Master Advanced to the public provider-configuration facade with
  environment selection, duplicate-submit protection, transient key clearing, safe
  error display, and restoration of non-secret status metadata.
- Added widget coverage proving successful configuration and rejected-key paths do
  not retain or render the submitted key.
- Reproduced the live NOWNodes response, added Horizon HAL JSON compatibility, and
  kept its credential-bearing link payload confined to the private transport layer.
- Removed the temporarily documented live API key; it must be rotated before reuse.
- Added a protected, installation-stable X25519 device-configuration identity that
  is separate from the Builder activation signing identity.
- Upgraded activation requests to a canonical, bounded v2 envelope containing only
  the opaque device ID and configuration public key, with strict restore validation
  and legacy-v1 invalidation.
- Added tests for deterministic encoding, malformed/oversized/unsupported/expired/
  altered rejection, stable device binding, private-key exclusion, and v1 cleanup.
- Added real App Master QR camera scanning and gallery-image decoding behind a
  focused adapter, including exact-value forwarding and safe cancel, denied,
  unreadable, and multiple-code outcomes.
- Declared purpose-specific Android and iOS camera/photo permissions and added
  adapter plus widget coverage for the Step 6 acquisition paths.
- Added SDK-backed App Master request inspection, consumed-request checks,
  protected pending-review restoration, and safe public review models.
- Replaced mock App Master review identity with validated Builder name, phone,
  request ID, expiry, and plain-language setup rows.
- Added App Master direct distributor-secret import with masked entry, explicit
  confirmation, private key derivation, live account verification, protected
  storage, safe masked status, replacement safety, and confirmed removal.
- Added authenticated direct account and fee-status reads, private ledger parsing,
  and a safe App Master overview facade for live capacity, Rewards availability,
  service status, and refresh behavior.
- Added the version-pinned Stellar XDR v27 activation subset, committed generator,
  strict RFC 4506 codec, limited classic-envelope round trips, transaction hashing,
  Ed25519 signing/verification, signature preservation, and fail-closed rejection
  of every unsupported protocol variant.
- Added SDK-backed App Master activation approval with live sequence and fee policy,
  exact three-operation construction, protected distributor signing, device-bound
  provider encryption, response authorization, and real QR rendering.
- Added Builder response camera/gallery acquisition, device-bound decryption,
  response and transaction authorization checks, exact policy inspection, replay
  rejection, protected pending-response storage, and safe review UI.
- Added exact-response Builder approval, repeat policy validation, protected local
  signing, pre-submit hash/state persistence, single direct transaction submission,
  duplicate prevention, and safe submitted/rejected/uncertain outcomes.
- Added direct transaction/account reconciliation, expected Builder Rewards-state
  verification, provider candidate health-check/promotion, durable active state,
  and startup restoration without duplicate submission.
- Wired the existing provider-configuration rotation APIs into distinct Builder
  and App Master Flutter flows: request QR, scan/gallery acquisition, safe review,
  update QR, apply outcome, duplicate-action guards, and focused widget coverage.

### Design System

- Applied neutral backgrounds and white surfaces.
- Centralized core theme colors and Material component themes.
- Applied orange primary actions and restrained violet selection states.
- Added the mixed orange/violet page-title underline.

### Verification Record

- `flutter analyze` passed on 2026-09-18.
- `flutter test` passed all 27 Step 4 SDK, protocol, transport, lifecycle, and widget
  tests on 2026-09-18.
- `flutter analyze`, all 32 Step 5 tests, and `flutter build apk --debug` passed on
  2026-09-19.
- `flutter analyze`, all 38 Step 6 tests, and `flutter build apk --debug` passed on
  2026-09-19.
- `flutter analyze`, all 43 Step 7 tests, and `flutter build apk --debug` passed on
  2026-09-19.
- `flutter analyze`, all 47 Step 8 tests, and `flutter build apk --debug` passed on
  2026-09-19.
- `flutter analyze`, all 49 Step 9 tests, and `flutter build apk --debug` passed on
  2026-09-19.
- The Step 10 generator reproduced its checked-in constants; `flutter analyze` and
  all 58 tests passed on 2026-09-19. No native build input changed.
- `flutter analyze` and all 60 Step 11 tests passed on 2026-09-19. No native build
  input changed.
- `flutter analyze` and all 60 Step 12 tests passed on 2026-09-19. No native build
  input changed.
- `flutter analyze` and all 63 Step 13 tests passed on 2026-09-19. No native build
  input changed.
- `flutter analyze` and all 64 Step 14 tests passed on 2026-09-19. No native build
  input changed.
- `flutter analyze` and all 64 Step 15 tests passed on 2026-09-19. No native build
  input changed.
- `flutter analyze` and all 67 Step 16 automated tests passed on 2026-09-19.
- `flutter build apk --debug` produced `build/app/outputs/flutter-apk/app-debug.apk` on 2026-09-18.
- `flutter pub get`, `flutter analyze`, and all 69 tests passed after the Flutter
  configuration-rotation integration on 2026-10-03.

These entries record completed checks at that point in history. They do not replace verification after later changes.

## Active Backlog

The gated implementation order is maintained in
`docs/walletsub-feature01/stepbystep.md`. Steps 1 through 9 are complete and device
verified. Steps 10–16 are implemented and pass automated checks. Capability claims
belong in `current-state.md`.

1. Complete the Step 16 two-physical-device testnet activation and
   provider-rotation gate, then obtain independent security approval before
   production/mainnet.
2. Replace mock post-activation Rewards balance, receive, send, and history with
   SDK-backed operations when that slice is planned.
3. Add loading, empty, offline, and unauthenticated states to remaining flows.
4. Add integration tests on physical devices.
5. Add a standalone Profile screen, controller, binding, and route only when that
   feature returns to scope.

Backlog order may change through an explicit planning decision. Architectural
direction belongs in `architecture.md`.
## Latest work — 2026-10-03

Implemented the host-injected App Master roster contract, scoped pagination, safe errors, controller loading and dashboard/Advanced roster rendering. Backend integration and authorization belong to the host provider and remain outstanding. Verification is deferred by user instruction. Recovery export and permanent erasure were not applied: automatic approval review requires a concrete authorized vault, payload and deletion policy.
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
