# Wallet Master Implementation Plan — 3 October 2026

Status (2026-10-03): Phases 0 and 1 complete. Phase 5 balance, Receive, migration,
and direct-payment history are automated-verified. Phase 6 recipient inspection,
exact transfer preparation, immutable review, and protected per-transfer device
authorization, testnet signing/single submission, durable hash recovery, and SDK
outcomes, local lock, and retained-material access removal are implemented.
Physical-device/security gates remain open; Phase 8 integration is next.
Phase 2 awaits the two-device testnet run; Phase 3 awaits independent review.
Device/security gates and remaining lifecycle work are open.

## Objective and implementation order

Complete the shared Horizon transport foundation first, verify the existing activation and provider-rotation flows against that foundation, then deliver the remaining daily Rewards capabilities through the Wallet SDK.

The transport refactor is a bounded prerequisite for new Horizon consumers. Implementing balance, history, and send before it would increase the migration and regression surface. Keep the refactor separate from new financial functionality so its behavior can be assessed independently.

| Phase | Delivery | Dependency | Completion evidence |
| --- | --- | --- | --- |
| 0 | Establish current baseline | None | Working-tree inspection, analysis, and test results |
| 1 | Shared Horizon transport refactor | Phase 0 | Transport, consumer, composition, and regression tests |
| 2 | Existing activation/rotation device gate | Phase 1 | Two-device testnet matrix on the refactored build |
| 3 | Independent security review | Phase 2 | Findings resolved and approval recorded for the reviewed scope |
| 4 | Daily Rewards SDK contract and policies | Foundation verified; product decisions supplied | Reviewed contracts and explicit policy decisions |
| 5 | Balance, receive, and history | Phase 4 | SDK-backed screens and automated/device evidence |
| 6 | Protected send | Phase 4 authorization policy and required read models | Reviewed prepare/authorize/submit/reconcile lifecycle |
| 7 | Complete lock and removal lifecycle | Phase 4 recovery policy; send authorization implemented | Protected lifecycle and failure/recovery evidence |
| 8 | Integration and release closeout | Applicable preceding phases | Scope-specific device/security approval and synchronized documentation |
| 9 | App Master Builder-access roster | Approved data source and authorization architecture | Authorized real roster replacing mock rows |

Phase 4 design can proceed while external device/security work is scheduled. External gates do not prohibit development on testnet, but must remain open until evidence is supplied. Production/mainnet remains blocked. Security approval for activation does not automatically approve later send, authentication, or removal capabilities.

## Sources and current baseline

- [Horizon transport refactor design](superpowers/specs/2026-09-23-horizon-transport-refactor-design.md): authoritative detailed scope and acceptance criteria for Phase 1.
- [Wallet scope/status, 3 October](walletsub-feature01/walletdevscopestatus3Oct.md): current screen and capability inventory.
- [Follow-up implementation plan](walletsub-feature01/fixingplan2ndoct.md): detailed rotation, device, security, and daily Rewards work.
- [Gated SDK sequence](walletsub-feature01/stepbystep.md), [SDK specification](walletsub-feature01/walletSDKspec.md), and [screen inventory](walletsub-feature01/01-screen-list.md).
- [Current runtime](../context/current-state.md), [architecture](../context/architecture.md), and [progress](../context/progress-tracker.md).

Baseline before Phase 1, inspected on 3 October:

- Activation, App Master provider/distributor setup, and configuration rotation are SDK-backed.
- Rotation Flutter flows are already implemented; do not repeat the earlier UI implementation phases.
- Five Horizon consumers still own independently constructed default HTTP clients. The approved shared transport refactor is not implemented.
- Daily balance, receive, send, history, authentication/lock, and removal remain presentation-only. App Master Builder-access rows are mock.
- The latest recorded checks passed `flutter pub get`, `flutter analyze`, and 69 tests. These are historical results, not a fresh baseline run for this plan.
- Two-physical-device activation/rotation verification and independent security approval remain open.

The September refactor design refers to 67 existing tests. Use the current suite, including October rotation coverage, as regression protection. The earlier follow-up plan also retains a stale baseline statement that rotation has no Flutter UI; its October status note and the current code supersede that statement. This master plan takes precedence for delivery order while linked specifications retain ownership of detailed behavior.

## Phase 0 — Baseline and change isolation

1. Inspect repository instructions, relevant context, working-tree status, and diffs. Preserve existing user changes, including the October rotation implementation and documentation.
2. Confirm the current facade, five Horizon consumers, and application import boundary against code.
3. Run baseline checks independently from the repository root. Record actual test count and any pre-existing failures.
4. Resolve blocking discrepancies before changing transport behavior.

