# Daily Rewards SDK Contract Draft — 3 October 2026

Status: Partial implementation. Active identity finalization, validated legacy migration,
balance, Receive, paginated direct-payment history, recipient inspection, and
exact preparation/review, native authorization, testnet sends/hash reconciliation,
local lock and retained-material access removal are implemented. Permanent
credential erasure and off-device recovery remain proposed policy work.
App Master controls the activation network and asset; the daily SDK uses that
verified configuration and does not require hard-coded code/issuer decisions.
Local access sessions/lock and retained-material device removal are implemented.
Per-transfer device authentication now uses native biometrics/device credentials,
short one-use grants, and background revocation. Local sessions start locked and
expire after five minutes; unlock does not authorize a payment. Removal disables
local access durably, retaining custody/evidence for native restoration. Pending
transfers block removal. Permanent key erasure and off-device recovery remain
future policy work.
The existing two-device and independent-security gates remain open.

## Baseline code findings before the new slices

- `WalletSdk` exposes activation, provider configuration, distributor authority,
  and App Master overview. It has no daily Rewards operations.
- `ActivationSubmissionRecord` persists response ID, transaction hash, and status.
  A verified status alone does not contain the Builder account or Rewards asset.
- Reconciliation currently recovers account identity from the pending activation
  request and asset identity from the protected inspected response. It verifies
  ledger state, promotes provider configuration, and writes verified status.
- The pending request and protected response currently remain after verification.
  Daily operations must not become dependent on retaining those temporary records
  indefinitely or on reusing their original expiry as a daily-operation deadline.
- Receive currently renders a mock ID and QR icon. There is no real Reward-ID
  directory mapping in the repository.

Evidence: `lib/wallet_sdk/src/default_wallet_sdk.dart`,
`src/storage/activation_submission_store.dart`, `src/storage/activation_store.dart`,
`lib/wallet_sdk/wallet_sdk.dart`, and the Receive screen.

## Proposed private active identity

Implementation note (2026-10-03): the protected record and ordered finalization
service are implemented for newly reconciled activations, with credential-account,
submission, and identity-conflict checks. The SDK also checks the inspected
transaction hash against persisted submission evidence. Validated legacy migration
is also implemented and tested. Temporary activation records are retained for recovery.

Introduce a versioned protected active-account record containing:

| Field | Purpose |
| --- | --- |
| Account identifier | Exact verified Builder receiving/signing account |
| Credential reference | Locate the existing protected Builder signing material |
| Network identity | Bind operations to the activated environment |
| Asset code and issuer | Bind Rewards operations to the verified activation asset |
| Activation transaction identity | Trace the ledger evidence that established activation |
| Verification timestamp / schema version | Support restoration and explicit migration |

This record is internal to the SDK. Never copy the signing secret into application
state. Per user clarification, the App Master-authorized activation network and
asset are the source of truth for daily Rewards; do not add a global asset allow-list
or compile-time network/issuer choice. Later changes require an explicitly designed
authorized update flow rather than inferring a different asset from account balances.

Write and restore the active record as part of a recoverable activation finalization
sequence. Final active status must not be published before required identity data
is durable. Protected storage and preferences are separate stores: use explicit
ordering, idempotent recovery, and failure tests rather than claiming one atomic
transaction across them.

For existing verified installations, migrate using the retained request and
protected response only after validating their binding and existing verified
transaction identity. Migration must not generate a new account, change an asset,
resubmit activation, or silently discard signing material. If required evidence is
missing or inconsistent, expose a safe recovery-required state and block signing.
Migration is implemented with these checks; independent security review and device
verification remain required before production use.

## Proposed public read contracts

Method names and shapes are proposals, to be reconciled with the canonical SDK
specification before code changes.

| Method | Safe return model | Main constraints |
| --- | --- | --- |
| `getRewardsBalance()` (implemented) | `RewardsBalanceView` | Exact activation asset, total and available decimal strings, observation time; UI marks retained data stale on failure |
| `getRewardsReceiveIdentity()` | `RewardsReceiveView` | Public identifier, opaque QR value, safe environment/asset summary |
| `getRewardsHistory(cursor, limit)` (implemented) | `RewardsHistoryPage` | Confirmed direct payment items, scoped opaque next cursor, observation time, page bound; local attempts and path payments excluded |

Suggested balance fields: safe amount strings, display label, observed-at time,
and state. Define canonical exact amounts privately; do not use floating-point
values for transfer policy or accounting. UI formats validated values and does
not compute spendable balance itself.

Receive must return the real public identity. Whether the display uses a raw
public account or an approved mapped Reward ID is a product decision. The mock
`BLD-...` ID cannot be converted into a real directory identity without an approved
data source. QR syntax and network/asset binding remain decisions to resolve.

Suggested history fields: opaque item ID, incoming/outgoing direction, exact
amount display, timestamp, safe counterparty label/public identity, and confirmed
ledger status. Never infer names/phone identities from account addresses. Decide
whether failed attempts are included or presented separately from ledger history.

The SDK validates cursor scope and page bounds, parses privately, and returns safe
records. The UI must not follow provider pagination URLs or receive raw responses.
Bind retained cache/page state to account, network, and asset. Ignore stale in-flight
results after identity changes or removal. Define cache persistence/retention before
storing history on disk; a failed refresh must not label cached data as fresh.

