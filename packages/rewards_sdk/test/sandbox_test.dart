import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rewards_sdk/rewards_sdk.dart';
import 'package:rewards_sdk/sandbox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SandboxWalletSdk headless verification', () {
    late SeedableSandbox sandbox;
    late WalletSdk builderSdk;
    late WalletSdk appMasterSdk;

    setUp(() {
      sandbox = SeedableSandbox(seed: 'test-seed-42');
      builderSdk = sandbox.createWalletSdk();
      appMasterSdk = sandbox.createWalletSdk();
    });

    test(
      'walks all 6 headless flows end-to-end within 5 seconds without network calls',
      () async {
        final stopwatch = Stopwatch()..start();

        // -------------------------------------------------------------
        // FLOW 1: Activation request
        // -------------------------------------------------------------
        final initialStatus = await builderSdk.getActivationStatus();
        expect(initialStatus.state, WalletActivationState.notActivated);

        final requestView = await builderSdk.startActivation(
          const BuilderIdentity(
            displayName: 'Alice Builder',
            phone: '+1234567890',
          ),
        );
        expect(requestView.requestId, startsWith('ACT-'));
        expect(requestView.qrValue, isNotEmpty);

        final restoredRequest = await builderSdk.restoreActivationRequest();
        expect(restoredRequest, isNotNull);
        expect(restoredRequest!.requestId, requestView.requestId);

        // -------------------------------------------------------------
        // FLOW 2: App Master approval
        // -------------------------------------------------------------
        await appMasterSdk.importDistributorSecret(
          SeedableSandbox.defaultDistributorSecret,
        );

        final requestReview = await appMasterSdk.inspectBuilderRequest(
          requestView.qrValue,
        );
        expect(requestReview.requestId, requestView.requestId);
        expect(requestReview.builder.displayName, 'Alice Builder');

        final responseView = await appMasterSdk.approveBuilderRequest(
          requestReview.requestId,
        );
        expect(responseView.responseId, startsWith('RES-'));
        expect(responseView.requestId, requestView.requestId);
        expect(responseView.qrValue, isNotEmpty);

        // -------------------------------------------------------------
        // FLOW 3: Activation completion
        // -------------------------------------------------------------
        final activationReview = await builderSdk.inspectActivationResponse(
          responseView.qrValue,
        );
        expect(activationReview.responseId, responseView.responseId);
        expect(activationReview.requestId, requestView.requestId);

        final approvedOutcome = await builderSdk.approveActivation(
          responseView.responseId,
        );
        expect(approvedOutcome.state, ActivationOutcomeState.submitted);

        final reconciledStatus = await builderSdk.reconcileActivation();
        expect(reconciledStatus.state, WalletActivationState.active);

        final activeStatus = await builderSdk.getActivationStatus();
        expect(activeStatus.state, WalletActivationState.active);

        // -------------------------------------------------------------
        // FLOW 4: Read surfaces
        // -------------------------------------------------------------
        final receiveIdentity = await builderSdk.getRewardsReceiveIdentity();
        expect(receiveIdentity.publicAccount, isNotEmpty);
        expect(receiveIdentity.qrValue, receiveIdentity.publicAccount);

        final balance = await builderSdk.getRewardsBalance();
        expect(double.parse(balance.available), greaterThanOrEqualTo(1.0));

        final initialHistory = await builderSdk.getRewardsHistory();
        expect(initialHistory.items, isA<List<RewardsHistoryItem>>());

        // -------------------------------------------------------------
        // FLOW 5: Transfer & Send
        // -------------------------------------------------------------
        final recipient = SeedableSandbox.defaultDistributorAccount;
        final recipientReview = await builderSdk.inspectRewardsRecipient(
          recipient,
        );
        expect(recipientReview.publicAccount, recipient);

        final transferReview = await builderSdk.prepareRewardsTransfer(
          publicAccount: recipient,
          amount: '0.25',
        );
        expect(transferReview.amount, '0.25');

        final authorization = await builderSdk.authorizeRewardsTransfer(
          transferReview.reviewId,
        );
        expect(authorization, isNotNull);

        final transferOutcome = await builderSdk.approveRewardsTransfer(
          transferReview.reviewId,
        );
        expect(transferOutcome.state, RewardsTransferState.confirmed);
        expect(transferOutcome.transactionHash, isNotEmpty);

        final transferStatus = await builderSdk.getRewardsTransferStatus();
        expect(transferStatus, isNotNull);
        expect(transferStatus!.state, RewardsTransferState.confirmed);
        expect(transferStatus.transactionHash, transferOutcome.transactionHash);

        // Check history records the payment
        final updatedHistory = await builderSdk.getRewardsHistory();
        expect(
          updatedHistory.items.any((item) => item.amount.contains('0.25')),
          isTrue,
        );

        // -------------------------------------------------------------
        // FLOW 6: Access and recovery
        // -------------------------------------------------------------
        final initialAccess = await builderSdk.getRewardsAccessState();
        expect(initialAccess, RewardsAccessState.unlocked);

        await builderSdk.lockRewards();
        final lockedAccess = await builderSdk.getRewardsAccessState();
        expect(lockedAccess, RewardsAccessState.locked);

        await builderSdk.unlockRewards();
        final unlockedAccess = await builderSdk.getRewardsAccessState();
        expect(unlockedAccess, RewardsAccessState.unlocked);

        final backup = await builderSdk.createRewardsBackup(
          'ValidPassword123!',
        );
        expect(backup, startsWith('BRB1.'));

        await builderSdk.confirmRewardsBackup(backup, 'ValidPassword123!');

        await builderSdk.eraseRewardsFromDevice();
        final removedAccess = await builderSdk.getRewardsAccessState();
        expect(removedAccess, RewardsAccessState.removed);

        await builderSdk.restoreRewardsBackup(backup, 'ValidPassword123!');
        final restoredAccess = await builderSdk.getRewardsAccessState();
        expect(restoredAccess, RewardsAccessState.locked);

        await builderSdk.unlockRewards();
        final unlockedAccess2 = await builderSdk.getRewardsAccessState();
        expect(unlockedAccess2, RewardsAccessState.unlocked);

        final restoredStatus = await builderSdk.getActivationStatus();
        expect(restoredStatus.state, WalletActivationState.active);

        stopwatch.stop();
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5000),
          reason: 'All 6 sandbox flows must execute in < 5 seconds.',
        );
      },
    );

    test('SeedableSandbox failNext simulates transient failure', () async {
      sandbox.failNext(WalletSdkFailureCode.providerServiceUnavailable);
      expect(
        sandbox.transport.pendingFailure,
        WalletSdkFailureCode.providerServiceUnavailable,
      );

      final failed = await sandbox.transport.send(
        http.Request(
          'GET',
          Uri.parse('https://horizon-testnet.stellar.org/fee_stats'),
        ),
      );
      expect(failed.statusCode, 504);
      expect(sandbox.transport.pendingFailure, isNull);

      final recovered = await sandbox.transport.send(
        http.Request(
          'GET',
          Uri.parse('https://horizon-testnet.stellar.org/fee_stats'),
        ),
      );
      expect(recovered.statusCode, 200);
    });

    test('SeedableSandbox reset restores clean state', () async {
      await builderSdk.startActivation(
        const BuilderIdentity(displayName: 'Bob', phone: '+9876543210'),
      );
      expect(await builderSdk.restoreActivationRequest(), isNotNull);

      sandbox.reset();
      expect(await builderSdk.restoreActivationRequest(), isNull);
    });
  });
}
