import 'package:flutter_test/flutter_test.dart';
import 'package:rewards_sdk/rewards_sdk.dart';
import 'package:rewards_sdk/sandbox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('smoke test runs all 6 headless flows end-to-end', () async {
    final sandbox = SeedableSandbox(seed: 'smoke-test-seed');
    final builderSdk = sandbox.createWalletSdk();
    final appMasterSdk = sandbox.createWalletSdk();

    // Flow 1
    final initialStatus = await builderSdk.getActivationStatus();
    expect(initialStatus.state, WalletActivationState.notActivated);

    final request = await builderSdk.startActivation(
      const BuilderIdentity(displayName: 'Test Builder', phone: '+1234567890'),
    );
    expect(request.requestId, startsWith('ACT-'));

    // Flow 2
    await appMasterSdk.importDistributorSecret(
      SeedableSandbox.defaultDistributorSecret,
    );
    final review = await appMasterSdk.inspectBuilderRequest(request.qrValue);
    final response = await appMasterSdk.approveBuilderRequest(review.requestId);
    expect(response.responseId, startsWith('RES-'));

    // Flow 3
    await builderSdk.inspectActivationResponse(response.qrValue);
    final outcome = await builderSdk.approveActivation(response.responseId);
    expect(outcome.state, ActivationOutcomeState.submitted);

    final reconciled = await builderSdk.reconcileActivation();
    expect(reconciled.state, WalletActivationState.active);

    // Flow 4
    final receive = await builderSdk.getRewardsReceiveIdentity();
    expect(receive.publicAccount, isNotEmpty);

    final balance = await builderSdk.getRewardsBalance();
    expect(double.parse(balance.available), greaterThanOrEqualTo(1.0));

    final history = await builderSdk.getRewardsHistory();
    expect(history.items, isNotEmpty);

    // Flow 5
    const recipient = SeedableSandbox.defaultDistributorAccount;
    await builderSdk.inspectRewardsRecipient(recipient);
    final transferReview = await builderSdk.prepareRewardsTransfer(
      publicAccount: recipient,
      amount: '0.25',
    );
    await builderSdk.authorizeRewardsTransfer(transferReview.reviewId);
    final transferOutcome = await builderSdk.approveRewardsTransfer(
      transferReview.reviewId,
    );
    expect(transferOutcome.state, RewardsTransferState.confirmed);

    // Flow 6
    final backup = await builderSdk.createRewardsBackup('SecretPass123!');
    expect(backup, startsWith('BRB1.'));

    await builderSdk.confirmRewardsBackup(backup, 'SecretPass123!');
    await builderSdk.eraseRewardsFromDevice();
    expect(
      await builderSdk.getRewardsAccessState(),
      RewardsAccessState.removed,
    );

    await builderSdk.restoreRewardsBackup(backup, 'SecretPass123!');
    expect(await builderSdk.getRewardsAccessState(), RewardsAccessState.locked);

    await builderSdk.unlockRewards();
    expect(
      await builderSdk.getRewardsAccessState(),
      RewardsAccessState.unlocked,
    );
    expect(
      (await builderSdk.getActivationStatus()).state,
      WalletActivationState.active,
    );
  });
}
