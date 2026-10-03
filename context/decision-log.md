# Decision Log

This log records the current durable product and architecture decisions.

## 2026-10-03 - Retain custody during local access removal

No off-device recovery/key-erasure policy has been supplied. Implement removal
as authenticated device-access disablement, preserving custody and transaction
evidence. Do not silently erase the only signing material or reset activation to
permit a replacement account. Commit one protected disabled marker and read it
back; interrupted writes are resolved by stored state, without destructive cleanup.
Native restoration binds the retained account. Block removal while a send is
unresolved and serialize it against preparation/approval. The UI names these
consequences explicitly. Permanent erasure requires a separate recovery design.

Local sessions start locked, last five minutes, and relock on background/restart.
Lock revokes reviews/approvals and in-flight preparation. Public reads remain
available while locked; native per-transfer authentication can unlock access but
general unlock never grants payment authorization. App Master role navigation
does not change this SDK state or the disabled marker.

## 2026-10-03 - Single testnet send with durable uncertainty

Use only the verified App Master-controlled network and activated asset. Gate
production sends until release evidence exists. Sign exactly one reviewed payment
with the existing protected account credential; validate its current medium
threshold signing authority. Persist hash and public intent before POST, then
revalidate and consume native approval. Persist no seed or signed envelope here.
Serialize send/reconciliation within the app process. Pending evidence blocks a
new transfer across restart. Status checks use GET only and require exact signed
ledger evidence. Neither POST acceptance/rejection nor 404/timeout proves a ledger
outcome. Expired unresolved transactions stay blocked; a later explicit recovery
policy must address never-ingested/pruned hashes without blind resubmission.

## 2026-10-03 - Per-transfer device authentication, no broad unlock session

Use the native OS authentication prompt with biometric/device PIN/passcode fallback
for the exact SDK-prepared intent. This is device-owner authentication, not Builder
identity verification or App Master role authorization. No app-defined mock PIN
or reusable public approval token is accepted. Allow native-dialog inactivity,
but revoke on real backgrounding; do not persist/retry prompts across background.
Grant lifetime is at most 30 seconds and cannot outlive the two-minute review.
Revalidate funds, capacity, sender sequence, fee, identity and provider before/after
the prompt; changed state requires a new review. Signing consumes the private
grant once at the POST boundary and revalidates again. This application-layer gate does not
claim hardware-bound cryptographic key authorization. Testnet sends are implemented;
production and general wallet lock/recovery need security/device review.

## 2026-10-03 - Preparation is exact, short-lived, and separate from authorization

Use a single direct credit-asset payment intent and seven-decimal integer units.
Derive its reviewed maximum native fee from the maximum of latest ledger base
fee, fee-stats base fee, and charged p95, rejecting values outside unsigned XDR
fee range. No arbitrary fixed asset transfer cap is introduced. Check Rewards
funds, receiving capacity, native selling liabilities, and current ledger reserve
with sponsorship adjustments. Fee bid is an estimate, not guaranteed inclusion.
Retain only one exact private intent in memory, expiring two minutes from
preparation start. Replacement or failure invalidates previous reviews; restart
requires preparation again. No credentials, envelope, or submission are produced.
Recheck network/account state and require authorization during signing; neither a public review nor an unprotected navigation action can approve it.

## 2026-10-03 - Recipient inspection is an address-only read observation

Use the verified App Master-authorized asset and current provider, not a fixed
asset list or name directory. Inspect a single exact authorized trustline and
calculate remaining capacity with integer seven-decimal units. Reject self sends,
issuer returns, and accounts advertising memo routing in this initial slice;
issuer redemption and memo routing require explicit transfer support. This is a
bounded initial capability, not a restriction on App Master's asset selection.
Inspection must be repeated during transfer preparation and before submission;
the public observation cannot authorize a send. Normal UI navigation stops before
mock transfer review/outcomes until real preparation and authorization are ready.