Exit: a reproducible baseline and a focused change scope are recorded. Do not treat historical checks as current verification.

## Phase 1 — Shared Horizon transport

Implement the approved design without adding daily Rewards methods or UI changes:

- Add private `HorizonHttpClient` and typed low-level failures under `lib/wallet_sdk/src/transport/`.
- Centralize URL construction, common headers, streaming reads, phase timeouts, response caps, and JSON decoding. Each operation retains domain parsing, result interpretation, retry decisions, and safe failure mapping.
- Wire one transport and one default HTTP client into health, distributor status, activation submission, activation reconciliation, and distributor account verification through `DefaultWalletSdk`.
- Preserve whole-service fake injection and raw `http.Client` compatibility adapters. Reject simultaneous `client` and `transport` arguments in all build modes.
- Add the specified injectable 15-second total reconciliation deadline across both sequential reads.
- Preserve health retry policy and per-operation response limits. Keep the public `wallet_sdk.dart` facade unchanged.
- Keep deferred D1–D4 retry/classification/polling policies outside this change.

Before implementation, resolve any ambiguity between the design's “no other runtime behavior changes” statement and applying shared 5-second connect/read phase deadlines to consumers that currently use different timeout mechanics. Document the intended compatibility interpretation and test it; do not silently broaden the behavior change.

Resolved: apply the explicitly specified shared phase defaults. Domain outcomes and
operation budgets remain unchanged, but non-health callers can return their existing
failure outcome earlier. This timing standardization is recorded in the design and
decision log. The new tests cover phase timeout taxonomy and the reconciliation budget.

Implementation record: the private shared core, all five delegates, factory wiring,
compatibility adapters, and reconciliation deadline are implemented. Analysis and
all 79 tests pass. The public facade and existing tests were not changed.

Device inventory found one physical Android device (Android 11), so the required
two-device evidence is still open. Use [the execution record](walletsub-feature01/two-device-verification-3oct.md)
for the next gate.

`flutter build apk --debug` also passed on 2026-10-03. The device-test artifact is
`build/app/outputs/flutter-apk/app-debug.apk`. That original artifact predated the
active identity and Receive slices; the current authorization build has replaced
it as recorded in the device execution record. Runtime network/asset settings
come from App Master.

Verification:

- Test URL/header construction, streaming byte boundaries, timeout/network taxonomy, and JSON decoding.
- Test delegation by all five consumers and conflicting constructor arguments.
- Test SDK composition through one injected transport and the bounded reconciliation deadline.
- Preserve current regression expectations; explain any necessary expectation change before altering it.
- Run formatting, dependency resolution, analysis, and the full test suite.

Exit: approved refactor criteria pass, October rotation coverage remains green, and architecture/decision/status documentation reflects the verified change.

## Phase 2 — Two-device activation and rotation gate

Run the existing Step 16 matrix on the refactored build using two physical devices and disposable testnet accounts:

- Complete App Master setup and Builder activation through ledger reconciliation.
- Exercise camera/gallery acquisition, expiry, tampering, replay, wrong device/environment, rejection, and duplicate actions.
- Interrupt and restart during pending/uncertain states; verify restoration without blind resubmission.
- Complete provider rotation and test downgrade, expiry, replay, wrong-device/environment, interruption, and failed health checks.
- Verify every failed replacement preserves the prior healthy configuration.
- Exercise the provider-key overlap/revocation procedure in the existing operations SOP.

Record build identifier, device/OS versions, environment, case outcomes, and redacted evidence. Fix defects and rerun affected cases. Keep credentials and protected payloads out of reports and source control.

Exit: complete passing matrix on the actual refactored build. Device access and test credentials must be supplied when this phase is executed.

## Phase 3 — Independent security review

Prepare a review package covering the facade, QR authorization/device binding, XDR subset, protected storage, transport, transaction signing/submission/reconciliation, provider rotation, and device evidence.

Track findings with severity, owner, remediation, and retest evidence. Close release-blocking findings and record the independent review outcome. This gate requires an independent reviewer; automated checks alone cannot close it.

Exit: approval for the existing activation/rotation scope, with any accepted residual risks documented. Later sensitive capabilities require additional review of their own changes.

## Phase 4 — Daily Rewards contract and policy

User clarification: the design is neutral to specific networks/assets and App Master
controls them. Use the verified App Master-authorized activation network, code, and
issuer as the runtime daily Rewards configuration. No user-supplied fixed asset is
required. Avoid a global hard-coded allow-list. Authentication and recovery design
remain separate prerequisites for protected send and removal.

