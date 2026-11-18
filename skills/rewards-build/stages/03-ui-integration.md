# Stage 03: Custom UI & Presentation Wiring

This stage guides the consumer in connecting their custom Flutter presentation layer (GetX, Bloc, Riverpod, or vanilla Flutter) to the headless `WalletSdk`.

## Key Architectural Principles

1. **Strict Decoupling**:
   - `packages/rewards_sdk` contains no UI widgets, dialogs, or framework dependencies.
   - Consumers write their own screens and controllers.
2. **Controller Pattern**:
   - The UI controller holds a `WalletSdk` instance.
   - SDK operations return typed immutable models (`ActivationRequestView`, `RewardsBalanceView`, `RewardsTransferOutcome`).
   - SDK errors throw typed `WalletSdkException` with localized `.safeMessage` and `.canRetry`.

## Copy-Paste Recipes

Exhaustive recipes for GetX, Riverpod, Bloc, and QR rendering are provided in the technical reference:
- [ui-recipes.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/references/ui-recipes.md)

## Next Stage

Once your custom UI is integrated with the sandbox or testnet:
- [04-production.md](file:///D:/TheFlutterBuilderProsApp/skills/rewards-build/stages/04-production.md): Review production readiness criteria.