## 2026-09-20 - Activation handshake is SDK-implemented; post-activation ops remain mock

### Decision

Treat first-time Rewards activation (Wallet SDK Steps 1–14) as implemented product
behavior behind the public `WalletSdk` facade. Keep post-activation Rewards
balance, receive, send, and history as presentation-only until a dedicated slice
ships. Keep provider-configuration rotation SDK-complete (Step 15) until Flutter
screens wire those APIs.

### Result

- Supersedes the “presentation-only” outcome recorded under
  `2026-09-18 - Use Wallet SDK QR Activation`.
- Runtime truth for this boundary lives in `context/current-state.md`.
- Analysis snapshot: `docs/walletsub-feature01/analysis-report.md`.
- Production/mainnet remains gated on two-device testnet verification and
  independent security approval (Step 16).

## 2026-09-19 - App Master distributor account uses direct secret import

### Decision

- Adopt the familiar existing-wallet import interaction used by wallets such as
  LOBSTR: the App Master types or pastes the existing Stellar secret into a masked
  Advanced field.
- The SDK validates it, derives the public account privately, and saves it in
  platform-protected storage only after live verification against the configured
  environment.
- Flutter receives only safe status and a masked public account identifier.
- Clear transient input after success or failure. Do not add QR transport, logs,
  clipboard writes, ordinary preferences, source configuration, or documentation
  containing the secret.
- Allow confirmed removal and replacement; failed verification preserves the
  previously working credential.

## 2026-09-16 - Establish theBuilderPros Identity

### Decision

Use `theBuilderPros` as the product identity across the Flutter application, platform configuration, assets, and repository.

### Result

- Dart package: `the_builder_pros`
- Android namespace and application ID: `com.thebuilderpros.thebuilderpros`
- iOS and macOS bundle ID: `com.thebuilderpros.thebuilderpros`
- Linux application ID: `com.thebuilderpros.thebuilderpros`
- Desktop binary: `the_builder_pros`
- Primary logo: `assets/images/the_builder_pros_logo.png`
- Canonical repository: `https://github.com/theBuilderPros/TheFlutterBuilderProsApp.git`

The supplied horizontal wordmark is used as provided. Derived square platform assets preserve the wordmark's aspect ratio with padding; no replacement monogram is introduced. User-facing text uses `theBuilderPros`, while the artwork retains its supplied visual casing.

Legal owner, production email and domain, store registration, release signing, and external account configuration require separate approval and must not be invented in source.

## 2026-09-17 - Use a Wallet-Only First-Release Surface

### Decision

Use Rewards Wallet as the initial and only active first-release feature, without top-level navigation.

### Result

- `Routes.wallet` is the initial route.
- Wallet activation, overview, receive, send, history, and security screens form the active UI surface.
- Profile has no active screen, controller, binding, or route.
- A future standalone Profile capability must be added explicitly within `lib/app/features/profile/`.

## 2026-09-17 - Keep Features Under `lib/app/features`

### Decision

Use `lib/app/features/` as the single feature root. Keep feature-owned widgets with their feature and organize larger screen sets by user journey with one route-level screen per implementation file.

### Result

- Wallet screens are grouped under activation, overview, receive, send, history, and security folders.
- Flow barrels and `wallet_screens.dart` contain exports only.
- Reusable Builder identity widgets live under `lib/app/features/profile/widget/`.

## 2026-09-18 - Use Wallet SDK QR Activation

### Decision

Use a mobile-to-mobile QR handshake between the Builder App and App Master App. Application code uses only a simple Wallet SDK facade, opaque QR values, safe review models, and safe outcomes. Every implementation-specific detail remains private to the SDK.

### Result

- Camera scanning and QR-image import share one SDK inspection path.
- App Master provides Overview, activation review, response QR, Advanced support information, and My Rewards.
- Advanced contains service/support information and the App Master-only NOWNodes
  configuration form required for offline provisioning.