Implementation prerequisite (2026-10-03): new activation finalization now persists
a protected, versioned account/asset/credential-reference record before verified
status. Credential-account and submission-evidence bindings are enforced, and
failed final status writes retain the identity for idempotent retry. This records
the App Master-authorized activation asset. Legacy migration has subsequently been
implemented as described in Phase 5; remaining daily-operation contracts stay open.
The original transport-only APK predated these slices; see the updated device
execution record for the current native-authorization build.

Design preparation (2026-10-03): [daily Rewards contract draft](walletsub-feature01/daily-rewards-sdk-contract-draft-3oct.md)
records proposed read/transfer APIs, active-identity persistence and migration needs,
verification cases, and the decisions awaiting user input. This draft is not an
approved contract or implemented functionality; Phase 4 remains open.

Define the next public SDK slice before replacing mocks:

- Safe immutable models for balance, receive identity/QR, paginated history, recipient inspection, transfer intent/review, outcomes, and reconciliation.
- Stable failure codes, cancellation, retry rules, stale/offline behavior, and persistence boundaries.
- Explicit supported network and Rewards asset code/issuer policy; no ambiguous asset inference for daily operations.
- Amount precision, available balance, liabilities/reserves, fee presentation, transfer limits, and recipient validation.
- Local authentication, protected sessions, lock/relock behavior, and authorization binding to the exact reviewed transfer.
- Recovery/removal consequences, retained pending-transaction evidence, and supported restoration paths.
- Public receive QR format and compatibility rules.

Record unresolved product choices as decisions needed before dependent implementation. Add fake SDK support alongside the contract. Preserve feature imports through the public facade only.

Exit: reviewed contract, testable lifecycle rules, and explicit policies. Do not infer a production backend, identity-verification service, or authorization model from existing role-switch UI.

## Phase 5 — Read-only daily Rewards

History slice (2026-10-03): implemented safe paginated direct Rewards payment reads,
scoped cursors, descending ordering, exact amounts, and SDK-backed history UI with
loading, empty pages, load-more, refresh, retained stale data, and retry. Analysis
and all 111 tests pass. Balance, Receive, migration, and direct-payment history
are automated-verified; physical-device checks remain open. Path payments and local
pending/rejected attempts are not included in the current history slice.

Legacy migration (2026-10-03): balance and Receive lazily reconstruct missing active
identity only after retained response/device/request/transaction checks, current
provider ledger verification, and signing credential ownership validation. It
preserves rotated settings and recovery evidence, permits an already-spent zero
balance, and never creates/submits activation. Concurrent callers share one attempt;
failed migration is safely retryable. Physical/security review remains open.

Partial implementation (2026-10-03; analysis and all 91 tests pass): Receive now uses a public SDK method and safe
view model, a real public-account QR, exact copy, loading, failure, and retry states.
It depends on the new protected active identity; legacy migration remains open.
History was subsequently implemented as described above. Receive was delivered before balance because it
can use verified local identity without new ledger reads or asset policy choices.

Balance slice (2026-10-03): the SDK now reads the exact App Master-authorized asset
through shared transport, with exact decimal total/available amounts, network and
identity checks, bounded responses, and a total deadline. Overview automatically
loads, guards duplicate refresh, shows observation time, and marks retained data
stale on failure. Validated legacy migration is now implemented; paginated history
is now implemented as described above. Migration checks passed analysis and all 105 tests.

Deliver three small SDK-to-UI slices in order:

1. **Balance (B-05):** private account/asset parsing through shared transport; safe balance/status/refresh models; loading, stale, offline, and error states.
2. **Receive (B-06):** real public receive identity and approved QR format; exact copy and rendering; no private material exposed.
3. **History (B-12):** typed bounded reads, pagination/cursor handling, ordering, refresh, and empty/offline states.

Replace each mock only after its SDK behavior passes tests. Cover asset/network mismatch, malformed responses, unavailable services, and lifecycle restoration where applicable. Verify against known testnet account state on devices.

Exit: overview, receive, and history display real SDK-backed data with honest freshness and failure states.

## Phase 6 — Protected send

Recipient slice (2026-10-03): `inspectRewardsRecipient` checks valid public
accounts, verified runtime identity/network/asset, exact authorized trustlines,
and capacity after buying liabilities. Provider/identity changes invalidate results.
Camera/gallery/manual input shows safe observation data. Self sends, memo routing,
and issuer returns are unsupported in this initial slice.

