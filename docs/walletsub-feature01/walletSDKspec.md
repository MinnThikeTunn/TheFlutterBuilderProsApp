# Wallet SDK Specification

## 1. Purpose

### Daily Rewards receive slice (implemented 2026-10-03)

`getRewardsReceiveIdentity()` returns `RewardsReceiveView` containing the public
account, opaque QR value, environment, and activation asset code. It requires
verified submission evidence matching the protected active-account record.
The current QR is the exact public account address and contains no private material.
The account QR does not encode network/asset intent; recipient inspection
validates compatibility using the SDK's App Master-authorized runtime settings.
Do not interpret it as an instruction to send an arbitrary asset.

Missing or mismatched active identity returns a safe `unavailable` failure.
Legacy verified installations without the new record trigger validated lazy
migration. The SDK rechecks retained authorized response/device binding and exact
transaction hash against live ledger state through the current provider. It checks
signing credential ownership and persists protected identity without replacing
provider settings, deleting evidence, creating an account, or submitting activation.
Offline, missing, or altered evidence remains safely unavailable and retryable.
Testnet transfer signing/submission and local lock/access removal are implemented.
Production sends, permanent key erasure, and off-device recovery remain blocked
or undesigned.

### Protected transfer authorization (implemented 2026-10-03)

### Testnet transfer approval and status (implemented 2026-10-03)

`approveRewardsTransfer(reviewId)` authenticates the retained exact review,
revalidates ledger funds/capacity/sequence/fees, verifies protected credential
ownership and current source medium-threshold authority, and signs one payment
in the activated asset. Source sequence increments once; the envelope has the
reviewed fee and review-expiry time bound. Production sending is rejected before
authentication/signing pending physical-device and independent security evidence.

The SDK writes/read-verifies a protected record containing transaction hash and
public intent before one POST. No signed envelope or secret is persisted in this
record. It revalidates after the write and consumes private approval immediately
before POST; cancellation or changed state prevents submission. A write failure
prevents POST. Repeated approval of the latest saved review returns its outcome.

`getRewardsTransferStatus({bool reconcile = false})` restores the latest saved
`RewardsTransferOutcome`, or null when absent. With `reconcile: true`, pending
evidence is checked through `GET /transactions/{hash}` only. Outcomes contain
review ID, hash, recipient, asset code, amount, and confirmed/failed/cancelled/
uncertain state. Exact source, sequence, fee, time bound, payment intent, network
hash, and source signature must match returned ledger evidence. Only then does
the ledger `successful` value yield confirmed or failed. Cancelled means the SDK
durably recorded cancellation before POST.

