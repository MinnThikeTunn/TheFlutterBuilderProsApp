# Wallet integration and release review — 3 October 2026

Status: automated coverage delivered; device run blocked; production sending remains blocked.
This is a review package, not independent security approval.

## Automated integration scope

`integration_test/wallet_flow_test.dart` runs the real app, controllers, SDK,
Horizon transport, payment construction/signing, ledger-envelope verification,
and access lifecycle. The same scenarios run headlessly through
`test/wallet_flow_test.dart` using `test/support/wallet_flow_scenarios.dart`.

Accounts/credentials are generated transiently. Activation starts from a verified
fixture; network responses, native authentication, and storage are controlled.
No real provider calls, payments, persistent credentials or existing app data are
used. Restart means reconstructing the app and SDK against retained test evidence;
it is not an OS process-kill/storage durability test.

Scenarios:

- Verified startup, public Receive QR, exact review, one signed payment,
  hash-confirmed outcome, refreshed balance, direct-payment history, native-adapter
  unlock, retained-material removal, reconstructed startup and account restoration.
- Accepted-but-not-visible transaction, uncertain outcome, reconstructed startup,
  blocked new send/removal, later hash-only reconciliation, and exactly one POST.

On Android, integration targets and Flutter's generated test listener use the
`.integration` package suffix to preserve the ordinary installed app/data sandbox.
Inspect the compiled APK package before device execution. Production build entry
points retain the ordinary package. The integration app is not a release artifact.

Run headlessly:

```powershell
flutter test test/wallet_flow_test.dart
```

Run on an available device:

```powershell
flutter test integration_test/wallet_flow_test.dart -d <device-id>
```

Workflow follows [Flutter integration testing](https://docs.flutter.dev/testing/integration-tests)
and [Android application ID suffixes](https://developer.android.com/build/build-variants).

## Independent review map

| Boundary | Implementation | Evidence / unresolved review |
| --- | --- | --- |
| App/SDK separation | `wallet_sdk.dart`, `default_wallet_sdk.dart` | Feature code uses public facade; private protocol/credentials stay inside SDK |
| Authorized configuration and rotation | configuration handshake/policy, activation response services | Existing binding/tamper/replay tests; two-device rotation matrix still pending |
| Custody and native authentication | credential store, transfer authorization, Rewards access service | Existing ownership/lifecycle/replay tests; real device prompt and storage-security evidence pending |
| Exact transaction intent | Rewards amount, transfer client, send service | Integer precision, capacity/reserve/fees/sequence checks; native grant consumed at single POST boundary |
| Durable uncertainty | Rewards send store/client/service | Pre-submit hash/public intent, no saved envelope/seed, signed ledger binding; never-ingested/pruned hash recovery policy remains open |
| Lock/removal | Rewards access service and SDK guards | Local access disablement retains custody/evidence; interrupted write fails closed; permanent key erasure/off-device recovery undesigned |
| Transport | Horizon HTTP client | Bounds, deadlines, header/form encoding and failure tests; no automatic payment retry |
| Release packaging | Android Gradle and platform auth setup | Debug artifacts only; production signing/store identity and platform evidence remain open |

## Release gates still open

Executed on 2026-10-03: dependency resolution, clean analysis and all 153 headless
tests passed (including both shared scenarios). The isolated Android APK built and
its `.integration` package was verified. Installation on M2007J22C / Android 11
was rejected with `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`.
No on-device scenario ran. The ordinary debug APK also rebuilt with its original
package ID; its hash is recorded in the device execution record. Windows desktop
lacks the Visual Studio C++ toolchain.

1. Two physical devices: actual activation/rotation and disposable testnet send,
   including network interruption, process kill/restart and duplicate prevention.
2. Real biometrics/device-credential fallback, cancellation/lockout/background,
   supported OS coverage and real protected-storage interruption/restore behavior.
3. Independent SDK/security review, findings closure and explicit production
   authorization. Automated tests do not approve release.
4. Explicit operational recovery for unresolved/absent ledger hashes; acceptance
   of retained-material local removal. Permanent erasure/off-device recovery must
   be designed separately if required for release.
5. Production signing/store identity, platform release builds and any separately
   required product gaps (identity verification, notifications, backend/roles).

App Master roster remains Phase 9: its data source, privacy boundaries and real
role authorization must be defined before replacing mock rows. This package does
not invent a backend or treat the testing role switch as authorization.

Record executed checks and artifact identities in
`two-device-verification-3oct.md`; leave unexecuted real-device cases pending.
## Send configuration policy update — 2026-10-03

Removed the test-only Send restriction from both the facade and private send service. Send uses the existing App Master-provisioned environment for signing and transaction hashing; reconciliation already uses the record's environment. Identity, review and configuration must agree. Native authentication, funds/recipient validation, exact-review approval and durable duplicate-send protection remain enforced. Security review/testing are release work, not an SDK production-network switch. Earlier statements that production sending is blocked are superseded. Added fixture coverage for production signing and network mismatch; it has not been run. Verification remains deferred by user instruction.

Remaining feature gaps: off-device recovery/backup and permanent credential erasure need the concrete authorized vault and custody policy. Uncertain sends reconcile by original hash and remain pending without authoritative resolution; a terminal recovery/support path for never-confirmed sends is not implemented. GitHub push remains paused at the user's instruction. No network-settings decision is needed for this change.
