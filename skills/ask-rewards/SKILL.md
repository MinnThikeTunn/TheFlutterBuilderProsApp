---
name: ask-rewards
description: Ask anything about rewards_sdk—full capabilities, what is implemented vs. left in your app, and which rewards-build stage or API to use next.
disable-model-invocation: true
---

# Ask Rewards

Your read-only assistant and coverage auditor for `rewards_sdk` and the `rewards-build` workflow.

## Answer by intent

Route the user's question to one (or more) of the four modes below, then **stop**—never edit project files or run mutating setup scripts unless the user explicitly asks to switch from Q&A into implementation.

1. **"What does the SDK offer?" / Capability, API & boundary questions**
   Read [sdk-offer-catalog.md](references/sdk-offer-catalog.md) for the complete 8-domain catalog (41 `WalletSdk` methods, `SeedableSandbox`, `RewardsRecoveryPage`, `AppMasterRosterPage`, models, and explicit non-goals).

2. **"Which functionalities are implemented and which are left?" / Coverage audit**
   Run the **Workspace Coverage Audit** below against the current directory, comparing observed integration against [sdk-offer-catalog.md](references/sdk-offer-catalog.md).

3. **"How do I build / integrate / test X?" / Next-step routing**
   Use the **Workflow Map** below to point to the exact `skills/rewards-build/` stage, verification gate, or recipe—including prerequisites and commands.

4. **"Why am I getting error X?" / Failure & troubleshooting**
   Check `skills/rewards-build/references/failure-codes.md` (and [sdk-offer-catalog.md](references/sdk-offer-catalog.md) for the full 49-code `WalletSdkFailureCode` list) for cause, `canRetry`, and user recovery action.

---

## Workspace Coverage Audit (Read-Only)

When asked what is implemented vs. what is left in the current project, inspect these sources in order before answering:

1. **SDK Dependency & Build Act**
   - `pubspec.yaml`: check how `rewards_sdk` is wired (`path: packages/rewards_sdk`, git ref, or missing).
   - `.rewards/installed.json` and `.rewards/state.json` (if present): report installed version and highest passed Act (`0` preflight, `1` sandbox, `2` testnet, `3` production).
2. **Wired `WalletSdk` Methods (`lib/`)**
   - Search `lib/` (excluding `packages/rewards_sdk/`) for `WalletSdk` method calls and `RewardsRecoveryPage` / `AppMasterRosterPage` references.
   - Check `lib/` for any forbidden `rewards_sdk/sandbox.dart` imports (only allowed in `test/` or `templates/rewards_harness/`).
3. **Native Prerequisites**
   - Android: `android/app/src/main/AndroidManifest.xml` (`USE_BIOMETRIC`, `INTERNET`), `MainActivity` (`FlutterFragmentActivity`), `android/app/build.gradle*` (`minSdk >= 23`).
   - iOS: `ios/Runner/Info.plist` (`NSFaceIDUsageDescription`).
4. **Output Format**
   Present three concise sections grounded in observed files:
   - **Implemented**: capabilities/methods actively wired (with file paths).
   - **Left / Not Yet Wired**: remaining domains or methods from the 41 `WalletSdk` APIs, `RewardsRecoveryPage`, or native configs.
   - **Recommended Next Step**: the exact `/rewards-build` stage, script, or API call to tackle next.

---

## Workflow Map (`skills/rewards-build/`)

### Main Integration Flow (Act 0 → Act 3)

| Act / Stage | Purpose | Gate / Script |
| :--- | :--- | :--- |
| **Act 0: Preflight** | Toolchain (`flutter`, `dart`), branch hygiene, dependency bootstrap | `skills/rewards-build/stages/00-preflight.md` • `bootstrap.ps1` • `verify.ps1 -Act 0` |
| **Act 1: Sandbox** | Run all 6 flows in-memory with `SeedableSandbox` (<5s, 0 network) | `skills/rewards-build/stages/01-sandbox.md` • `verify.ps1 -Act 1` |
| **Act 2: Testnet** | Live Stellar Testnet, Friendbot funding, `REWARD` trustline & minting | `skills/rewards-build/stages/02-testnet.md` • `seed-testnet.ps1` • `verify.ps1 -Act 2` |
| **Act 3: UI Integration** | Bind GetX / Riverpod / Bloc / Vanilla Flutter UI to `WalletSdk` | `skills/rewards-build/stages/03-ui-integration.md` • `references/ui-recipes.md` |
| **Act 4: Production** | Mainnet custody, cold Issuer key, NOWNodes, zero `sandbox.dart` in `lib/` | `skills/rewards-build/stages/04-production.md` • `verify.ps1 -Act 3` |

### Key References

- [sdk-offer-catalog.md](references/sdk-offer-catalog.md) — Full 8-domain capability offer, all 41 `WalletSdk` methods, 49 failure codes, sandbox & non-goals.
- `skills/rewards-build/references/sdk-contract.md` — Method signatures by flow.
- `skills/rewards-build/references/failure-codes.md` — `WalletSdkFailureCode` catalog and recovery actions.
- `skills/rewards-build/references/native-setup.md` — Android KeyStore & iOS Keychain configuration.
- `skills/rewards-build/references/ui-recipes.md` — State management controller & Perplexity-style UI recipes.
- `skills/rewards-build/references/test-plan.md` — Verification matrix across Acts 0–3.