Preparation slice (2026-10-03): exact positive seven-decimal amounts are checked
against fresh sender Rewards funds and recipient capacity. Native fee funding
uses current ledger reserves and sponsorship-adjusted minimum balance plus selling
liabilities. A single-operation fee bid uses the maximum of ledger/base fee and
charged p95. One private exact intent expires after two minutes; replacement,
failure, identity/provider changes, and restart require new preparation. Amount
and review screens show immutable SDK data. The subsequent testnet send slice
connects protected signing/submission and durable hash reconciliation.
Verification: formatted Dart, dependency resolution, clean analysis, and all
123 tests passed. Physical-device/security evidence remains open.

Authorization slice (2026-10-03): SDK-owned native biometrics/device-credential
prompt replaces mock approval in the Send review. Ledger intent is revalidated
before/after the prompt. Private approval is single-use, expires within 30 seconds,
and revokes on cancellation/background/replacement/expiry/changed state. Public
status cannot authorize signing. Native Android/iOS setup and plugin registration
are added; physical native-prompt verification remains open. Authorization alone
does not submit; the subsequent approve method consumes its private grant.
Verification: dependency resolution, clean analysis, all 130 tests, and Android
debug APK build passed. See the device execution record for its artifact hash.
Physical prompts and Apple/Windows builds have not been verified.

Implement B-07 through B-11 as a separately reviewed slice:

Testnet submission slice (2026-10-03): `approveRewardsTransfer` authenticates,
revalidates, verifies credential ownership/current signing authority, and signs
the exact reviewed single payment. Protected public hash/intent evidence is
written and read back before one POST. Revalidate again and consume approval at
that boundary. Repeated approval and restart restoration never resubmit. Matching
signed ledger evidence determines confirmed/failed outcomes; 404/timeout/mismatch
remain uncertain and block another send, even after expiry. Never-ingested/pruned
hashes need a later explicit recovery policy. SDK outcome/status screens replace
mock send results. Production sending remains blocked.
Dependency resolution, clean analysis, all 140 tests, and Android debug APK build
passed. Physical-device
testnet/security review gates remain open. Phase 7 subsequently implemented local
lock/removal; Phase 6
release verification is not complete.

- Inspect recipient QR/address with network and asset policy checks.
- Validate exact amounts, fees, limits, and available balance inside the SDK.
- Prepare an immutable safe review and privately retain the exact transaction intent.
- Implement actual protected authentication/session authorization before signing. Bind approval to the reviewed recipient, asset, amount, and fee; reject expired or changed reviews.
- Extend the private protocol only where the approved send design requires it; preserve fail-closed parsing and signing boundaries.
- Persist transaction identity and pre-submit state before one submission. Prevent duplicate approval/submission and reconcile accepted, rejected, and uncertain outcomes after interruption or restart.
- Integrate the send screens with SDK outcomes and update balance/history appropriately.

Verification must cover duplicate taps, insufficient funds, precision/limit failures, expired review, authentication failure/cancellation, network loss around submission, restart recovery, and ledger-confirmed outcomes. Obtain security review and physical-device testnet evidence before production use.

Exit: real transfers follow prepare/review/authorize/sign/submit/reconcile with durable recovery and no blind resubmission.

## Phase 7 — Complete lock and removal

Implementation slice (2026-10-03): native SDK unlock, explicit/background/restart
lock, five-minute in-memory sessions, cancellation of reviews/in-flight preparation,
and POST-boundary session checks are implemented. Every send still authenticates
separately; public reads remain available while locked. Security screens no longer
accept mock passcodes or route-only approval.

Removal uses a conservative retention policy because off-device recovery and
permanent key erasure are not defined: native authentication writes/read-verifies
one protected disabled-access marker. Rewards reads and Builder activation/signing
are blocked across restart; protected custody and transaction evidence are retained.
Pending sends block removal. UI caches are cleared and native restoration binds the
existing account. Partial writes/corrupt state fail closed. No credential destruction
or ledger-account closure is implemented. Device/security gates remain open; the
Phase 7 release exit is not yet satisfied. Phase 8 integration is next.
Verification: formatted Dart, dependency resolution, clean analysis, all 151 tests,
and Android debug APK build passed. Physical-device and Apple/Windows checks remain
open; the device record identifies the current artifact.

Build on the authorization mechanism required by Phase 6:

- Replace B-13 mock lock behavior with the approved session lifecycle, background/restart rules, and guarded access to sensitive SDK actions.
- Replace B-14 simulated removal with explicit consequences, confirmation, and safe protected-material cleanup.
- Define and test interrupted cleanup, partial storage failure, pending/uncertain transactions, and subsequent startup state. Preserve the evidence required by the approved recovery policy.
- Verify that removal and locking cannot be bypassed by navigation or role switching.

