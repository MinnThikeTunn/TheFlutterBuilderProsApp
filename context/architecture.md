# Architecture Context

## Stack

Local Rewards access uses private `RewardsAccessService` with the existing native
authentication adapter and credential store. Sessions begin locked, remain only
in memory for five minutes, and revoke on explicit lock or real backgrounding.
Lock cancels prepared/in-flight reviews and transfer approvals. Public reads remain
available while locked; every payment still requires its own exact native prompt.
The SDK checks the access session again at the POST boundary.

Removal is a single read-verified protected `rewards.device.access.v1` marker,
not multi-key credential erasure. It disables Rewards reads and new Builder
activation/signing across restart. Native restoration binds the retained account.
Unresolved sends block removal before authentication and again before commit.
Custody/configuration/activation/transaction evidence is preserved. UI caches are
cleared after removal. Failed/interrupted writes must be resolved by reading the
marker; a corrupt/unreadable marker blocks access. Permanent key destruction and
off-device recovery are outside this implemented retention policy.
Protected transfer authorization uses the private `TransferAuthorizationService`
and `TransferAuthenticator`, defaulting to native `local_auth` 3.0.1 (compatible
with Dart 3.9.2). The SDK revalidates the retained intent against fresh ledger
state before and after authentication. No UI boolean/status object is accepted
as approval. A private one-use grant is bound by exact review identity and expires
within 30 seconds; backgrounding, cancellation, replacement, and expiry revoke it.
Observers/timers exist only during attempts/grants. Native prompt inactivity is
allowed; paused/hidden/detached revoke approval.

Transfer preparation uses the same shared transport for recipient, sender,
fee-stats, and latest-ledger reads. Sender Rewards/native funds and sequence come
from one account snapshot. `RewardsAmount` centralizes exact decimal arithmetic
for balance parsing and preparation. The facade retains one private in-memory
intent with identity/configuration/sequence/fee bindings, a random review ID, and
two-minute expiry. Public immutable review data cannot authorize a send.
`getPreparedRewardsTransfer` checks identity/configuration/expiry; it does not
reread ledger funds. Authorization now rereads ledger state before and after the
native prompt. Testnet signing uses private `RewardsSendService`,
`RewardsSendStore`, and `RewardsSendClient`. Revalidate before signing and after
durable transaction identity is written; consume approval immediately before the
single POST. Persist only hash and public intent, never seed or signed envelope.
Restore/reconcile with hash GETs only. A matching signed ledger envelope is required
for confirmed/failed results; a 404, timeout, or mismatched evidence stays uncertain.
Pending evidence blocks another transfer across restart. Production sends remain
blocked pending physical-device evidence and security review.

Recipient inspection uses the private `RewardsRecipientClient` and the shared
Horizon transport, with a 128 KiB cap and 12-second total deadline. The facade
validates public StrKey addresses, verified active identity, configured environment,
and identity/provider consistency after reads. `RewardsRecipientView` exposes only
public account, environment, code, capacity, and observation time. No signing or
transfer approval is performed by inspection.


| Layer | Technology | Role |
| --- | --- | --- |
| UI framework | Flutter / Dart `^3.9.2` | Cross-platform application UI |
| Design system | Material 3 | Theme, navigation, controls, and typography |
| State and DI | GetX `^4.7.2` | Reactive state, bindings, dependency injection, and routing |
| Rewards boundary | `lib/wallet_sdk/` | Public `WalletSdk` facade; private crypto, XDR, Horizon, storage |
| Secure storage | `flutter_secure_storage` | Protected credentials and device-bound secrets |
| HTTP | `http` | Direct Horizon / NOWNodes transport inside the SDK |
| Crypto | `cryptography` | Ed25519, X25519, and related primitives inside the SDK |
| QR | `qr_flutter`, `mobile_scanner`, `image_picker` | Render and acquire opaque QR values |
| Icons | Material Icons | Application iconography |
| Testing | `flutter_test`, SDK `integration_test` | Unit/widget and controlled app integration scenarios |

Dependency versions are authoritative in `pubspec.yaml`.

## Application Structure

1. `lib/main.dart` starts the application.
2. `lib/main_app.dart` creates `GetMaterialApp`, applies the theme and initial binding, and registers centralized routes.
3. All application features live under `lib/app/features/` and use screen, controller, binding, and feature-local widget folders as needed.
4. Shared resources live under `lib/app/constant/`.
5. Shared base abstractions and application bindings live under `lib/app/core/`.
6. Feature-owned reusable widgets stay under that feature's `widget/` folder. Introduce `lib/app/widget/` only for components that are genuinely shared across unrelated features.
7. Rewards activation and provider logic live under `lib/wallet_sdk/`. Features may import only `lib/wallet_sdk/wallet_sdk.dart`.

