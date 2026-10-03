# Wallet Development Scope and Status — 3 October 2026

## Purpose

This report reconciles the infographic **Wallet Project Status report 20th Sep
2026** with the repository as of 3 October 2026. The infographic is a useful dated
visual summary, but the current repository is authoritative for implementation
status.

## Where the wallet screen scope is maintained

| Source | Ownership |
| --- | --- |
| `docs/walletsub-feature01/01-screen-list.md` | Canonical screen inventory, IDs, purposes, actions, and screen-level status |
| `docs/walletsub-feature01/rewards-first-time-activation-spec-v2.md` | First-time Builder/App Master activation behavior |
| `docs/walletsub-feature01/walletSDKspec.md` | Public Wallet SDK contract and security boundary |
| `docs/walletsub-feature01/stepbystep.md` | Gated implementation sequence and manual verification requirements |
| `docs/walletsub-feature01/fixingplan2ndoct.md` | Follow-up implementation plan, including rotation UI and remaining daily Rewards work |
| `context/current-state.md` | Authoritative current runtime behavior and limitations |
| `context/progress-tracker.md` | Completed work, verification history, and active backlog |
| `context/decision-log.md` | Durable product, security, and architecture decisions |

The Flutter screen implementations live under:

- Builder Rewards: `lib/app/features/wallet/screen/`
- App Master: `lib/app/features/app_master/screen/`
- Central route inventory: `lib/app/constant/routing/app_route.dart` and
  `app_pages.dart`
- Application orchestration: `WalletController` and `AppMasterController`
- Public SDK boundary: `lib/wallet_sdk/wallet_sdk.dart`
- Private implementation: `lib/wallet_sdk/src/`

## Status meanings used in this report

- **SDK-backed:** The screen calls the production Wallet SDK facade and performs
  real local, cryptographic, storage, or testnet-capable behavior.
- **UI implemented / mock:** The route and screen exist, but displayed data or
  actions are simulated and must not be treated as production functionality.
- **Folded into another screen:** The behavior exists without a dedicated route.
- **Automated verification only:** Implemented and tested in automation but still
  awaiting its required physical-device gate.

## Executive status

| Area | Infographic status on 20 Sep | Repository status on 3 Oct | Result |
| --- | --- | --- | --- |
| Builder activation | 5/5 implemented | SDK-backed end-to-end; activation progress is folded into review | Done, subject to final two-device release gate |
| App Master activation | 3/3 implemented | SDK-backed request acquisition, inspection, approval, and response QR | Done, subject to final two-device release gate |
| App Master administration | 2/2 implemented | Provider setup, distributor authority, live capacity/status, and rotation entry are SDK-backed; Builder list remains mock | Core administration done; roster remains |
| Daily Rewards | 0/6, UI mock | Routes and screens exist, but balance, receive, send, and history remain mock | Functional implementation remaining |
| Provider rotation | 0/4, not started | Builder and App Master request/update flows are now implemented and covered by automated tests | Implemented; two-device verification remaining |

The most important change since the infographic was produced is that **provider
configuration rotation is no longer “Not Started.”** Its Flutter flows were added
on 3 October and use the existing Step 15 SDK APIs.

## 1. Builder activation scope

The infographic uses B-01 through B-05 as five visual steps. The canonical
repository list separates the broader Builder Rewards scope into B-01 through
B-14.

| Repository ID | Screen/behavior | Current status | Evidence/notes |
| --- | --- | --- | --- |
| B-01 | Rewards — Not Activated | SDK-backed | Collects Builder name/phone, validates them, and calls `startActivation()` |
| B-02 | Activation Request | SDK-backed | Displays real SDK request QR, request ID, expiry, restoration, and cancellation |
| B-03 | Review Activation | SDK-backed | Scans/imports response, displays safe SDK review, approves and reconciles activation |
| B-04 | Activation Progress | Folded into B-03 | No dedicated route; pending, rejected, uncertain, and verified outcomes are handled during review/reconciliation |
| B-05 | Rewards overview | Mixed | Route and actions exist; activation routing is real, but displayed daily balance is mock |

