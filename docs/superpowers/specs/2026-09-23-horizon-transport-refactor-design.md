# Horizon HTTP Transport Refactor — Design

Date: 2026-09-23
Status: Approved design (not yet implemented)

## Purpose

Refactor the Wallet SDK's Horizon HTTP transport to eliminate duplicated
request mechanics, unify transport behavior where appropriate, improve DI and
testability, and create a reliable reusable transport foundation. The refactor
preserves existing runtime behavior. It adds no new Wallet feature.

This refactor is exploratory and intentionally mechanical: shared core owns
*how* the SDK talks to Horizon; each operation owns *what* a response means.

## Scope

### In scope

- A new private shared transport core (`HorizonHttpClient`) under
  `lib/wallet_sdk/src/transport/`.
- Five Horizon HTTP consumers become thin delegates over that core:
  - `DirectHorizonHealthClient`
  - `DirectDistributorStatusClient`
  - `DirectActivationSubmissionClient`
  - `DirectActivationReconciliationClient`
  - `HorizonDistributorAccountVerifier` (defined in
    `lib/wallet_sdk/src/authority/distributor_authority_service.dart`; no file
    move, but it switches to the shared core)
- A single `http.Client` shared by all consumers, owned by the transport
  foundation, injectable for testing.
- Compatibility constructor adapters so existing tests keep injecting a raw
  `http.Client`.
- Focused tests for the new shared transport; existing tests remain as
  behavioral regression protection.
- One agreed behavior change: an operation-level total deadline for
  reconciliation (see *Behavior changes*).
- Documentation sync (`context/decision-log.md`, `context/architecture.md`,
  verification records).

### Out of scope (explicit)

- New post-activation Wallet operations (balance, history, send). Those may use
  this foundation later, but are outside this refactor.
- All UI work, including provider-configuration rotation screens.
- Blind resubmission of uncertain transactions (unchanged: durable state, poll
  and reconcile only).
- `/transactions_async`.
- The deferred policy notes D1–D4 below.
- Any change to the public `WalletSdk` facade (`lib/wallet_sdk/wallet_sdk.dart`).

## Verified current state