## Proposed transfer lifecycle

| Method | Responsibility |
| --- | --- |
| `inspectRewardsRecipient(value)` (implemented) | Validate public G account, activated asset trustline/authorization/capacity; return safe read observation, not transfer authorization |
| `prepareRewardsTransfer(publicAccount, amount)` (implemented named arguments) | Fresh recipient/funds/capacity/native fee checks; private exact intent; immutable two-minute review |
| `getPreparedRewardsTransfer(reviewId)` (implemented) | Validate retained review ID, expiry, identity, and provider; no ledger recheck or authorization |
| `approveRewardsTransfer(reviewId)` (implemented for testnet) | Native authentication; revalidate exact intent, sign privately, persist public hash evidence, submit once, reconcile |
| `authorizeRewardsTransfer(reviewId)` (implemented) | Native device-owner authentication; exact private intent revalidation before/after prompt; short one-use private grant, no signing/submission |
| `cancelRewardsTransferAuthorization()` (implemented) | Invalidate review/grant and cancel prompt; late results cannot approve |
| `getRewardsTransferStatus({reconcile: false})` (implemented) | Restore latest safe durable outcome; optional hash-only ledger reconciliation, no POST |

Suggested review fields: opaque review ID, recipient public identity, exact amount,
asset summary, fee summary, expiry, and safe warnings justified by policy. Do not
expose raw envelopes, provider credentials, or signing material.

UI navigation or a boolean supplied by a controller is not authentication evidence.
Choose the authentication mechanism before implementing approval. The SDK must
enforce authorization even when its methods are invoked without the review screen.
Cancellation or failed authentication must not sign or submit.

Suggested durable states:

```text
prepared -> authorization required -> authorized -> submitting
submitting -> submitted | rejected | uncertain
submitted | uncertain -> verified | rejected | still unresolved
```

Prepared expiry and rejection are terminal for that attempt. A new attempt must
be explicit. Persist transaction identity before submission; on persistence failure
do not submit. Restart during submitting becomes unresolved until reconciled.
Repeated approval must return/reconcile the existing attempt rather than create
another transaction. Any changed recipient, amount, asset, or fee requires a new
review and authorization. Define concurrency/sequence policy before supporting
multiple outstanding transfers.

## Safe failure and state design

Proposed categories: not activated, recovery required, unsupported asset/network,
service unavailable, invalid recipient/amount, insufficient spendable balance,
review expired, authentication cancelled/failed, locked, persistence failure,
and transfer unresolved. Final code names remain to be agreed.

Distinguish empty history from unavailable history, zero balance from failed reads,
and uncertain submission from definite rejection. Expose retry eligibility without
allowing the UI to blindly resubmit an uncertain transaction. Safe messages must
not include private transport errors or protected payloads.

## Decisions needed from the user

| Decision | Required details | Dependent work |
| --- | --- | --- |
| Rewards asset | Resolved: derive network/code/issuer from App Master-authorized verified activation | Balance, history, recipient validation, send |
| Receive identity | Implemented: verified public account, account-address QR; recipient inspection must apply runtime network/asset checks | Receive and recipient inspection |
| Authentication | Supported device authentication/fallback; relock timing; session scope | Send approval and lock |
| Recovery/removal | Supported recovery path; device-loss consequences; pending-transfer removal behavior | Migration recovery and removal |
| Transfer policy | Limits, fee limits/presentation, concurrent-transfer policy | Preparation and signing |
| History scope | Successful ledger payments versus local attempts; retention expectations | History models/cache |

Do not invent these decisions or commit real account data to this draft. Asset
identifiers may be public, but secrets and private account information must be
provided through an appropriate protected channel when needed for device tests.

## Implementation slices after decisions

1. Reviewed active identity/finalization migration with fake stores and fault tests.
2. Read facade models and fake SDK support; real balance service and overview UI.
3. Real receive identity/QR and exact copy behavior.
4. Typed paginated history service and UI states.
5. Protected-session mechanism, then transfer lifecycle and UI.
6. Complete lock/removal and approved recovery behavior.

Use the shared Horizon transport and focused private services. Keep the existing
public activation contract compatible while adding each reviewed daily capability.
Update canonical SDK/screen documentation with implemented slices, not this draft's
proposals as if they already exist.

## Verification plan

- Active identity: storage failure at each boundary, interrupted finalization,
  legacy migration, mismatched evidence, missing credential, and restore.
- Reads: account/asset mismatch, exact amount parsing, malformed/oversized response,
  timeout, pagination scope, duplicate records, empty results, and stale refresh.
- Receive: exact identity/QR/copy, wrong environment, inactive/recovery states.
- Send: review alteration/expiry, authentication cancellation, duplicate approval,
  pre-submit persistence failure, uncertain result, and restart reconciliation.
- Lifecycle: background/relock, direct-call authorization, interrupted removal,
  pending transfer handling, and stale in-flight read completion.
- Boundary: features import only the facade; credentials and raw provider records
  remain private; widget tests use public models/fakes.

Run required automated checks per the master plan, then verify known testnet state
on physical devices. Obtain review for migration, signing, authentication, and
removal before production use.