Timeout, 404, non-matching/malformed evidence, and terminal-status storage failure
remain uncertain. Pending evidence blocks new preparation/submission across
restart. Expiry alone never clears uncertainty; recovery for a never-ingested or
pruned transaction remains an explicit future policy decision. The UI offers
status checks, never blind resubmission. Stable errors include
`rewardsSendUnavailable` and `rewardsTransferPending`.
Ledger fields follow the [Horizon transaction schema](https://developers.stellar.org/docs/data/apis/horizon/api-reference/resources/transactions/object).

### Protected transfer authorization (implemented 2026-10-03)

`authorizeRewardsTransfer(reviewId)` resolves the private prepared review, rereads
the recipient and source/fees before and after a native device authentication
prompt, and rejects changed sequence, insufficient Rewards/capacity/native funds,
fee increase, identity/provider mismatch, or expiry. It uses biometric or native
device PIN/passcode fallback. It does not accept a UI authentication boolean.
`RewardsTransferAuthorization` returns informational review ID/expiry only; it is
never accepted as signing evidence. A private single-use grant binds the exact
retained review and expires within 30 seconds or review expiry, whichever is first.

`cancelRewardsTransferAuthorization()` invalidates the review/grant and requests
native prompt cancellation. Late successes cannot restore approval. Replacement,
expiry and paused/hidden/detached lifecycle states revoke private grants. Inactive
native-dialog state is permitted. Prompts do not resume across backgrounding.
`rewardsAuthorizationDenied` describes native false results;
`rewardsAuthorizationUnavailable` safely masks platform errors/unsupported setup.
Invalid/changed/cancelled reviews use `invalidRewardsTransferReview`.

This is an application-layer device-owner check, not identity verification or
hardware-bound seed use. Local session/removal contracts are defined below.
Testnet approval revalidates and consumes the private grant exactly once at
the submission boundary after durable public transaction evidence is written.
Native setup follows the [Flutter local_auth documentation](https://pub.dev/packages/local_auth/versions/3.0.1),
including [Android integration](https://pub.dev/packages/local_auth_android) and
[Apple Face ID configuration](https://pub.dev/packages/local_auth_darwin).

### Local access lifecycle (implemented 2026-10-03)

`getRewardsAccessState()` returns locked/unlocked/removed. `lockRewards()` revokes
reviews, in-flight preparation and private approval. Sessions start locked on
restart, last five minutes in memory, and relock on paused/hidden/detached states.
Native-dialog inactivity is permitted. `unlockRewards()` authenticates device
ownership; it never grants payment approval. A successful exact transfer prompt
may open access, but every payment still authenticates its review separately.
Public reads remain available while locked. Session validity is checked at POST;
locking after POST cannot retract an already submitted transaction.

`removeRewardsAccess()` authenticates, checks unresolved-send and identity state
before/after the prompt, and writes/read-verifies one protected disabled marker.
It blocks Rewards reads and new Builder activation/signing across restart. It
retains the protected signing credential, active identity, configuration, activation
and transaction evidence. No account closure, seed destruction, balance transfer,
or off-device recovery is implied. The UI clears derived daily-operation data and
routes to native restoration. `unlockRewards()` restores only the retained matching
account. Pending/uncertain transfers block removal. Partial writes can already have
disabled access despite an error; inspect saved state. Corrupt/unreadable marker
fails closed. These guarantees are enforced by SDK methods independently of
navigation/role switching. Errors use `rewardsAccessRemoved` and
`rewardsAccessUnavailable`. Physical-device/security evidence remains open.

### Transfer preparation (implemented 2026-10-03)

`prepareRewardsTransfer(publicAccount: ..., amount: ...)` accepts an exact positive
decimal amount (at most seven decimals, signed 64-bit units) and a public receiving
account. It returns immutable `RewardsTransferReview`: random review ID, recipient,
network, activated asset code/issuer, canonical amount, maximum native XLM fee bid,
and expiry. Public data contains no credentials or envelope.

Fresh recipient and sender reads check receiving capacity and spendable Rewards.
Sender native balance subtracts selling liabilities and
`(2 + subentry_count + num_sponsoring - num_sponsored) * base_reserve_in_stroops`.
The fee must fit the remaining native funds. The one-payment bid is the maximum of
latest ledger base fee, fee-stats base fee, and fee-charged p95; values must fit
unsigned 32-bit fee encoding. Source sequence must permit a next signed 64-bit
sequence. Reads use bounded shared transport and a 15-second combined deadline.
These are separate ledger observations, not an atomic multi-account snapshot.

One private exact intent is retained per SDK instance for two minutes from start.
Concurrent preparation is rejected; replacement/failed preparation invalidates
old intent. `getPreparedRewardsTransfer(reviewId)` validates ID, expiry, identity,
and provider configuration, returning that same immutable review. Reviews are not
persisted and require preparation after restart. It does not recheck ledger funds
or authorize/sign/submit; `approveRewardsTransfer` performs those checks.

Stable errors include `invalidRewardsAmount`, `insufficientRewardsFunds`,
`insufficientRewardsFeeFunds`, `rewardsTransferPreparationUnavailable`, and
`invalidRewardsTransferReview`, plus existing recipient/identity errors.
Fee/reserve fields follow the [ledger schema](https://developers.stellar.org/docs/data/apis/horizon/api-reference/resources/ledgers/object)
and [fee stats schema](https://developers.stellar.org/docs/data/apis/horizon/api-reference/aggregations/fee-stats/object).

### Recipient inspection (implemented 2026-10-03)

`inspectRewardsRecipient(publicAccount)` accepts a trimmed public G address with
valid StrKey checksum. Returns `RewardsRecipientView` with public account,
environment, activated asset code, exact receiving capacity, and UTC observation
time. It requires verified active identity and matching provider environment,
reads the destination account through shared transport, and rechecks identity and
provider configuration after the read. It matches exactly one authorized asset
trustline and subtracts balance and buying liabilities from limit with integer
seven-decimal precision. Bounded to 128 KiB and 12 seconds.

Invalid/self/missing/unsupported destinations use `invalidRewardsRecipient`;
service/malformed failures use retryable `rewardsRecipientUnavailable`; identity
failures preserve their safe identity code. No raw provider messages are exposed.
Memo-routed accounts and issuer returns are unsupported in the address-only slice.
This view is not a transfer review; preparation must reread recipient and funds.
Capacity follows the [Horizon account schema](https://developers.stellar.org/docs/data/apis/horizon/api-reference/resources/accounts/object).

### Daily Rewards balance slice (implemented 2026-10-03)

`getRewardsBalance()` returns immutable `RewardsBalanceView` with public account,
environment, activation asset code, exact decimal `total` and `available` strings,
and `observedAt`. Protected active identity must match verified activation evidence,
and provider configuration must match its environment. The SDK privately selects
the exact App Master-authorized code/issuer; it does not infer Rewards from other
account assets. It rejects malformed, ambiguous, or missing trustline data.

Amounts use integer decimal units with at most seven decimal places. Available
Rewards subtract selling liabilities and are zero for an unauthorized trustline.
This read does not authorize sending or account for native transfer fees.
The private client uses shared transport with a 128 KB response cap and 12-second
operation deadline. It returns no raw provider data or credentials to Flutter.

`rewardsIdentityUnavailable` clears displayed identity-bound data;
`rewardsBalanceUnavailable` permits a previous balance to remain explicitly stale.
Overview shows observation time, loading, refresh failure, and retry. The cache is
in-memory only. Legacy identity migration is shared with the Receive path.

Field reference: [official Horizon account object](https://developers.stellar.org/docs/data/apis/horizon/api-reference/resources/accounts/object).

### Daily Rewards history slice (implemented 2026-10-03)

`getRewardsHistory({cursor, limit = 20})` returns an immutable `RewardsHistoryPage`
with safe payment items, exact amounts, public counterparties, UTC timestamps,
observation time, and an opaque next cursor. Limits are 1–50 raw records per read.
Cursor scope binds account, network, code/issuer, page size, and descending position.
The client constructs its own request query and never follows provider link URLs.

History currently includes successful direct `payment` operations in the activated
asset only. Path payments, other operation types/assets, and local pending/rejected
attempts are excluded. Incoming/outgoing/self direction is explicit; no private
identity directory or invented counterparty name is used. Filtered pages may be empty
and still have a next cursor. Pagination progresses over raw records, rejects
non-descending/duplicate positions, and ends on a short or empty raw page.

Reads use current protected provider settings, a 256 KB response cap, and a
12-second total request deadline. The facade verifies activation/configuration and
rechecks identity after reads. `invalidRewardsHistoryCursor` asks for refresh;
`rewardsHistoryUnavailable` retains explicitly stale rows; identity failure clears
the cache. UI data is in memory and refresh replaces pages. No history persistence
or live event stream is implemented.

Endpoint reference: [official account payments API](https://developers.stellar.org/docs/data/apis/horizon/api-reference/get-payments-by-account-id).

`WalletSdk` is the only Rewards integration boundary visible to Flutter features.
It exposes simple product operations and safe view models. All Stellar protocol,
cryptography, XDR, Horizon HTTP, provider authentication, secure storage,
validation, signing, retry, and reconciliation details are private SDK internals.

The SDK must call Stellar-compatible HTTP APIs directly. It must not depend on
`stellar_flutter_sdk` or another full Stellar SDK.

## 2. Reference implementation finding

The reference wallet uses `stellar_flutter_sdk: ^2.2.2` for local Stellar objects
and uses direct HTTP calls for Horizon access. Its configuration contains:

```json
{
  "horizonUrl": "https://xlm.nownodes.io",
  "nownodeApiKey": "YOUR_NOWNODES_API_KEY"
}
```

The reference services send the value in an `api-key` header when loading accounts,
loading balances, validating recipients, and submitting transactions.

The new SDK must not copy the reference asset-based key pattern. A key bundled in a
mobile application is recoverable and cannot be treated as a secret.

## 3. Provider policy

The SDK supports a configurable Horizon-compatible base URL and optional request
headers:

```dart
final class WalletSdkEnvironment {
  const WalletSdkEnvironment({
    required this.id,
    required this.horizonBaseUrl,
    required this.networkPassphrase,
    this.providerHeaders = const <String, String>{},
  });

  final String id;
  final Uri horizonBaseUrl;
  final String networkPassphrase;
  final Map<String, String> providerHeaders;
}
```

Rules:

- Development may use the public Stellar test endpoint without an API key.
- Production endpoint selection is a release decision.
- Provider headers remain optional in the reusable Wallet SDK transport contract so
  development can use a public test endpoint. This product's production activation
  policy requires a healthy saved NOWNodes configuration before App Master approval.
- No provider key may be committed, bundled in assets, hard-coded, logged, placed
  in analytics, or placed in a plaintext QR artifact.
- The App Master provisions the initial provider configuration through the
  device-bound activation response and rotates it through the Settings QR flow.
- Configuration QR ciphertext is unique to the intended Builder device. A global
  QR containing a shared plaintext key is forbidden.
- The configuration is stored with platform-backed secure storage after validation.
  It must still be considered extractable from a compromised device and restricted
  at the provider where possible.
- Provider headers are injected only inside the private HTTP adapter.

## 4. Public application interface

The Dart facade in `lib/wallet_sdk/wallet_sdk.dart` is authoritative. The sketch
below mirrors the implemented surface as of 2026-09-20.

```dart
abstract interface class WalletSdk {
  Future<ActivationRequestView> startActivation(BuilderIdentity builder);
  Future<ActivationRequestView?> restoreActivationRequest();
  Future<void> cancelActivation();
  Future<ActivationRequestReview> inspectBuilderRequest(String qrValue);
  Future<ActivationRequestReview?> restoreInspectedBuilderRequest();
  Future<ActivationResponseView> approveBuilderRequest(String requestId);
  Future<ActivationReview> inspectActivationResponse(String qrValue);
  Future<ActivationOutcome> approveActivation(String responseId);
  Future<WalletActivationStatus> reconcileActivation();
  Future<WalletActivationStatus> getActivationStatus();
  Future<ConfigurationRequestView> createConfigurationRequest();
  Future<ConfigurationRequestReview> inspectConfigurationRequest(String qrValue);
  Future<ConfigurationUpdateView> createConfigurationUpdate(String requestId);
  Future<ConfigurationReview> inspectConfigurationUpdate(String qrValue);
  Future<ConfigurationOutcome> applyConfigurationUpdate(String updateId);
  Future<DistributorAuthorityStatus> importDistributorSecret(String secret);
  Future<DistributorAuthorityStatus> getDistributorAuthorityStatus();
  Future<void> removeDistributorAuthority();
  Future<AppMasterOverview> getAppMasterOverview();
  Future<ProviderConfigurationOutcome> saveAppMasterProviderConfiguration(
    ProviderConfigurationInput input,
  );
  Future<ProviderConfigurationStatus> getProviderConfigurationStatus();
}
```

Configuration-request/update methods are implemented in the SDK. Flutter screens
for that rotation handshake are not yet wired. See `01-screen-list.md` and
`analysis-report.md`.

Application-facing objects contain only display-ready product data, stable IDs,
opaque QR strings, expiry, safe status enums, retry flags, and support references.
They never expose Stellar addresses, seeds, XDR, signatures, sequence numbers,
fees, operation names, Horizon records, or provider response bodies.

`ProviderConfigurationInput` is the sole exception for App Master setup. It accepts
the endpoint, masked-field API-key value, environment, and next configuration
version. The controller passes it directly to the SDK and immediately clears the
field. The SDK returns only a safe status; it never returns the API key.

App Master Advanced also accepts a distributor secret through
`importDistributorSecret` under the same clear-after-submit rule. Flutter receives
only masked safe status.

## 5. Private SDK modules

```text
wallet_sdk/
|-- wallet_sdk.dart                    public facade and safe models
`-- src/
    |-- default_wallet_sdk.dart        use-case orchestration
    |-- configuration/
    |   |-- configuration_handshake_service.dart
    |   |-- configuration_policy.dart
    |   |-- provider_configuration.dart
    |   `-- wallet_sdk_environment.dart
    |-- activation/
    |   |-- activation_request_service.dart
    |   |-- activation_response_service.dart
    |   |-- activation_policy.dart
    |   `-- activation_reconciler.dart
    |-- protocol/
    |   |-- strkey_codec.dart
    |   |-- xdr_reader.dart
    |   |-- xdr_writer.dart
    |   |-- transaction_builder.dart
    |   |-- transaction_inspector.dart
    |   `-- signature_service.dart
    |-- transport/
    |   |-- horizon_client.dart
    |   |-- horizon_models.dart
    |   |-- provider_header_policy.dart
    |   `-- retry_policy.dart
    |-- qr/
    |   |-- activation_qr_codec.dart
    |   |-- configuration_qr_codec.dart
    |   `-- qr_integrity_service.dart
    |-- storage/
    |   |-- credential_store.dart
    |   |-- activation_store.dart
    |   |-- configuration_store.dart
    |   `-- replay_store.dart
    `-- diagnostics/
        |-- sdk_event.dart
        `-- sdk_diagnostics.dart
```

No file under `lib/app/` may import `wallet_sdk/src/`. Only the application
composition root may construct the private implementation.

## 6. Direct Stellar HTTP surface

The classic Rewards workflow uses Horizon-compatible HTTP endpoints directly:

| Purpose | HTTP request | SDK use |
| --- | --- | --- |
| Server health/network identity | `GET /` | Validate configured environment before sensitive work |
| Load account and sequence | `GET /accounts/{account_id}` | Build from current authoritative state |
| Read balances and trustlines | `GET /accounts/{account_id}` | Capacity, eligibility, and post-submit verification |
| Estimate fee | `GET /fee_stats` | Apply approved fee policy and cap |
| Submit envelope | `POST /transactions` | Send form field `tx=<base64 envelope>` |
| Reconcile result | `GET /transactions/{hash}` | Resolve timeout or interrupted submission |

HTTP rules:

- HTTPS only outside local test environments.
- Normalize the base URL once and prevent path/host injection.
- Apply connection, read, and total deadlines.
- Cap response size before JSON decoding.
- Require expected content types.
- Parse into private typed DTOs; never return raw JSON to the application.
- Redact headers, URLs with credentials, envelope bodies, and provider payloads.
- Treat `404` according to endpoint context rather than as a generic failure.
- On `429` or transient `5xx`, use bounded backoff with jitter.
- Never rebuild and resubmit after an ambiguous result until reconciliation proves
  it is safe.

## 7. Protocol implementation without a Stellar SDK

The private protocol layer must implement and test:

### Key and address handling

- secure Ed25519 seed generation using the operating system random source;
- Ed25519 public-key derivation and signing through a reviewed generic crypto
  library or platform primitive;
- Stellar StrKey version bytes, Base32 encoding/decoding, and CRC16-XModem checksum;
- constant-time comparison where protected values are compared;
- zeroization where supported by the language/runtime.

### XDR

- RFC 4506 big-endian primitives and 4-byte padding;
- the exact Stellar protocol structures required by this product;
- strict discriminant, length, and bounds validation;
- canonical encoding and byte-for-byte round-trip fixtures;
- rejection of unknown or unsupported operations in activation responses.

Do not hand-maintain protocol definitions from memory. Generate or derive codecs
from the version-pinned official Stellar `.x` definitions, commit the generator and
generated source, and record the supported protocol version. A protocol upgrade is
an explicit SDK release.

The implemented activation subset is pinned to official Stellar XDR `v27.0`, exact
commit `68fa1ac55692f68ad2a2ca549d0a283273554439`. Its committed schema and generator
produce the discriminants and bounds used by the private codec. The codec accepts
only classic V1 envelopes, Ed25519 accounts, no memo, no or time-bound
preconditions, extension v0, credit alpha-num-4/12 assets, and the three activation
operations. It rejects all other protocol variants rather than partially decoding
them.

### Transaction hashing and signatures

- derive the network ID from SHA-256 of the configured passphrase;
- construct the signature base from the network ID, envelope type, and transaction
  XDR;
- hash the signature base with SHA-256;
- create and verify Ed25519 signatures;
- derive and validate signature hints;
- preserve existing valid signatures when adding the local signature;
- reject duplicate, unexpected, missing, or invalid signatures.

## 8. Activation transaction contract

The App Master SDK constructs one classic atomic transaction with:

1. `createAccount`, sourced by the App Master-controlled distributor;
2. `changeTrust`, sourced by the new Builder account; and
3. `payment`, sourced by the distributor, delivering starting Rewards.

Before returning a response QR, the SDK validates:

- network and environment;
- current distributor sequence;
- time bounds and fee ceiling;
- exact Builder address from the request;
- configured Rewards code and issuer;
- approved starting XLM and Rewards amounts;
- operation count, order, source accounts, and absence of extra operations; and
- all App Master-controlled signatures.

The Builder SDK independently decodes the response and repeats the full allow-list
validation. It signs only after the application calls `approveActivation()` for
the inspected response ID.

## 9. QR schemas

QR values are opaque to Flutter code but versioned inside the SDK.

### Request

```json
{
  "payload": {
    "type": "rewards_activation_request",
    "version": 2,
    "request_id": "...",
    "challenge": "...",
    "created_at": "...",
    "expires_at": "...",
    "environment": "test",
    "builder": {"name": "...", "phone": "..."},
    "activation_address": "G...",
    "device_id": "...",
    "device_configuration_public_key": "..."
  },
  "integrity": "..."
}
```

The v2 request encoder uses a fixed field order and a SHA-256 integrity checksum
over the canonical payload. This detects accidental or un-recomputed alteration;
it is not App Master authentication. App Master authorization is provided by the
signed response protocol. The decoder enforces exact fields, types, version, byte
limit, device-key lengths, timestamps, lifetime, and checksum before returning a
private decoded model.

### Response

```json
{
  "type": "rewards_activation_response",
  "version": 1,
  "response_id": "...",
  "request_id": "...",
  "challenge": "...",
  "expires_at": "...",
  "environment": "...",
  "activation_address": "G...",
  "envelope_xdr": "...",
  "encrypted_provider_configuration": {
    "algorithm": "X25519-HKDF-SHA256-XCHACHA20POLY1305",
    "ephemeral_public_key": "...",
    "nonce": "...",
    "ciphertext": "..."
  },
  "app_master_key_id": "...",
  "integrity_signature": "..."
}
```

Enforce byte-size limits before parsing. Canonicalize the integrity-signature input.
If a response does not fit the selected static QR error-correction level, fail
closed until an approved animated-QR or compression profile exists.

## 10. Provider configuration QR handshake

### 10.1 Trust and device binding

The Wallet SDK creates a separate device configuration encryption identity. Use an
X25519 key agreement identity for configuration encryption; do not treat the
Builder's Ed25519 activation identity as an encryption key.

The Builder configuration private key remains in platform-backed secure storage.
The corresponding public key and an opaque device ID may appear in activation and
configuration-request QR artifacts.

The Builder SDK must have an approved App Master verification trust root before it
accepts a configuration. The trust root is public verification material, not the
App Master's private credential. Its provisioning and rotation must be separately
versioned and security-reviewed.

### 10.2 Initial configuration during activation

0. App Master enters the NOWNodes endpoint and API key in Advanced. The controller
   passes it directly to `saveAppMasterProviderConfiguration()`, clears the field,
   and renders only the returned safe status. The SDK validates the endpoint,
   performs a health check, and saves the configuration in protected storage.
1. Builder SDK includes its configuration public key and device ID in the
   activation request.
2. App Master SDK validates the activation request.
3. App Master selects the approved provider configuration from its protected
   storage.
4. App Master SDK encrypts that configuration uniquely for the Builder device.
5. App Master SDK binds the ciphertext to the activation request, device,
   environment, configuration version, issue time, and expiry.
6. App Master SDK authorizes the complete response.
7. Builder SDK validates authorization and binding before decryption.
8. Builder SDK decrypts and validates the provider configuration internally.
9. Builder SDK performs a provider health check.
10. Builder SDK saves the configuration in protected storage only after the health
    check succeeds.

`approveBuilderRequest()` must fail with `providerConfigurationRequired` when no
healthy App Master configuration is installed. Every activation response includes
the encrypted configuration and its monotonically increasing version.

### 10.3 Settings update handshake

Configuration rotation uses `wallet_configuration_request` and
`wallet_configuration_update`; it never reuses activation or Rewards-transfer QR
types.

The Builder can show a fresh configuration-request QR, or the App Master may use a
previously stored device public key after selecting the exact Builder. The fresh
request is preferred because it supplies a new challenge and proves the device is
present.

```text
Builder Settings -> createConfigurationRequest()
App Master -> inspectConfigurationRequest(qrValue)
App Master -> createConfigurationUpdate(requestId)
Builder Settings -> inspectConfigurationUpdate(qrValue)
Builder confirms safe provider/environment summary
Builder Settings -> applyConfigurationUpdate(updateId)
```

### 10.4 Configuration request schema

```json
{
  "type": "wallet_configuration_request",
  "version": 1,
  "request_id": "...",
  "device_id": "...",
  "device_configuration_public_key": "...",
  "current_configuration_version": 3,
  "environment": "production",
  "challenge": "...",
  "created_at": "...",
  "expires_at": "..."
}
```

### 10.5 Configuration update schema

```json
{
  "type": "wallet_configuration_update",
  "version": 1,
  "update_id": "...",
  "request_id": "...",
  "device_id": "...",
  "environment": "production",
  "configuration_version": 4,
  "issued_at": "...",
  "expires_at": "...",
  "encrypted_configuration": {
    "algorithm": "X25519-HKDF-SHA256-XCHACHA20POLY1305",
    "ephemeral_public_key": "...",
    "nonce": "...",
    "ciphertext": "..."
  },
  "app_master_key_id": "...",
  "integrity_signature": "..."
}
```

The encrypted plaintext contains only the approved endpoint, required provider
headers, configuration version, environment, and health-check policy. It must not
contain App Master account credentials.

### 10.6 Update validation and commit

Before decryption or application, validate:

- QR type and schema version;
- App Master authorization against the trusted verification root;
- request ID, fresh challenge, intended device ID, and device key binding;
- expected environment;
- issue and expiry times;
- replay status; and
- configuration version strictly greater than the installed version.

Apply the update transactionally:

1. retain the current configuration;
2. decrypt the candidate inside the SDK;
3. validate endpoint allow-list, HTTPS, header names, and value sizes;
4. save the candidate as pending in protected storage;
5. perform a bounded provider health check;
6. promote the candidate atomically when healthy;
7. delete the previous configuration after promotion; and
8. record the update ID and version as consumed.

If any step fails, preserve the previous working configuration and return a safe
failure. Never fall back to a bundled key.

### 10.7 Rotation operations

- App Master creates a new provider key and configuration version.
- Old and new keys remain valid during a defined overlap window.
- Each Builder device receives and applies its device-bound update QR.
- Without a backend, App Master cannot remotely prove every offline device updated.
- An optional Builder-generated confirmation QR may let the App Master mark a
  device as updated in its local roster.
- Revoke the old provider key only after the operational migration policy is met.

This QR design provides offline distribution and rotation, not absolute secrecy on
a compromised device. Provider quotas, monitoring, restriction, and revocation
remain required.

## 11. Storage model

### Platform-backed secure storage

- Builder secret seed;
- App Master distributor secret seed;
- optional provider API key;
- device configuration private key;
- installed and pending provider configurations;
- integrity/trust-root material that is not public; and
- protected authentication state.

### Ordinary local persistence

- request and response IDs;
- opaque QR values when required for restoration;
- expiry and safe workflow status;
- safe Builder display data;
- transaction hash for reconciliation; and
- replay markers.

Never store secret seeds, provider keys, decoded protected QR internals, or signed
envelopes in ordinary preferences, controller state, analytics, or crash reports.

## 12. Error mapping

Private failures map to stable public codes such as:

- `invalidBuilder`
- `invalidQr`
- `expiredQr`
- `wrongEnvironment`
- `requestMismatch`
- `requestAlreadyUsed`
- `activationCapacityUnavailable`
- `approvalRejected`
- `serviceUnavailable`
- `verificationPending`
- `verificationFailed`
- `restartRequired`
- `configurationNotNewer`
- `configurationNotForDevice`
- `configurationHealthCheckFailed`
- `providerConfigurationRequired`

The public error includes only `code`, `safeMessage`, `canRetry`, and an optional
support reference. Raw Horizon result codes and response bodies remain private.

## 13. Testing requirements

- official StrKey valid/invalid vectors;
- CRC and Base32 property tests;
- official XDR fixtures and byte-for-byte round trips;
- malformed/truncated/oversized XDR fuzz tests;
- deterministic transaction and signature vectors;
- operation allow-list mutation tests;
- QR canonicalization, tampering, expiry, mismatch, and replay tests;
- HTTP contract tests for every endpoint and status class;
- timeout and duplicate-submission reconciliation tests;
- provider-header redaction tests;
- device-bound configuration encryption/decryption vectors;
- wrong-device, wrong-challenge, downgrade, expiry, tamper, and replay tests;
- health-check failure preserving the previous configuration;
- successful atomic configuration promotion and old-value removal;
- secure-storage rollback and restoration tests;
- testnet activation across two physical devices; and
- an import-boundary test proving `lib/app/` does not import private SDK files.

## 14. Current implementation gap

The first activation slice now uses private generic Ed25519 key generation and a
local SEP-23 StrKey codec. `stellar_flutter_sdk` has been removed. Request QR
encoding, protected credential access, pending activation persistence, clock, and
token generation are separated private services. Provider configuration facade
models, strict NOWNodes candidate validation, protected pending storage, safe status
restoration, explicit clearing, and failed-write rollback are implemented. The
private direct Horizon HTTP client now injects the `api-key` header, enforces
timeouts and response limits, validates the Horizon network identity, retries
bounded transient failures with jitter, and promotes a candidate atomically only
after a successful check. It accepts standard JSON media types, including the
`application/hal+json` returned by the live NOWNodes Horizon root endpoint, while
keeping the response body and its credential-bearing HAL links private. App Master
Advanced now calls the public facade, prevents
duplicate submissions, clears the entered key after every result, and restores only
safe status metadata. Step 4 is device verified. Device-bound activation request
version 2 is implemented with a separate protected X25519 installation identity,
strict private codec, stable restore binding, and safe v1 invalidation. Step 5 is
device verified. Step 6 camera and gallery QR acquisition are implemented behind
a focused adapter that forwards exact opaque values and keeps protocol parsing out
of feature code and is device verified. Step 7 SDK-backed inspection now strictly
validates request v2, rejects consumed requests, protects the pending raw request,
supports safe restoration, and exposes only Builder identity, request ID, expiry,
and plain-language setup steps; Step 7 is device verified. Step 8 uses approved
LOBSTR-style direct distributor-secret import in App Master Advanced. The private
SDK validates the StrKey, derives the Ed25519 public account, verifies it through
the active provider configuration, stores it only after success, and exposes only
masked status and is device verified.

Steps 8 and 9 are device verified. Step 9 reads the protected distributor account and
fee status directly through authenticated Horizon HTTP calls. Private DTOs retain
balances, liabilities, subentries, sequence, trustlines, and fee percentiles; the
public facade exposes only estimated activation capacity, safe Rewards availability,
service status, and refresh time.

The current estimate retains `(2 + subentry_count) * 0.5`, native selling
liabilities, three p95 fees, and a 0.5 safety margin, then divides spendable funding
by the temporary 2.1-per-Builder activation policy. These are explicit interim
policy constants, not live protocol reserve discovery. Until an allowlisted Rewards
asset code and issuer are configured, expose a numeric Rewards balance only when
exactly one non-native balance exists; otherwise fail closed to a safe label.

Step 10 implements the version-pinned RFC 4506 codec, limited transaction envelope,
network-passphrase transaction hashing, Ed25519 signature hints/signing/verification,
and preservation of existing signatures. It is private SDK protocol infrastructure
only; Step 11 remains responsible for building and signing the policy-approved live
activation response.
## Host-injected Builder-access roster — 2026-10-03

Bootstrap with `createWalletSdk(rosterProvider: provider)`. The provider implements `AppMasterRosterProvider.loadAuthorizedPage`; it receives environment, public authority account, limit and opaque cursor, and must authorize every request at the backend. Call `WalletSdk.getAppMasterRoster` from features. Pages contain public Builder identity, application access state and UTC timestamps. The SDK validates scope and pagination and masks provider errors. Missing configuration is a typed error, not a sample roster. No backend provider is shipped; this implementation has not been verified yet.
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
