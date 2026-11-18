# UI Recipes & Presentation Patterns

This document details integration recipes for connecting the headless `rewards_sdk` to Flutter presentation layers (GetX controllers, views), preserving the minimalist 'Perplexity' aesthetic (font-black headings, rounded-[32px] containers, generous whitespace, subtle animations).

## Architecture Rule

Controllers own `WalletSdk` instances and map typed outcomes and exceptions into reactive observables (`Rx<T>`). Views never touch raw transport or private cryptographic keys.

## Controller Recipe: Activation Flow

```dart
class WalletActivationController extends GetxController {
  WalletActivationController({required this.sdk});
  final WalletSdk sdk;

  final Rx<WalletActivationState> state = WalletActivationState.notActivated.obs;
  final RxString qrData = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;

  Future<void> startActivation(String name, String phone) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final view = await sdk.startActivation(
        BuilderIdentity(displayName: name, phone: phone),
      );
      qrData.value = view.qrValue;
      state.value = WalletActivationState.pendingApproval;
    } on WalletSdkException catch (e) {
      errorMessage.value = e.safeMessage;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onScannedResponse(String qrPayload) async {
    try {
      isLoading.value = true;
      final review = await sdk.inspectActivationResponse(qrPayload);
      await sdk.approveActivation(review.responseId);
      final status = await sdk.reconcileActivation();
      state.value = status.state;
    } on WalletSdkException catch (e) {
      errorMessage.value = e.safeMessage;
    } finally {
      isLoading.value = false;
    }
  }
}
```

## Perplexity-Style Card Container

```dart
Widget buildPerplexityContainer({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(32),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}
```
