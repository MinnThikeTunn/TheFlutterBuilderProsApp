import 'dart:async';

import 'package:rewards_sdk/rewards_sdk.dart';
import 'package:rewards_sdk/src/authority/distributor_authority_service.dart';
import 'package:rewards_sdk/src/authorization/transfer_authorization_service.dart';
import 'package:rewards_sdk/src/configuration/provider_configuration.dart';
import 'package:rewards_sdk/src/storage/activation_inspection_store.dart';
import 'package:rewards_sdk/src/storage/activation_store.dart';
import 'package:rewards_sdk/src/storage/activation_submission_store.dart';
import 'package:rewards_sdk/src/storage/active_rewards_store.dart';
import 'package:rewards_sdk/src/storage/configuration_handshake_store.dart';
import 'package:rewards_sdk/src/storage/configuration_store.dart';
import 'package:rewards_sdk/src/storage/credential_store.dart';
import 'package:rewards_sdk/src/storage/rewards_send_store.dart';

final class SandboxCredentials implements CredentialStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<bool> contains(String key) async => _values.containsKey(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  void clear() {
    _values.clear();
  }
}

final class SandboxActivationStore implements ActivationStore {
  PendingActivationRecord? _record;

  @override
  Future<PendingActivationRecord?> read() async => _record;

  @override
  Future<void> write(PendingActivationRecord record) async {
    _record = record;
  }

  @override
  Future<void> clear() async {
    _record = null;
  }
}

final class SandboxInspectionStore implements ActivationInspectionStore {
  String? _pendingRequest;
  String? _pendingResponse;
  final Set<String> _consumedRequestIds = <String>{};

  @override
  Future<String?> readPendingRequest() async => _pendingRequest;

  @override
  Future<void> savePendingRequest(String qrValue) async {
    _pendingRequest = qrValue;
  }

  @override
  Future<void> clearPendingRequest() async {
    _pendingRequest = null;
  }

  @override
  Future<void> savePendingResponse(String qrValue) async {
    _pendingResponse = qrValue;
  }

  @override
  Future<String?> readPendingResponse() async => _pendingResponse;

  @override
  Future<bool> isConsumed(String requestId) async =>
      _consumedRequestIds.contains(requestId);

  @override
  Future<void> markConsumed(String requestId) async {
    _consumedRequestIds.add(requestId);
  }

  void clear() {
    _pendingRequest = null;
    _pendingResponse = null;
    _consumedRequestIds.clear();
  }
}

final class SandboxHandshakeStore implements ConfigurationHandshakeStore {
  String? _request;
  String? _update;
  String? _reviewedUpdateId;
  final Set<String> _consumedUpdateIds = <String>{};

  @override
  Future<void> saveRequest(String value) async {
    _request = value;
  }

  @override
  Future<String?> readRequest() async => _request;

  @override
  Future<void> saveUpdate(String value, String updateId) async {
    _update = value;
    _reviewedUpdateId = updateId;
  }

  @override
  Future<String?> readUpdate() async => _update;

  @override
  Future<String?> readReviewedUpdateId() async => _reviewedUpdateId;

  @override
  Future<bool> isConsumed(String updateId) async =>
      _consumedUpdateIds.contains(updateId);

  @override
  Future<void> markConsumed(String updateId) async {
    _consumedUpdateIds.add(updateId);
  }

  void clear() {
    _request = null;
    _update = null;
    _reviewedUpdateId = null;
    _consumedUpdateIds.clear();
  }
}

final class SandboxActiveRewardsStore implements ActiveRewardsStore {
  ActiveRewardsRecord? _record;

  @override
  Future<ActiveRewardsRecord?> read() async => _record;

  @override
  Future<void> write(ActiveRewardsRecord record) async {
    _record = record;
  }

  void clear() {
    _record = null;
  }
}

final class SandboxSendStore implements RewardsSendStore {
  RewardsSendRecord? _record;

  @override
  Future<RewardsSendRecord?> read() async => _record;

  @override
  Future<void> write(RewardsSendRecord record) async {
    _record = record;
  }

  void clear() {
    _record = null;
  }
}

final class SandboxSubmissionStore implements ActivationSubmissionStore {
  ActivationSubmissionRecord? _record;

  @override
  Future<ActivationSubmissionRecord?> read() async => _record;

  @override
  Future<void> write(ActivationSubmissionRecord record) async {
    _record = record;
  }

  @override
  Future<void> clear() async {
    _record = null;
  }
}

final class SandboxConfigurationStore implements ConfigurationStore {
  SandboxConfigurationStore({ProviderConfiguration? initial})
    : _active = initial;

  ProviderConfiguration? _active;
  ProviderConfiguration? _pending;

  @override
  Future<ProviderConfiguration?> readActive() async => _active;

  @override
  Future<ProviderConfiguration?> readPending() async => _pending;

  @override
  Future<void> savePending(ProviderConfiguration configuration) async {
    _pending = configuration;
  }

  @override
  Future<ProviderConfigurationStatus> readStatus() async => _active == null
      ? const ProviderConfigurationStatus.notConfigured()
      : ProviderConfigurationStatus(
          state: ProviderConfigurationState.ready,
          environment: _active!.environment,
          version: _active!.version,
          endpointHost: _active!.endpoint.host,
        );

  @override
  Future<void> promotePending(DateTime checkedAt) async {
    _active = _pending;
    _pending = null;
  }

  @override
  Future<void> discardPending() async {
    _pending = null;
  }

  void reset(ProviderConfiguration? initial) {
    _active = initial;
    _pending = null;
  }
}

final class SandboxDistributorAuthorityStore
    implements DistributorAuthorityStore {
  SandboxDistributorAuthorityStore({String? initialSecret})
    : _secret = initialSecret;

  String? _secret;

  @override
  Future<String?> readSecret() async => _secret;

  @override
  Future<void> writeSecret(String secret) async {
    _secret = secret;
  }

  @override
  Future<void> clear() async {
    _secret = null;
  }
}

final class SandboxAuthenticator implements TransferAuthenticator {
  bool shouldSucceed = true;
  int authCalls = 0;

  @override
  Future<bool> authenticate(String reason) async {
    authCalls++;
    return shouldSucceed;
  }

  @override
  Future<void> cancel() async {}

  void reset() {
    shouldSucceed = true;
    authCalls = 0;
  }
}