- Protected credentials never cross between phones or enter Flutter presentation state.
- ~~Current QR and activation behavior remains presentation-only.~~ Superseded by
  `2026-09-20 - Activation handshake is SDK-implemented; post-activation ops remain mock`.

## 2026-09-18 - Provision Provider Configuration Through Device-Bound QR

### Decision

Keep the application backend-free for the current design. The App Master supplies
the Builder phone's provider configuration during activation and later rotates it
through a dedicated Settings QR handshake. Provider configuration is encrypted for
one Builder device, authorized by the App Master, versioned, expiring, and handled
entirely inside the Wallet SDK.

### Result

- The NOWNodes endpoint and API key are never hard-coded, committed, bundled in
  application assets, retained in ordinary Flutter state, or placed in a plaintext
  QR. App Master Advanced may accept the key through a masked field and must pass
  it immediately to the Wallet SDK, clear the field, and retain only safe status.
- The Builder activation request carries a device-specific configuration public
  key. The activation response may carry the encrypted initial provider
  configuration for that device.
- A later configuration update uses a distinct QR type and the same device binding.
- The Wallet SDK verifies App Master authorization, intended device, environment,
  expiry, replay status, and monotonically increasing configuration version before
  applying an update.
- The SDK keeps the previous configuration until the replacement passes a health
  check, then removes the old value from protected storage.
- The App Master must keep old and new provider keys active during a rotation
  window because offline devices cannot be updated remotely.
- App Master activation is blocked until the SDK reports a saved, healthy
  NOWNodes configuration. The encrypted device-bound configuration is included in
  every activation response.
- This approach improves controlled distribution and rotation but does not make a
  credential permanently secret from the owner of a compromised mobile device.

## 2026-10-03 - Share the private Horizon transport

Use one private `HorizonHttpClient` for the five default SDK Horizon consumers.
Request construction, credential headers, streaming limits, JSON decoding, and
typed transport failures belong in the shared core; domain parsing, retry policy,
and safe outcome mapping remain with each operation. The public facade is unchanged.

Apply the design's 5-second connect and per-chunk read defaults to all consumers,
plus a 15-second total activation-reconciliation deadline. The phase deadlines
standardize previously differing request mechanics and can return the existing safe
failure outcome earlier; therefore the refactor is not strictly timing-neutral.
Existing operation budgets, response caps, and result classifications are retained.
Rate-limit-aware retry, service-level rejection classification, and reconciliation
polling/backoff (design notes D1-D4) remain deferred.

Implement this foundation before daily Rewards. Verify activation/rotation on the
refactored build, and keep physical-device and independent security release gates
open until their evidence exists. See `docs/masterimplementationpaln3oct.md`.

## 2026-10-03 - Use App Master activation settings for daily Rewards

The user clarified that the design is neutral to fixed networks and assets and
App Master controls those settings. Daily SDK operations use the network, asset
code, and issuer from verified App Master-authorized activation. Do not introduce
hard-coded global asset settings or ask for fixed issuer decisions as a prerequisite.
Authorized asset changes need their own explicit flow; provider-key rotation alone
does not change the activation asset.

Receive shares the verified public account as an opaque account-address QR, without
inventing a mapped Reward-ID directory. The QR alone does not authorize network or
asset choices for send; those checks remain inside future recipient inspection.

## Recording Future Decisions

Add an entry when a decision materially changes product scope, architecture, data contracts, security boundaries, platform identity, or design rules. Record:

- date and decision
- reason
- resulting constraints or consequences
- superseding decision, when applicable

Do not use this file as an implementation status report or backlog.
## 2026-10-03 — Host-owned roster; recovery custody deferred

Keep the roster source and backend authorization host-injected, consistent with App Master control over policy. Remove sample Builder-access rows without inventing a backend. Defer verification as explicitly requested. Do not implement signing-seed export or irreversible erasure until an exact recovery destination, private payload, authorization and deletion policy are authorized. The proposed custody patch was rejected by automatic approval review and was not applied.
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
