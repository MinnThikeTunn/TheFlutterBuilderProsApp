import 'dart:math';

import 'package:rewards_sdk/rewards_sdk.dart';
import 'package:rewards_sdk/src/authority/distributor_authority_service.dart';
import 'package:rewards_sdk/src/configuration/configuration_policy.dart';
import 'package:rewards_sdk/src/configuration/provider_configuration.dart';
import 'package:rewards_sdk/src/crypto/wallet_key_generator.dart';
import 'package:rewards_sdk/src/default_wallet_sdk.dart';
import 'package:rewards_sdk/src/recovery/rewards_recovery_service.dart';
import 'package:rewards_sdk/src/sandbox/sandbox_stores.dart';
import 'package:rewards_sdk/src/sandbox/sandbox_transport.dart';
import 'package:rewards_sdk/src/time/wallet_clock.dart';
import 'package:rewards_sdk/src/transport/horizon_http_client.dart';

final class SeedableSandbox {
  SeedableSandbox({this.seed}) {
    _init();
  }

  final String? seed;

  static const String defaultDistributorAccount =
      'GAJDTB7GW62XGIBEQHL2BA5HJEXYZCZNCUOS74NJGPFUHCVP4H4E7LGC';
  static const String defaultDistributorSecret =
      'SCK2DSDCDAV6CKZKJ4H3IL5TI2UQAY5IRS57W5GXSHAPUOCU53BKZDV4';
  static const String defaultIssuerAccount =
      'GANEIB42TJEFUCH7PDLMEYW6EJJNP2I74P6ZB5BB56QBO5SUBWWU3JDU';
  static const String defaultAssetCode = 'REWARD';

  late DateTime _currentTime;
  late final CallbackWalletClock clock = CallbackWalletClock(
    () => _currentTime,
  );

  late final SandboxCredentials credentials;
  late final SandboxActivationStore activationStore;
  late final SandboxInspectionStore inspectionStore;
  late final SandboxHandshakeStore handshakeStore;
  late final SandboxActiveRewardsStore activeRewardsStore;
  late final SandboxSendStore sendStore;
  late final SandboxSubmissionStore submissionStore;
  late final SandboxConfigurationStore configurationStore;
  late final SandboxDistributorAuthorityStore distributorAuthorityStore;
  late final SandboxAuthenticator authenticator;
  late final SandboxTransport transport;

  void _init() {
    _currentTime = DateTime.utc(2026, 10, 3, 12, 0, 0);

    credentials = SandboxCredentials();
    activationStore = SandboxActivationStore();
    inspectionStore = SandboxInspectionStore();
    handshakeStore = SandboxHandshakeStore();
    activeRewardsStore = SandboxActiveRewardsStore();
    sendStore = SandboxSendStore();
    submissionStore = SandboxSubmissionStore();
    configurationStore = SandboxConfigurationStore(
      initial: ProviderConfiguration(
        endpoint: Uri.parse('https://horizon-testnet.stellar.org'),
        apiKey: '',
        environment: ProviderEnvironment.test,
        version: 1,
        activationFundingUnits: 21000000,
        initialRewardsUnits: 10000000,
      ),
    );
    distributorAuthorityStore = SandboxDistributorAuthorityStore(
      initialSecret: defaultDistributorSecret,
    );
    authenticator = SandboxAuthenticator();
    transport = SandboxTransport(
      clock: clock,
      distributorAccountId: defaultDistributorAccount,
      issuerAccountId: defaultIssuerAccount,
      assetCode: defaultAssetCode,
    );
  }

  void reset() {
    _currentTime = DateTime.utc(2026, 10, 3, 12, 0, 0);
    credentials.clear();
    activationStore.clear();
    inspectionStore.clear();
    handshakeStore.clear();
    activeRewardsStore.clear();
    sendStore.clear();
    submissionStore.clear();
    configurationStore.reset(
      ProviderConfiguration(
        endpoint: Uri.parse('https://horizon-testnet.stellar.org'),
        apiKey: '',
        environment: ProviderEnvironment.test,
        version: 1,
        activationFundingUnits: 21000000,
        initialRewardsUnits: 10000000,
      ),
    );
    distributorAuthorityStore.clear();
    authenticator.reset();
    transport.reset();
  }

  void failNext(WalletSdkFailureCode code) {
    transport.pendingFailure = code;
  }

  void advanceTime(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }

  DateTime nowUtc() => _currentTime;

  WalletSdk createWalletSdk() {
    final horizonTransport = HorizonHttpClient(client: transport);
    final distributorVerifier = HorizonDistributorAccountVerifier(
      transport: horizonTransport,
    );
    final distributorAuthorityService = DistributorAuthorityService(
      store: distributorAuthorityStore,
      verifier: distributorVerifier,
    );

    return DefaultWalletSdk(
      now: () => clock.nowUtc(),
      clock: clock,
      random: seed == null ? Random.secure() : Random(seed.hashCode),
      keyGenerator: WalletKeyGenerator(
        random: seed == null ? Random.secure() : Random(seed.hashCode),
      ),
      credentialStore: credentials,
      activationStore: activationStore,
      activationInspectionStore: inspectionStore,
      configurationHandshakeStore: handshakeStore,
      configurationStore: configurationStore,
      activeRewardsStore: activeRewardsStore,
      rewardsSendStore: sendStore,
      activationSubmissionStore: submissionStore,
      transferAuthenticator: authenticator,
      horizonHttpClient: horizonTransport,
      distributorAuthorityService: distributorAuthorityService,
      configurationPolicy: const ConfigurationPolicy(
        allowPublicTestnetHorizon: true,
      ),
      recoveryService: RewardsRecoveryService(
        credentials,
        activeRewardsStore,
        sendStore,
        iterations: 1000,
      ),
    );
  }
}
