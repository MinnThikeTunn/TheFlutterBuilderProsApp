import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:rewards_sdk/src/crypto/wallet_key_generator.dart';
import 'package:rewards_sdk/src/protocol/stellar_activation_protocol.dart';

const String horizonUrl = 'https://horizon-testnet.stellar.org';
const String friendbotUrl = 'https://friendbot.stellar.org';
const String networkPassphrase =
    StellarActivationProtocol.testNetworkPassphrase;
const String assetCode = 'REWARD';
const int initialDistributionUnits = 100000; // 100,000 units
const int stroopsPerUnit = 10000000;

Future<void> main(List<String> args) async {
  stdout.writeln('=== Stellar Testnet Rewards Seeding Tool ===');

  final client = http.Client();
  final keyGenerator = WalletKeyGenerator();
  final protocol = StellarActivationProtocol();

  try {
    // 1. Generate Keypairs
    stdout.writeln('\n1. Generating Issuer and Distributor keypairs...');
    final issuer = await keyGenerator.generate();
    final distributor = await keyGenerator.generate();

    stdout.writeln('   Issuer:      ${issuer.accountId}');
    stdout.writeln('   Distributor: ${distributor.accountId}');

    // 2. Fund via Friendbot
    stdout.writeln('\n2. Funding accounts via Friendbot...');
    await _fundViaFriendbot(client, issuer.accountId, 'Issuer');
    await _fundViaFriendbot(client, distributor.accountId, 'Distributor');

    // 3. Establish REWARD Trustline on Distributor
    stdout.writeln('\n3. Establishing REWARD trustline on Distributor...');
    final distSequence = await _getSequence(client, distributor.accountId);
    final trustAsset = StellarAsset.credit(
      code: assetCode,
      issuer: issuer.accountId,
    );
    final trustEnvelope = StellarActivationEnvelope(
      sourceAccount: distributor.accountId,
      fee: 10000,
      sequenceNumber: distSequence + 1,
      minTime: 0,
      maxTime: 0,
      operations: <StellarActivationOperation>[
        StellarChangeTrustOperation(
          sourceAccount: distributor.accountId,
          asset: trustAsset,
          limit: 0x7fffffffffffffff,
        ),
      ],
    );

    final signedTrust = await protocol.sign(
      trustEnvelope,
      secretSeed: distributor.secretSeed,
      networkPassphrase: networkPassphrase,
    );
    final trustTxHash = await _submitTransaction(
      client,
      protocol.encodeEnvelopeBase64(signedTrust),
    );
    stdout.writeln('   Trustline established! Tx hash: $trustTxHash');

    // 4. Distribute 100,000 REWARD tokens from Issuer to Distributor
    stdout.writeln(
      '\n4. Minting and sending 100,000 $assetCode to Distributor...',
    );
    final issuerSequence = await _getSequence(client, issuer.accountId);
    final paymentEnvelope = StellarActivationEnvelope(
      sourceAccount: issuer.accountId,
      fee: 10000,
      sequenceNumber: issuerSequence + 1,
      minTime: 0,
      maxTime: 0,
      operations: <StellarActivationOperation>[
        StellarPaymentOperation(
          destination: distributor.accountId,
          asset: trustAsset,
          amount: initialDistributionUnits * stroopsPerUnit,
        ),
      ],
    );

    final signedPayment = await protocol.sign(
      paymentEnvelope,
      secretSeed: issuer.secretSeed,
      networkPassphrase: networkPassphrase,
    );
    final paymentTxHash = await _submitTransaction(
      client,
      protocol.encodeEnvelopeBase64(signedPayment),
    );
    stdout.writeln('   Payment submitted! Tx hash: $paymentTxHash');

    // 5. Build Output and Save Secrets
    stdout.writeln('\n5. Saving authority secrets and output configuration...');
    final secrets = <String, Object>{
      'issuerAccountId': issuer.accountId,
      'issuerSecretSeed': issuer.secretSeed,
      'distributorAccountId': distributor.accountId,
      'distributorSecretSeed': distributor.secretSeed,
      'assetCode': assetCode,
      'network': 'testnet',
      'horizonUrl': horizonUrl,
      'configuration': <String, Object>{
        'endpoint': horizonUrl,
        'apiKey': '',
        'environment': 'test',
        'version': 1,
        'activationFunding': '2.1',
        'initialRewards': '1',
      },
    };

    final secretsDir = Directory('.secrets');
    if (!secretsDir.existsSync()) {
      secretsDir.createSync(recursive: true);
    }
    final secretsFile = File('.secrets/testnet-authority.json');
    secretsFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(secrets),
    );
    stdout.writeln('   Saved to ${secretsFile.path}');

    stdout.writeln('\n=== Testnet Seeding Completed Successfully! ===');
    stdout.writeln('App Master Distributor Secret: ${distributor.secretSeed}');
    stdout.writeln('App Master Provider Endpoint:  $horizonUrl');
  } finally {
    client.close();
  }
}

Future<void> _fundViaFriendbot(
  http.Client client,
  String accountId,
  String label,
) async {
  final uri = Uri.parse('$friendbotUrl/?addr=$accountId');
  int delayMs = 1000;

  for (int attempt = 1; attempt <= 5; attempt++) {
    try {
      final response = await client.get(uri);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        stdout.writeln('   $label funded successfully.');
        return;
      }
      if (response.statusCode == 429) {
        stdout.writeln(
          '   Friendbot rate limit (429) on attempt $attempt, backing off for ${delayMs}ms...',
        );
        await Future<void>.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2;
        continue;
      }
      throw HttpException(
        'Friendbot failed with status ${response.statusCode}: ${response.body}',
      );
    } on SocketException catch (e) {
      stdout.writeln(
        '   Network glitch on attempt $attempt ($e), retrying in ${delayMs}ms...',
      );
      await Future<void>.delayed(Duration(milliseconds: delayMs));
      delayMs *= 2;
    }
  }
  throw StateError('Could not fund $label via Friendbot after 5 attempts.');
}

Future<int> _getSequence(http.Client client, String accountId) async {
  final uri = Uri.parse('$horizonUrl/accounts/$accountId');
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    throw HttpException(
      'Failed to load account $accountId: ${response.statusCode}',
    );
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return int.parse(json['sequence'] as String);
}

Future<String> _submitTransaction(
  http.Client client,
  String envelopeXdr,
) async {
  final uri = Uri.parse('$horizonUrl/transactions');
  final response = await client.post(
    uri,
    headers: <String, String>{
      'content-type': 'application/x-www-form-urlencoded',
      'accept': 'application/json',
    },
    body: <String, String>{'tx': envelopeXdr},
  );

  if (response.statusCode != 200) {
    throw HttpException(
      'Failed to submit transaction (${response.statusCode}): ${response.body}',
    );
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return json['hash'] as String;
}