Recovered decisions were checked against the repository before this design was
continued. All four Direct clients exist under `lib/wallet_sdk/src/transport/`.
`DefaultWalletSdk` constructs each independently, so today each owns a separate
default `http.Client` (health's is `IOClient(HttpClient()..connectionTimeout =
5s)`; the others are plain `http.Client()`).

`HorizonDistributorAccountVerifier` in
`lib/wallet_sdk/src/authority/distributor_authority_service.dart` is a fifth
Horizon HTTP caller duplicating the same mechanics (header merge, timeout,
64 KB cap, JSON decode).

Existing automated checks pass at baseline: `flutter analyze` clean, all 67
tests green.

Repeated mechanics to remove (move into the shared core):

- URL join: `endpoint.replace(pathSegments: [...existing, ...segments],
  query: null, fragment: null)` duplicated across distributor status,
  submission, reconciliation, and the verifier.
- Common headers: `accept: application/json` + `api-key: <key>` on every
  request.
- Request send, timeouts, bounded/streaming body reads, and JSON decoding
  (`jsonDecode(utf8.decode(bytes))`) with per-operation behavior differing
  today.

## Design

### Principle

- The shared core owns how we talk to Horizon: request construction, URL
  assembly, common headers, connect/read timeouts, bounded streaming read,
  JSON decoding, and typed low-level transport failures.
- Each operation owns what the response means: status/result interpretation,
  domain parsing, and safe error mapping. The core never classifies domain
  outcomes.

### Shared core: `HorizonHttpClient`

New final class in `lib/wallet_sdk/src/transport/horizon_http_client.dart`.
Importable only from within `lib/wallet_sdk/src/` and never re-exported by
`lib/wallet_sdk/wallet_sdk.dart`.

Responsibilities:

1. **Single shared `http.Client`**. Owned by `HorizonHttpClient`
   (`{http.Client? client}` injectable). Default:
   `IOClient(HttpClient()..connectionTimeout = 5s)` — the client health already
   uses. `DefaultWalletSdk`'s default construction creates exactly one
   `HorizonHttpClient`, so exactly one default `IOClient` backs all five
   consumers.
2. **Transport defaults**: connect timeout 5s, per-chunk read timeout 5s.
   (These match health's current policy and become the shared defaults.)
3. **URL join**: base = `configuration.endpoint`; append the operation's path
   segments to the endpoint's existing non-empty segments; clear query and
   fragment.
4. **Header merge**: always `accept: application/json` + `api-key:
   configuration.apiKey`; operation-supplied headers overlaid on top
   (operation headers win). Example: submission adds `content-type:
   application/x-www-form-urlencoded`.
5. **Request**: `_client.send(http.Request)` — streaming everywhere, matching
   health's current approach — guarded by connect timeout on the initial send,
   body drained with per-chunk read timeout, optionally capped by the
   operation's `maximumResponseBytes`.
6. **Result**: `HorizonHttpResult(statusCode, headers, bytes)` plus a
   `decodeJson()` helper (utf8 decode + `jsonDecode` → `Map<String, dynamic>`;
   `FormatException` propagates).
7. **Low-level failures**: typed `HorizonHttpException` with `failure ∈
   {timeout, network, responseTooLarge}`:
   - `timeout` — either request phase (connect or read).
   - `network` — `SocketException` / `http.ClientException`.
   - `responseTooLarge` — byte cap exceeded while streaming.
   Status codes are never interpreted by the core; headers and bytes are
   returned raw so operations own meaning.

### Per-operation configuration (existing semantics preserved)

| Operation | Request | Op total deadline | Byte cap | Meaning mapping (op-owned, unchanged) |
| --- | --- | --- | --- | --- |
| Health | GET bare endpoint | 10s wraps its retry loop | 64 KB in-stream | 401/403 → `providerUnauthorized`; 429 → `providerRateLimited`; 2xx + passphrase + JSON → OK; else `providerInvalidResponse` / `providerServiceUnavailable` / `providerNetworkMismatch`; retry 3× exponential + jitter on rateLimited/serviceUnavailable/timeout |
| Distributor status | 2× GET in parallel (`accounts/{id}`, `fee_stats`) | 12s wraps `Future.wait` | 128 KB each | any failure, oversize, bad JSON, or domain parse issue → `distributorAccountUnavailable` |
| Submission | POST `transactions`, form `{tx}` | 15s | uncapped (read-timeout bounded) | 2xx → `accepted`; 4xx except 408/429 → `rejected`; else → `uncertain`; timeout/network → `uncertain` |
| Reconciliation | 2× GET sequential (`transactions/{hash}`, `accounts/{id}`) | one op-level 15s total deadline over both GETs (the one agreed fix) | 128 KB each | 404 → `pending`; non-200/oversize → `pending`; `successful != true` → `failed`; account + balance check → `verified`/`failed`; any catch → `pending` |
| Verifier | GET `accounts/{id}` | 10s | 64 KB | non-200/oversize/`account_id` mismatch → `distributorAccountUnavailable` |

### Low-level failure → operation mapping (unchanged)

| `HorizonHttpException.failure` | Health | Distributor / Verifier | Submission | Reconciliation |
| --- | --- | --- | --- | --- |
| `timeout` | `providerTimeout` | `distributorAccountUnavailable` | `uncertain` | `pending` |
| `network` | `providerServiceUnavailable` | `distributorAccountUnavailable` | `uncertain` | `pending` |
| `responseTooLarge` | `providerInvalidResponse` | `distributorAccountUnavailable` | `uncertain` | `pending` |

### Health retry policy (unchanged)

Retry/backoff stays in the health operation, keyed on operation failure codes
(`providerRateLimited`, `providerServiceUnavailable`, `providerTimeout`).
`Random`, `delay`, `maximumAttempts`, `retryBaseDelay`, and `totalTimeout`
remain injectable on `DirectHorizonHealthClient`.

### Behavior changes (complete list)

1. **Reconciliation operation-level total deadline**, default 15s over both
   sequential GETs inside `DirectActivationReconciliationClient.reconcile()`.
   Today reconciliation has no timeout at all. Value rationale: two sequential
   bounded reads need more headroom than the parallel 12s distributor budget;
   15s tracks submission's single-op budget while still capping each
   `reconcile()` attempt (worst-case outer loop = 3 × 15s at startup).
   Injectable via constructor like the other op budgets.

No other runtime behavior changes.

## DI and wiring

### `DefaultWalletSdk`

- New optional constructor param: `HorizonHttpClient? horizonHttpClient`.
  Omitted → `DefaultWalletSdk` creates the single shared instance. Injected
  (tests/future consumers) → used directly.
- The one `HorizonHttpClient` is wired into all five consumers:
  - `DirectHorizonHealthClient(transport: shared)`
  - `DirectDistributorStatusClient(transport: shared)`
  - `DirectActivationSubmissionClient(transport: shared)`
  - `DirectActivationReconciliationClient(transport: shared)` (with the new
    15s default deadline)
  - `HorizonDistributorAccountVerifier(transport: shared)` (inside the default
    `DistributorAuthorityService` construction)
- Existing whole-service injection seams are unchanged: `horizonHealthClient`,
  `distributorStatusClient`, `distributorAuthorityService`,
  `activationSubmissionClient`, `activationReconciliationClient`, and the
  rest still inject complete fakes.

### Consumer constructors: single dependency path

Each Direct client and the verifier keeps `{http.Client? client}` and adds
`{HorizonHttpClient? transport}`. Resolution rule (exactly one path):

- `transport` supplied → use it. This is the production path (the shared
  transport).
- `transport` not supplied, `client` supplied → wrap `client` in a private
  `HorizonHttpClient`. This is the backward-compatible test adapter.
- neither → build a default transport with the standard `IOClient`
  (connect timeout 5s).
- **Both supplied → `ArgumentError`.** Enforced in all build modes, not a
  debug-only `assert`.

`client` is explicitly a temporary compatibility adapter; production wiring
always uses the shared transport.

### Health compatibility parameters

- `connectTimeout`, `readTimeout`: transport policy in the new architecture.
  They remain on `DirectHorizonHealthClient` strictly as compatibility
  constructor params applied only when the client self-constructs a private
  transport; when a `transport` is supplied they are ignored (shared transport
  policy governs).
- `maximumResponseBytes`: operation policy. Always honored — passed per-request
  into the transport's request spec regardless of which transport is in use.

## Horizon guidance comparison and deferred policy notes

Compared against Stellar Horizon official guidance on 429 rate limiting, 504
transaction-submission timeout/uncertainty, retry/backoff, and safe
reconciliation. Current operation semantics already align with the guidance on
the important points (504 → unsure → poll; 400 → definite rejection; 404-until
-ingested → pending; no blind resubmission). Findings are recorded as deferred
policy notes; **none are implemented in this refactor**:

- **D1/D3 — rate-limit-aware retry policy.** Health's backoff may not respect
  Horizon's throttling window. Qualified: Horizon docs confirm per-IP 429
  limiting with a configurable default of 3600/hour; the exact
  `Retry-After` / `X-RateLimit-*` header contract must be verified against
  actual Horizon/NOWNodes behavior before becoming Wallet SDK production
  policy.
- **D2 — distinguish definite Stellar transaction rejection from
  provider/service-level HTTP failures.** Example: submission maps 403 to
  `rejected` (definite), while Horizon defines 403 as "transaction submission
  disabled" (a service-level condition). Candidate reclassification is
  deferred.
- **D4 — bounded reconciliation polling with delay/backoff.** `reconcileActivation`
  currently polls up to 3 times with no inter-attempt delay. Adding a
  delay/backoff is deferred.
- **D5 — corrected, no action.** The 409 `DUPLICATE` semantics belong to
  `/transactions_async`. The Wallet SDK uses the synchronous `POST
  /transactions`, where resubmitting an already-included transaction returns
  the original transaction response (200), not 409. Async-endpoint semantics
  are not imported into the current operation; no mapping change.

## Public API constraint

`lib/wallet_sdk/wallet_sdk.dart` is unchanged. Nothing under
`lib/wallet_sdk/src/transport/` is exported. The import-boundary guarantee
(feature code imports only `wallet_sdk/wallet_sdk.dart`) is preserved.

## Composition invariant

**Invariant:** `DefaultWalletSdk`'s default construction creates exactly one
`HorizonHttpClient` and therefore one default `http.Client`, and supplies that
same instance to all five Horizon consumers.

The spec deliberately adds **no production getters** (for example
`@visibleForTesting` identity getters on `DefaultWalletSdk` and the five
consumers) solely to observe object identity for a composition test. Strict
same-instance identity across all five consumers is therefore documented here
rather than asserted directly.

Closest-practical composition coverage:

1. **Per-consumer delegation** (new transport tests): for each consumer,
   supply one `HorizonHttpClient` backed by a `MockClient` and assert the
   consumer's requests flow through that transport (observable through the
   mock's request log).
2. **`DefaultWalletSdk` behavioral composition** (new SDK test): construct
   `DefaultWalletSdk(horizonHttpClient: <one MockClient-backed transport>)`
   with the existing fake stores/services and drive flows that exercise the
   real consumers — provider-configuration save (health consumer),
   distributor-secret import (verifier consumer), and App Master overview
   (distributor-status consumer). Assert that the single injected transport's
   client serves all of those flows (health `GET /`, verifier + status
   `accounts/{id}`, status `fee_stats`). This proves multiple consumers route
   through one shared transport at the `DefaultWalletSdk` composition level
   using existing and injected seams only.

## Documentation sync

With the change, update per `AGENTS.md`:

- `context/decision-log.md`: entry for the shared Horizon transport
  foundation, the 15s reconciliation deadline, and deferred D1–D4.
- `context/architecture.md`: brief note for the transport foundation under
  `lib/wallet_sdk/src/transport/`.
- `context/current-state.md` / `context/progress-tracker.md`: verification
  record once green.
- No changes to `pubspec.yaml` or `context/code-standards.md`.

## Testing strategy

- All 67 existing tests remain and pass with no or near-zero edits; they act as
  behavioral regression protection that operation semantics are preserved. If
  any existing test must change, it is flagged and justified before its
  behavioral expectation is altered.
- New focused tests for `HorizonHttpClient` (e.g.
  `test/wallet_sdk_transport_test.dart`), driving it with a `MockClient`
  injected as the transport's client:
  - URL join (existing base path segments + op segments; query/fragment
    stripped)
  - Header merge (api-key + accept always; op headers overlaid and winning on
    conflict)
  - Bounded streaming read (cap exceeded → `responseTooLarge`; exact-boundary
    accepted)
  - Timeout taxonomy (connect-phase timeout → `timeout`; slow-chunk read-phase
    → `timeout`)
  - Network taxonomy (handler throws `ClientException`/`SocketException` →
    `network`)
  - `decodeJson()` (valid Map; `FormatException` on malformed)
- Constructor coverage: supplying both `transport` and `client` to a consumer
  throws `ArgumentError`.
- Reconciliation: the op-level 15s deadline is verified by test (slow mock
  across both GETs → bounded), and oversize still maps to `pending`.
- Composition coverage as described in *Composition invariant*.

## Acceptance criteria

- `flutter analyze` clean; `dart format` applied to changed files.
- All 67 existing tests pass unchanged (or each changed test is justified
  before its expectation is altered).
- New tests green, including the `ArgumentError` constructor coverage and the
  composition coverage above.
- Reconciliation 15s op-level deadline verified by test.
- No change to the public `WalletSdk` facade.
- Documentation sync committed with the change.