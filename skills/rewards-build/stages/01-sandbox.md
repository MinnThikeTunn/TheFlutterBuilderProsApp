# Stage 01: Deterministic Sandbox Verification

This stage verifies that all 6 core Builder Rewards flows execute headlessly in an in-memory sandbox without any physical network calls.

## Overview

The `SeedableSandbox` (exported via `package:rewards_sdk/sandbox.dart`) simulates:
- In-memory credential and secure stores.
- Simulated Stellar Horizon HTTP transport (handling `/accounts`, `/fee_stats`, `/ledgers`, `/transactions`, and `/payments`).
- Configurable clock and failure simulation (`failNext()`).

## The 6 Headless Flows

1. **Activation Request**: Builder generates an activation keypair, creates a signed `ACT-...` activation request, and encodes it into a QR string.
2. **App Master Approval**: App Master authority imports distributor secret, inspects the QR request, builds the activation transaction envelope, and signs it into a `RES-...` package.
3. **Activation Completion**: Builder inspects the `RES-...` package, co-signs the envelope, submits it to the Horizon transport, and reconciles the verified ledger state.
4. **Read Surfaces**: Querying public receiving identity, checking spendable Rewards balances, and querying paginated payment history.
5. **Transfer & Send**: Inspecting counterparty receiving capacity, preparing transfer review, authenticating via native prompt, and broadcasting the signed payment transaction.
6. **Access & Recovery**: Biometric lock/unlock states, creating an AES-256-GCM encrypted backup (`BRB1....`), confirming the backup, securely erasing the device, and restoring from backup.

## Running the Sandbox Tests

To run the sandbox test suite:

```powershell
cd packages/rewards_sdk
flutter test test/sandbox_test.dart
```

## Running the Reference Harness

To run the standalone harness smoke test and CLI demonstration:

```powershell
cd templates/rewards_harness
.\run.ps1
```
