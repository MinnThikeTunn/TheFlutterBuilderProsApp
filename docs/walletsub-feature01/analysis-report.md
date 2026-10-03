# Wallet Sub-Feature 01 — Analysis Report

Date: 2026-09-20  
Scope: Compare the repository implementation against `AGENTS.md`, `context/*`, and `docs/` (including this folder).  
Method: Static review of documentation and code. Automated checks (`flutter analyze`, `flutter test`) were not re-run for this report.

**Follow-up (same day):** The recommended documentation syncs in Section 8 were
applied to `context/*` and the stale docs listed there. This report remains the
analysis snapshot; runtime truth is `context/current-state.md`.

## 1. Verdict

The application structure and Wallet SDK boundary largely follow the architecture and code standards described in context. The first-time activation handshake (Steps 1–14) is present in code behind the public `WalletSdk` facade.

The main problem is documentation drift. Several “current limitations” and early status statements still describe activation as presentation-only, which contradicts later Step 7–16 write-ups and the controllers that call real SDK operations.

Post-activation Rewards operations (balance, receive, send, history) remain mock. Provider-configuration rotation exists in the SDK but has no Flutter UI. Production remains gated on two-device testnet verification and independent security approval.

## 2. Sources reviewed

### Repository rules

- `AGENTS.md`

### Context

- `context/project-overview.md`
- `context/current-state.md`
- `context/architecture.md`
- `context/code-standards.md`
- `context/ui-context.md`
- `context/decision-log.md`
- `context/progress-tracker.md`
- `context/ai-workflow-rules.md`

### Feature docs

- `docs/QRhandshakespec.md`
- `docs/walletsub-feature01/stepbystep.md`
- `docs/walletsub-feature01/walletSDKspec.md`
- `docs/walletsub-feature01/rewards-first-time-activation-spec-v2.md`
- `docs/walletsub-feature01/01-screen-list.md`
- Related plans, sequence diagrams, and `provider-operations-sop.md`

### Implementation sampled

- `lib/main_app.dart`, routing, bindings
- `lib/app/features/wallet/` and `lib/app/features/app_master/`
- `lib/wallet_sdk/wallet_sdk.dart` and private `src/`
- `pubspec.yaml`, Android application ID
- `test/` suite layout

## 3. What aligns

| Claim | Evidence |
| --- | --- |
| Flutter / Dart `^3.9.2`, GetX `^4.7.2`, Material 3 | `pubspec.yaml`, `main_app.dart`, `AppTheme` |
| Package `the_builder_pros`, Android ID `com.thebuilderpros.thebuilderpros` | `pubspec.yaml`, `android/app/build.gradle.kts` |
| Features under `lib/app/features/`; Profile is widgets only | Matches architecture and decision log |
| Controllers extend `BaseController`; route screens extend `BaseView` | Wallet and App Master screens/controllers |
| Centralized routes; initial route is Rewards / wallet not-activated | `AppPages.initial` → `Routes.wallet` |
| Brand color tokens match UI context | `AppColors` values match `ui-context.md` |
| Feature code imports only `wallet_sdk/wallet_sdk.dart` | No `lib/wallet_sdk/src/` imports under `lib/app/` |
| No `stellar_flutter_sdk` dependency | Absent from `pubspec.yaml` |
| Activation request create/restore/cancel via SDK | `WalletController` + SDK |
| App Master inspect / approve request via SDK | `AppMasterController` |
| Builder inspect / approve response, reconcile via SDK | `WalletController` |
| App Master Advanced NOWNodes + distributor secret import | Wired to public SDK APIs |
| Live App Master overview capacity / Rewards availability facade | `getAppMasterOverview()` |
| User-facing copy mostly uses Rewards language | Screens use Rewards titles; Advanced may name NOWNodes |

## 4. Critical documentation mismatches

### 4.1 `context/current-state.md` contradicts itself

Early Runtime and Implemented Presentation sections still imply that App Master activation and activation-response flows are presentation prototypes, including “display/save a mock activation QR.”

**Current Limitations** still lists as missing:

- completed App Master request inspection after QR acquisition
- Builder-side activation response inspection, approval, submission, reconciliation

Those bullets conflict with the same file’s Step 7–14 narrative and with controller calls such as:

- `inspectBuilderRequest`
- `approveBuilderRequest`
- `inspectActivationResponse`
- `approveActivation`
- `reconcileActivation`

**Recommended ownership:** rewrite Runtime, Presentation, and Limitations so activation is described as implemented, and limitations cover only remaining product gaps (see Section 6).

### 4.2 `context/decision-log.md` (2026-09-18 QR activation)

The recorded result still says QR and activation behavior remains presentation-only. That outcome is obsolete relative to Steps 11–14.

**Recommended ownership:** add a superseding decision entry, or amend the Result of that entry.

### 4.3 `docs/QRhandshakespec.md`

Status banner: design specification and not yet implemented. The mobile-to-mobile activation handshake is substantially implemented.

**Recommended ownership:** change status to “design reference; activation path implemented through Steps 1–14; remaining gaps noted elsewhere.”

### 4.4 `docs/walletsub-feature01/stepbystep.md` baseline

The top “Current baseline” / “Temporary implementation” section still claims:

- `stellar_flutter_sdk` for key generation
- inline activation QR encoding
- App Master NOWNodes as a UI mock

