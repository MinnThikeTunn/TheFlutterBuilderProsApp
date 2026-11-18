import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ConfigurationHandshakeStore {
  factory ConfigurationHandshakeStore({FlutterSecureStorage? secureStorage}) =
      ProtectedConfigurationHandshakeStore;

  Future<void> saveRequest(String value);
  Future<String?> readRequest();
  Future<void> saveUpdate(String value, String updateId);
  Future<String?> readUpdate();
  Future<String?> readReviewedUpdateId();
  Future<bool> isConsumed(String updateId);
  Future<void> markConsumed(String updateId);
}

final class ProtectedConfigurationHandshakeStore
    implements ConfigurationHandshakeStore {
  ProtectedConfigurationHandshakeStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _requestKey = 'rewards.configuration.request.v1';
  static const String _updateKey = 'rewards.configuration.update.v1';
  static const String _reviewedUpdateIdKey =
      'rewards.configuration.reviewed_update_id.v1';
  static const String _consumedKey = 'rewards.configuration.consumed.v1';
  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> saveRequest(String value) =>
      _secureStorage.write(key: _requestKey, value: value);

  @override
  Future<String?> readRequest() => _secureStorage.read(key: _requestKey);

  @override
  Future<void> saveUpdate(String value, String updateId) async {
    await _secureStorage.write(key: _updateKey, value: value);
    await _secureStorage.write(key: _reviewedUpdateIdKey, value: updateId);
  }

  @override
  Future<String?> readUpdate() => _secureStorage.read(key: _updateKey);

  @override
  Future<String?> readReviewedUpdateId() =>
      _secureStorage.read(key: _reviewedUpdateIdKey);

  @override
  Future<bool> isConsumed(String updateId) async =>
      (await _consumed()).contains(updateId);

  @override
  Future<void> markConsumed(String updateId) async {
    final List<String> values = await _consumed();
    if (!values.contains(updateId)) values.add(updateId);
    if (values.length > 100) values.removeAt(0);
    await (await SharedPreferences.getInstance()).setString(
      _consumedKey,
      jsonEncode(values),
    );
  }

  Future<List<String>> _consumed() async {
    final String? raw = (await SharedPreferences.getInstance()).getString(
      _consumedKey,
    );
    return raw == null
        ? <String>[]
        : (jsonDecode(raw) as List<dynamic>).cast<String>();
  }
}