Exit: lock protects the defined operations, removal meets its recovery policy, and sensitive lifecycle behavior has device/security verification.

## Phase 8 — Integration and release closeout

Automated slice (2026-10-03): shared real-app/SDK/transport scenarios now run
headlessly and have an `integration_test` device entry point. They cover verified-
fixture startup, Receive, exact send/hash evidence, balance/history, lock/removal/
restoration, and uncertain reconstruction with blocked resend/removal. Native auth,
network and storage are controlled; actual activation/rotation, OS restart/storage
and native prompts still require the device matrix. All 153 headless tests and clean
analysis passed. Isolated Android APK/package verified; device installation was
blocked by `INSTALL_FAILED_USER_RESTRICTED`, so no device scenario passed yet.

Independent review package: `docs/walletsub-feature01/release-closeout-3oct.md`.
Phase 8 release exit remains open. Production sending stays blocked; Phase 9
roster still requires its approved data source and real authorization design.

Introduce integration coverage incrementally during earlier phases, then complete the final matrix:

- Add `integration_test/` coverage for high-value navigation, protected actions, and restart/interruption paths using controlled dependencies where practical.
- Verify activation, rotation, read operations, send, lock, and removal together on physical devices.
- Complete remaining loading, empty, offline, stale, and unauthenticated states within the delivered scope.
- Review platform permissions and package/build changes introduced by new dependencies.
- Obtain scope-specific security approval, close release-blocking findings, and confirm operational readiness before any production/mainnet release.

Notifications, bundled fonts, production identity/phone verification, backend selection, and production role authorization are separately tracked product/platform gaps. Decide which are release requirements explicitly; this plan does not mark them implemented or silently authorize new services.

## Phase 9 — App Master roster

Keep mock Builder-access replacement separate from core wallet delivery. First decide its data source, ownership, privacy boundaries, and production App Master authorization. The current app has no general backend, and its testing role switch is not authorization.

Implement only after that architecture is approved. Cover authorized/unauthorized access, pagination, loading/empty/offline states, and safe data presentation.

Exit: roster rows come from the approved source under real authorization. Do not describe mock rows as administration functionality.

## Verification and documentation rules

For each implementation phase, run relevant checks independently from the repository root:

```powershell
dart format <changed Dart files>
flutter pub get
flutter analyze
flutter test
```

Build affected platform artifacts when native configuration, dependencies, permissions, packaging, or release output changes. Use focused tests during development and the full relevant suite for completion. Record checks that could not run and their concrete blockers. A documentation-only change does not require Flutter runtime checks.

Synchronize the owning documents when facts change:

| Changed fact | Document |
| --- | --- |
| Runtime capability or limitation | `context/current-state.md` |
| Architecture and boundaries | `context/architecture.md` |
| Durable policy/architecture decision | `context/decision-log.md` |
| Completed work and verification | `context/progress-tracker.md` |
| Public SDK contract | `docs/walletsub-feature01/walletSDKspec.md` |
| Screen behavior/status | `docs/walletsub-feature01/01-screen-list.md` |
| Device and release gates | `docs/walletsub-feature01/stepbystep.md` |

Update phase status here as evidence is produced; link detailed records rather than duplicating them. Preserve dated analysis/status reports as snapshots.

## Definition of done

- Shared transport is implemented and all current regression checks pass.
- Activation and rotation have passing two-device evidence and independent security approval.
- Daily Rewards balance, receive, history, send, lock, and removal are SDK-backed with approved policies and appropriate verification.
- Financial screens contain no simulated production behavior or mock account data.
- Interrupted and uncertain transactions recover through durable reconciliation.
- Feature code uses only the safe public SDK boundary; protected material stays private.
- Scope-specific production release gates are closed and documentation matches verified behavior.
- The App Master roster is completed only under its separately approved data/authorization architecture; any deferred product gaps remain explicitly recorded.
## Latest execution update — roster implementation, verification deferred

Phase 9 now has a public host-injected roster provider, validated scoped SDK pagination, and dashboard/Advanced loading/error/empty/refresh/load-more UI replacing sample rows. Its production exit remains open until the host supplies a genuinely authorized data source. No default provider or backend authorization service has been invented.

At the user's request, tests, analysis, builds and device checks are deferred for this slice. Earlier verification results do not cover these changes. Phase 8 release gates remain open. Off-device recovery and permanent credential erasure remain unimplemented; see `walletsub-feature01/remaining-features-implementation-3oct.md` for the concrete decisions required.
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