That is pre–Step 1–4 history. Later per-step statuses are closer to the code.

**Recommended ownership:** replace the baseline with a short pointer to completed Steps 1–16 and the open release gates.

### 4.5 `context/progress-tracker.md` backlog wording

The tracker correctly notes Steps 1–9 device-verified and 10–16 automated, but backlog item 1 still reads as “Complete Wallet SDK Steps 1–16 with user verification,” which understates completion and overstates remaining SDK work.

**Recommended ownership:** rephrase backlog to two-device testnet gate, security approval, post-activation Rewards ops, and configuration-rotation UI.

## 5. Spec vs implementation gaps

### 5.1 Screen list (`01-screen-list.md`)

| Spec ID | Intent | Status |
| --- | --- | --- |
| B-01–B-03 | Not activated, request QR, review | Implemented with SDK |
| B-04 | Dedicated activation progress screen | Not a separate route; progress/outcome handled on review |
| B-05–B-14 | Overview, receive, send, history, lock, remove | Present as screens; balance/receive/send/history remain mock |
| M-01–M-03 | Overview, review, response QR | Implemented with SDK for activation path |
| M-04 | Advanced + configuration rotation | NOWNodes and distributor import real; rotation UI missing |
| M-05 | My Rewards reuses Builder screens | Role switch exists; Rewards ops still mock |

### 5.2 Configuration rotation (Step 15)

`WalletSdk` exposes:

- `createConfigurationRequest`
- `inspectConfigurationRequest`
- `createConfigurationUpdate`
- `inspectConfigurationUpdate`
- `applyConfigurationUpdate`

No App Master or Builder screen/controller currently calls these APIs. Rotation is SDK-tested, not product-wired.

### 5.3 `walletSDKspec.md` public surface

The implemented facade is close to the spec and adds product-needed methods such as:

- `reconcileActivation`
- distributor authority import / status / remove
- `getAppMasterOverview`
- restore helpers for inspected requests

Naming differs slightly (for example `WalletActivationStatus` vs a simpler `ActivationStatus` in the written interface). Treat the Dart facade as authoritative; update the spec when convenient.

### 5.4 `rewards-first-time-activation-spec-v2.md`

End-to-end activation steps 0–13 match the intended SDK-backed flow and are largely present. Remaining product work after verified activation is outside that activation-only spec (live balance, send/receive, history).

## 6. Accurate current limitations

These claims remain true against the code and should stay in `current-state.md`:

- No authentication or user session
- No general application backend client
- No real Rewards balance, history, transfer, or day-to-day custody/signing UX
- Receive / send / overview balance / history are mock or presentation-only
- App Master “Builder access” list still uses mock rows
- No working notification action
- Limited loading / offline / unauthenticated product states outside activation paths
- No production-grade identity or phone verification
- No dedicated B-04 progress route
- No Flutter UI for provider configuration rotation
- No `integration_test/` suite
- Inter is declared in theme but not bundled as font assets
- Production/mainnet blocked pending two-physical-device testnet gate and independent security approval

## 7. Architecture and standards notes

### Strong adherence

- Feature modules, bindings, centralized routes, shared resources
- Wallet SDK black-box boundary for features
- Opaque QR values in UI; private crypto, XDR, Horizon, and storage under `lib/wallet_sdk/src/`
- Tests under `test/` for SDK slices, boundary import, and widget flows

### Minor gaps

- `architecture.md` stack table omits the Wallet SDK layer and supporting packages (`http`, `cryptography`, `flutter_secure_storage`, `mobile_scanner`, `qr_flutter`, `image_picker`)
- Internal code identity still uses `wallet` paths and route names; Builder-facing copy correctly prefers Rewards language (`project-overview.md`)
- App Master Advanced correctly hosts privileged NOWNodes and distributor-secret controls; those must never appear on Builder surfaces

## 8. Recommended documentation actions

Priority order — **applied on 2026-09-20**:

1. Synced `context/current-state.md` Runtime, Presentation, and Limitations with Steps 7–14 reality.
2. Superseded the decision-log “presentation-only” QR result (`2026-09-20` entry).
3. Refreshed `stepbystep.md` baseline and `QRhandshakespec.md` status.
4. Clarified `progress-tracker.md` active backlog around release gates and remaining product UI.
5. Aligned `walletSDKspec.md` public interface notes and `01-screen-list.md` status columns for B-04 and M-04.
6. Expanded `context/architecture.md` stack table for the Wallet SDK and supporting packages.
7. Clarified `context/ui-context.md` navigation wording for SDK-backed vs mock surfaces.

## 9. Recommended product / engineering next steps

From `stepbystep.md` and the open gaps above:

1. Run the Step 16 two-physical-device testnet activation and provider-rotation gate.
2. Obtain independent security approval before production/mainnet.
3. Wire configuration-request/update screens to the existing SDK APIs.
4. Replace mock receive/send/history/overview balance with SDK-backed Rewards operations when that slice is planned.
5. Add integration tests on physical devices when activation and rotation gates pass.

## 10. How to use this report

- This file is an analysis snapshot, not runtime truth.
- Runtime capability claims belong in `context/current-state.md`.
- Backlog and completion belong in `context/progress-tracker.md`.
- Durable product/architecture choices belong in `context/decision-log.md`.
- Step gating details remain in `docs/walletsub-feature01/stepbystep.md`.