### Completed activation behavior

- Protected Builder activation identity and pending request persistence
- Real request QR creation, restoration, expiry, and cancellation
- Camera and gallery response acquisition
- Response authorization, expiry, replay, device, environment, and transaction
  policy validation
- Protected Builder signing
- Single Horizon submission with duplicate prevention
- Pending/uncertain reconciliation without blind resubmission
- Active Rewards-state persistence and startup restoration

### Remaining activation release work

- Run the complete activation path across two physical devices on testnet.
- Verify interruption, restart, expiry, replay, wrong-device, wrong-environment,
  rejection, and uncertain-submission recovery cases.
- Obtain independent security approval before production/mainnet.

## 2. App Master activation scope

| ID | Screen/behavior | Current status | Evidence/notes |
| --- | --- | --- | --- |
| M-01 | App Master Overview | Mixed SDK-backed | Live activation capacity, Rewards availability, service status, and refresh time; Builder access rows are still mock |
| M-02 | Activate Builder review | SDK-backed | Inspects validated Builder request and displays safe identity/setup information |
| M-03 | Activation QR | SDK-backed | Builds, signs, encrypts, authorizes, and displays a real activation response QR |

### Completed App Master activation behavior

- Camera/gallery Builder-request acquisition
- Strict SDK request inspection and consumed-request checks
- Restorable pending review
- Live distributor account/fee/provider reads
- Exact three-operation activation transaction construction
- Distributor signing and full response authorization
- Device-bound encrypted provider configuration in the activation response

## 3. App Master administration scope

| ID | Screen/behavior | Current status | Evidence/notes |
| --- | --- | --- | --- |
| M-04 | Advanced / provider setup | SDK-backed | Saves and health-checks NOWNodes endpoint/API key; returns only safe masked status |
| M-04 | Provider rotation entry | SDK-backed, automated verification | Scans/imports Builder request, reviews safe fields, and creates a device-bound update QR |
| M-05 | Distributor authority | SDK-backed | Imports, verifies, masks, restores, replaces safely, and removes the distributor credential |
| M-01 supporting area | Builder access list | UI mock | Names, balances, status, and last-checked rows are static mock data |
| M-05 My Rewards | Mixed | Role switch works; the reused daily Rewards screens remain mock |

### Administration work still remaining

- Replace the mock Builder-access roster with an approved real data source and
  authorization model.
- Decide whether Builder administration belongs on-device or behind a dedicated
  authenticated service; the current application has no general backend.
- Add production-grade role authorization. The present Builder/App Master switch
  exists for dual-role testing and is not production authorization.

## 4. Daily Rewards scope after activation

All of these routes and screens exist. None of the financial behavior below is
yet implemented through production Wallet SDK operations.

| Canonical ID | Infographic equivalent | Screen/behavior | Current status | Remaining implementation |
| --- | --- | --- | --- | --- |
| B-05 | W-01 | Rewards home/balance | UI mock | Add real balance/status facade, refresh, stale/offline states, and asset policy |
| B-06 | W-02 | Receive Rewards | UI mock | Return the real public receive identifier/QR from the SDK and support exact copy |
| B-07 | Part of W-03 | Scan recipient | UI mock | Add recipient QR/address inspection, validation, environment/asset checks, and safe review model |
| B-08 | W-03 | Send amount | UI mock | Add amount precision, available-balance, fee, limit, and validation policy |
| B-09 | W-04 | Review send | UI mock | Build a real SDK-provided transaction review containing recipient, asset, amount, and fee |
| B-10 | W-04 | Confirm protected action | UI mock | Add real authentication/authorization before signing |
| B-11 | W-05 | Send outcome | UI mock | Submit once, persist pre-submit state, and reconcile accepted/rejected/uncertain results |
| B-12 | W-06 | Rewards history | UI mock | Add typed, paginated SDK history reads plus loading, empty, refresh, and offline states |
| B-13 | Not shown separately | Rewards locked | UI mock | Define and implement actual local authentication and protected-session behavior |
| B-14 | Not shown separately | Remove Rewards access | UI mock | Define recovery consequences and transactionally remove protected material after confirmation |