Wallet and App Master are the active features. Wallet owns the Builder Rewards
experience, including the implemented first-time activation handshake and
presentation-only post-activation surfaces. App Master owns the Distributor
Dashboard, activation approval, Advanced provider/distributor setup, and links to
the same Wallet routes for dual-role testing. Reusable Builder identity components
live under `lib/app/features/profile/widget/`.

Recommended feature shape:

```text
lib/app/features/{feature}/
|-- binding/
|-- controller/
|-- screen/
`-- widget/
```

Folders are capability-driven rather than mandatory. For example, Profile currently contains only `widget/`; its screen, controller, binding, and route should be introduced only when a standalone Profile capability returns.

Features with several route-level screens may group them by user journey below `screen/`. The Wallet feature uses `activation/`, `overview/`, `receive/`, `send/`, `history/`, and `security/`. Each route-level screen has its own file; flow barrels and the top-level `wallet_screens.dart` contain exports only. Route-level screen implementations must not be consolidated back into barrel files.

See `current-state.md` for the exact runtime composition.

## State and Presentation Boundary

- Route-level controllers extend `BaseController`.
- Route-level screens extend `BaseView<T>`.
- GetX bindings own controller registration.
- Views observe reactive state with `Obx`.
- State mutations belong in controllers or services, not presentation widgets.
- Process-local UI state must not be treated as persistence.

## Data Boundary

Widgets must not access a backend directly. External data flows through typed services or repositories for concerns such as:

- authentication and sessions
- Builder profiles
- Rewards balances and operations

Map transport records to typed DTOs or domain models at the data boundary.

Rewards features depend only on a small `WalletSdk` facade and safe,
product-facing models. Screens and controllers treat QR values as opaque and must
not import SDK implementation libraries. Credential protection, QR inspection,
activation rules, completion, verification, provider communication, and detailed
diagnostics remain private to the SDK.

The production backend and authorization design are not yet selected. Private account material and privileged credentials must never ship in the app.

### Active Rewards persistence

New activation finalization writes `ProtectedActiveRewardsStore` before verified
submission status, after ledger verification and healthy provider promotion.
The private versioned record binds account, credential reference, network,
activation asset, response, and transaction identity. Finalization verifies the
credential derives the expected account and preserves an existing matching record
on retry. Separate stores use ordered recoverable writes; they are not a single
atomic transaction. A private migration service reconstructs missing identity from
retained authorized activation, matching submission evidence, current provider,
live ledger state, and the existing signing credential. Balance/Receive trigger it
lazily and coalesce concurrent attempts per SDK instance. It does not submit,
replace provider configuration, or erase recovery evidence.

### Private Horizon transport

`DirectRewardsHistoryClient` delegates through shared transport with explicit
operation query parameters. It owns bounded descending pagination, scoped opaque
cursors, and direct-payment parsing. Feature code receives immutable history views,
not provider records or links. Runtime identity/configuration checks remain in the facade.

The daily `DirectRewardsBalanceClient` also delegates through that same transport.
It owns exact decimal amount parsing, account/asset selection, and liability handling;
the facade checks protected identity/configuration and returns safe immutable views.

`DefaultWalletSdk` creates one `HorizonHttpClient` shared by the five default
Horizon consumers. The private transport owns URL/header construction, streaming
response limits, JSON decoding, and 5-second connect/per-chunk read deadlines.
Consumers own domain parsing, safe outcomes, retries, and operation budgets;
activation reconciliation has a 15-second total budget across both reads.
Raw HTTP-client constructor injection remains a compatibility adapter, while
whole-service fake injection remains available. The transport is not exported
through the public Wallet SDK facade.

## Resource Boundaries

- `AppColors`: brand and semantic colors
- `AppTheme`: Material component and typography themes
- `AppDimens`: reusable dimensions
- `AppString`: application strings
- `AppImages`: asset paths
- `assets/images/`: bundled image assets
- Native platform directories: launcher, package, and application branding

Visual rules and token values belong in `ui-context.md`. Current limitations belong in `current-state.md`; actionable architecture work belongs in `progress-tracker.md`.
## Host-owned App Master roster

`createWalletSdk(rosterProvider: ...)` accepts an `AppMasterRosterProvider`. Features use only `WalletSdk.getAppMasterRoster`; the SDK derives the configured authority's public account privately and validates page scope, entries and bounded cursors. The provider must enforce authorization at its data source on every request. The testing role switch grants no backend privileges. Roster entries describe application access, not ledger balances or asset freezing. Provider exceptions are masked; no signing credential is passed to this provider.
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
