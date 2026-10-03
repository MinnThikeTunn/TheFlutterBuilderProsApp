# Activation and Rotation Device Verification — 3 October 2026

Status: Not executed. This is an execution record for master-plan Phase 2.

Controlled integration attempt (2026-10-03): the separate
`com.thebuilderpros.thebuilderpros.integration` APK built; SHA256
`0E26762AA287468E0A4D20CD31F3BEA104B94157B9742EFBA03BA7CAA6DC1F61`.
Artifact: `build/app/outputs/flutter-apk/wallet-integration-debug.apk`.
The connected M2007J22C / Android 11 rejected installation with
`INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`. Neither controlled
device scenario ran. Both scenarios passed headlessly within all 153 tests.
This fixture run uses simulated native authentication/ledger/storage and does not
replace the actual native/two-device matrix below. See `release-closeout-3oct.md`.

## Build and participants

| Field | Record |
| --- | --- |
| Build identifier / artifact hash | Current ordinary debug APK with integration build isolation, built 2026-10-03; SHA256 `37CB3AC801A5CAD9241B1B24D3A7CCE0EAC378AED674735549DBB0A55A6B2877` |
| Builder device / OS | Pending assignment |
| App Master device / OS | Pending assignment |
| Environment | Testnet only |
| Tester / date | Pending |

Device discovery on 3 October found one connected physical Android device,
M2007J22C running Android 11. A second physical device is required. Connection
discovery is not verification of application behavior.

Artifact: `build/app/outputs/flutter-apk/app-debug.apk`. Build succeeded; the
matrix below has not been run. Rebuild and update the hash if code changes before testing.

The original transport-only build had SHA256
`2FCB7B6EF3DD525A79F1D6634235EC725A6453D06728335EE15E7EFD9E5B8EE9`.
The subsequent authorization-only build had SHA256
`AC46E408660C9BDA11FCAAF3A3008E2B551A62AEB21622F46E1501B0F342CAA3`.
The previous testnet-send build had SHA256
`6AC084512856908BB7C887A6DC6253065F75355965102400C6390AE329324F4D`.
These are superseded by the local-access/removal build above, which includes active
identity/migration, read operations, transfer preparation/authorization, signing,
single submission, durable hash reconciliation, native local lock, and retained-
material access removal/restoration. No physical matrix was run.

Additional native authorization checks remain open: biometric success, native
PIN/passcode fallback, no device lock/enrollment, cancellation, lockout, real
background/resume, review expiry, changed account/fee/sequence, and leaving review.
Verify no payment submission occurs after failed/cancelled authentication and old approvals never survive cancellation,
replacement, background, expiry, or restart. Check Android minimum-supported OS;
iOS/macOS/Windows native behavior needs its own platform evidence.

Additional testnet-send checks remain pending: one exact payment after successful
native approval; duplicate taps produce one POST; changed sequence/fee/funds or
expired review prevents POST; interrupted submission/restart restores only hash
lookups; uncertain status blocks another send; confirmed/failed states match the
ledger; production sends are refused. 404/expiry must never clear uncertainty or
trigger resubmission. Preserve the device when status cannot be resolved.

Local-access checks also remain pending: explicit lock and background/restart
revocation; native unlock does not approve a payment; locking during preparation
rejects its result; removal refuses pending sends; removal survives interruption
and restart; role switching/direct routes cannot re-enable reads or signing;
native restoration retains the same account; unreadable/partial protected marker
fails closed. Signing material and ledger balances must remain unchanged by access
removal. Permanent erasure and off-device recovery are not implemented.

Use disposable accounts and externally supplied test credentials. Record only
redacted outcomes; never include seeds, API keys, transaction envelopes, or
decoded protected QR payloads.

## Test matrix

Every row starts pending. For each case record build, result, redacted evidence,
and any defect/retest reference.

| ID | Case | Expected result | Result / evidence |
| --- | --- | --- | --- |
| A01 | Configure App Master provider and distributor; restart | Healthy configuration and masked authority restore | Pending |
| A02 | Clean Builder request, camera scan, approval, response, reconciliation | Verified Rewards activation on testnet | Pending |
| A03 | Repeat acquisition using gallery images | Same validated handshake | Pending |
| A04 | Duplicate taps/scans/approval | No duplicate signing/submission/funding | Pending |
| A05 | Request/response expiry, alteration, replay | Safe rejection; protected state remains consistent | Pending |
| A06 | Wrong device/environment response | Safe rejection; no configuration promotion | Pending |
| A07 | Restart during request and review | Correct pending state restores | Pending |
| A08 | Interrupt connection around submission; restart | Persisted identity reconciles without blind resubmission | Pending |
| A09 | Definite rejected transaction | Safe rejected outcome; no false active state | Pending |
| A10 | Restart after verified activation | Active Rewards restore without resubmission | Pending |
| R01 | Create newer provider configuration with old key overlap | Both operational keys available during migration | Pending |
| R02 | Builder request, App Master update, Builder review/apply | New healthy version promotes on intended device | Pending |
| R03 | Rotation through gallery acquisition | Same validated update behavior | Pending |
| R04 | Wrong-device/environment, altered, expired update | Rejected; previous configuration remains usable | Pending |
| R05 | Replay and downgrade | Rejected; version does not regress | Pending |
| R06 | Candidate provider health failure | Previous configuration remains usable | Pending |
| R07 | Interrupt/restart during update | Consistent restored state and safe retry | Pending |
| R08 | Revoke old key after migration checks | Updated device remains operational | Pending |

Follow [the provider operations SOP](provider-operations-sop.md) for overlap and
revocation. Use controlled test fixtures where a failure cannot be produced safely
through ordinary UI; record the fixture and distinguish it from a live-provider test.

## Gate outcome

- Passing matrix: pending.
- Defects and retests: pending.
- Independent security reviewer and approval: pending, tracked separately.
- Production/mainnet: blocked until required device and security gates close.