### Missing SDK surface for daily Rewards

The public `WalletSdk` currently exposes activation, configuration rotation,
provider setup, distributor authority, and App Master overview methods. It does
not yet expose production methods for:

- Builder Rewards balance
- receive identifier/QR
- recipient inspection
- transfer preparation/review
- transfer approval/signing/submission
- transfer reconciliation
- paginated Rewards history
- authentication/session locking
- secure Rewards removal/recovery

Daily Rewards therefore requires a new reviewed SDK slice before the UI mocks can
be converted safely.

## 5. Provider-configuration rotation scope

The September 20 infographic labels R-01 through R-04 as not started. That is now
out of date.

| Infographic ID | Current implementation | Status |
| --- | --- | --- |
| R-01 Create Request | Builder calls `createConfigurationRequest()` | SDK-backed |
| R-02 Show Request QR | Builder displays opaque request QR, ID, and expiry | SDK-backed |
| R-03 Scan/Review Update | Builder scans/imports and calls `inspectConfigurationUpdate()` | SDK-backed |
| R-04 Apply/Complete | Builder confirms `applyConfigurationUpdate()` and sees safe outcome | SDK-backed |
| App Master counterpart | Scans/imports request, calls `inspectConfigurationRequest()` and `createConfigurationUpdate()` | SDK-backed |

Implemented safeguards include device binding, App Master authorization, expiry,
replay and downgrade rejection, environment checks, provider health validation,
and atomic promotion that preserves the prior healthy configuration on failure.

### Rotation work still remaining

- Run request/update exchange across two physical devices.
- Test wrong-device, replayed, expired, downgraded, wrong-environment, interrupted,
  and failed-health-check cases on devices.
- Confirm the previous provider configuration remains usable after every failed
  update.
- Exercise the documented old/new provider-key overlap and revocation procedure.

## 6. Platform and product gaps outside individual screens

- No authentication or user session
- No production-grade Builder identity or phone verification
- No general application backend client
- No production App Master role authorization
- No working notification action
- Limited loading, empty, offline, stale, and unauthenticated states outside
  activation/configuration paths
- No `integration_test/` suite
- Inter is declared but its font assets are not bundled
- Production/mainnet is blocked by two-device testnet verification and independent
  security approval

## 7. Verification state

The last recorded repository verification after rotation UI integration is:

- `flutter pub get` passed on 3 October 2026
- `flutter analyze` passed with no issues
- `flutter test` passed all 69 tests
- Feature code has no imports from `lib/wallet_sdk/src/`

Automated success is not a substitute for the required physical-device and
security gates.

## 8. Recommended next delivery order

1. Complete the two-physical-device testnet activation and rotation matrix.
2. Obtain independent security review and close release-blocking findings.
3. Define the daily Rewards public SDK contract, authentication policy, asset
   policy, fees, limits, and recovery/removal behavior.
4. Implement read-only daily Rewards first: balance, receive, and history.
5. Implement send as a separately reviewed prepare/review/authorize/submit/
   reconcile slice.
6. Replace mock lock and removal screens with real protected lifecycle behavior.
7. Add integration tests and remaining loading/offline/unauthenticated states.
8. Replace the mock App Master Builder-access roster only after its data and
   authorization architecture is approved.

## Bottom line

The wallet screen scope was not lost: it is documented in the wallet feature
folder and represented by routes/screens in the source tree. First-time activation,
App Master activation, provider setup, distributor authority, and configuration
rotation are implemented behind the Wallet SDK boundary. The main unfinished
product area is the **normal post-activation Rewards experience**—real balance,
receive, send, history, authentication/lock, and secure removal—plus the external
device/security gates required for release.
