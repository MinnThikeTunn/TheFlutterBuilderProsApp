import 'package:flutter/widgets.dart';
import 'package:rewards_sdk/rewards_sdk.dart';
import 'package:rewards_sdk/sandbox.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ignore: avoid_print
  print('=== Rewards SDK Reference Harness (Headless Sandbox) ===');

  final sandbox = SeedableSandbox(seed: 'harness-seed-101');
  final builderSdk = sandbox.createWalletSdk();
  final appMasterSdk = sandbox.createWalletSdk();

  // -----------------------------------------------------------------
  // Flow 1: Activation Request
  // -----------------------------------------------------------------
  // ignore: avoid_print
  print('\n[Flow 1] Starting Activation...');
  final initialStatus = await builderSdk.getActivationStatus();
  // ignore: avoid_print
  print('  Initial status: ${initialStatus.state}');

  final requestView = await builderSdk.startActivation(
    const BuilderIdentity(
      displayName: 'Harness Builder',
      phone: '+15551234567',
    ),
  );
  // ignore: avoid_print
  print('  Activation request created: ${requestView.requestId}');

  // -----------------------------------------------------------------
  // Flow 2: App Master Approval
  // -----------------------------------------------------------------
  // ignore: avoid_print
  print('\n[Flow 2] App Master Approving Request...');
  await appMasterSdk.importDistributorSecret(
    SeedableSandbox.defaultDistributorSecret,
  );
  final review = await appMasterSdk.inspectBuilderRequest(requestView.qrValue);
  // ignore: avoid_print
  print('  Inspected request for: ${review.builder.displayName}');

  final responseView = await appMasterSdk.approveBuilderRequest(
    review.requestId,
  );
  // ignore: avoid_print
  print('  Approval response created: ${responseView.responseId}');

  // -----------------------------------------------------------------
  // Flow 3: Activation Completion
  // -----------------------------------------------------------------
  // ignore: avoid_print
  print('\n[Flow 3] Completing Activation...');
  await builderSdk.inspectActivationResponse(responseView.qrValue);
  final outcome = await builderSdk.approveActivation(responseView.responseId);
  // ignore: avoid_print
  print('  Submitted activation outcome: ${outcome.state}');

  final reconciled = await builderSdk.reconcileActivation();
  // ignore: avoid_print
  print('  Reconciled activation status: ${reconciled.state}');

  // -----------------------------------------------------------------
  // Flow 4: Read Surfaces
  // -----------------------------------------------------------------
  // ignore: avoid_print
  print('\n[Flow 4] Reading Surfaces...');
  final receiveIdentity = await builderSdk.getRewardsReceiveIdentity();
  // ignore: avoid_print
  print('  Receive Account: ${receiveIdentity.publicAccount}');

  final balance = await builderSdk.getRewardsBalance();
  // ignore: avoid_print
  print('  Rewards Balance: ${balance.available} ${balance.assetCode}');

  final history = await builderSdk.getRewardsHistory();
  // ignore: avoid_print
  print('  Rewards History count: ${history.items.length}');

  // -----------------------------------------------------------------
  // Flow 5: Transfer & Send
  // -----------------------------------------------------------------
  // ignore: avoid_print
  print('\n[Flow 5] Transfer & Send...');
  const recipient = SeedableSandbox.defaultDistributorAccount;
  await builderSdk.inspectRewardsRecipient(recipient);
  final transferReview = await builderSdk.prepareRewardsTransfer(
    publicAccount: recipient,
    amount: '0.50',
  );
  await builderSdk.authorizeRewardsTransfer(transferReview.reviewId);
  final transferOutcome = await builderSdk.approveRewardsTransfer(
    transferReview.reviewId,
  );
  // ignore: avoid_print
  print('  Transfer confirmed tx: ${transferOutcome.transactionHash}');

  final updatedBalance = await builderSdk.getRewardsBalance();
  // ignore: avoid_print
  print(
      '  Updated Balance: ${updatedBalance.available} ${updatedBalance.assetCode}');

  // -----------------------------------------------------------------
  // Flow 6: Access & Recovery
  // -----------------------------------------------------------------
  // ignore: avoid_print
  print('\n[Flow 6] Access and Recovery...');
  final backup = await builderSdk.createRewardsBackup('SecurePassword123!');
  // ignore: avoid_print
  print('  Backup generated: ${backup.substring(0, 12)}...');

  await builderSdk.confirmRewardsBackup(backup, 'SecurePassword123!');
  await builderSdk.eraseRewardsFromDevice();
  final removedState = await builderSdk.getRewardsAccessState();
  // ignore: avoid_print
  print('  State after erasure: $removedState');

  await builderSdk.restoreRewardsBackup(backup, 'SecurePassword123!');
  await builderSdk.unlockRewards();
  final restoredAccess = await builderSdk.getRewardsAccessState();
  // ignore: avoid_print
  print('  State after restore & unlock: $restoredAccess');

  // ignore: avoid_print
  print('\n=== All 6 Flows Executed Successfully! ===');
}
