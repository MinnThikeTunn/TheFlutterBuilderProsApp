import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rewards_sdk/rewards_sdk.dart';
import 'package:rewards_sdk/src/protocol/stellar_activation_protocol.dart';
import 'package:rewards_sdk/src/time/wallet_clock.dart';

final class SandboxAccountState {
  SandboxAccountState({
    required this.accountId,
    this.sequence = 100,
    this.nativeBalance = 100.0,
    Map<String, double>? nonNativeBalances,
  }) : nonNativeBalances = nonNativeBalances ?? <String, double>{};

  final String accountId;
  int sequence;
  double nativeBalance;
  final Map<String, double> nonNativeBalances;
}

final class SandboxPaymentRecord {
  SandboxPaymentRecord({
    required this.id,
    required this.from,
    required this.to,
    required this.assetCode,
    required this.assetIssuer,
    required this.amount,
    required this.createdAt,
    required this.transactionHash,
  });

  final String id;
  final String from;
  final String to;
  final String assetCode;
  final String assetIssuer;
  final String amount;
  final DateTime createdAt;
  final String transactionHash;

  Map<String, Object> toJson() => <String, Object>{
    'id': id,
    'paging_token': id,
    'type': 'payment',
    'transaction_successful': true,
    'asset_type': assetCode.length <= 4
        ? 'credit_alphanum4'
        : 'credit_alphanum12',
    'asset_code': assetCode,
    'asset_issuer': assetIssuer,
    'from': from,
    'to': to,
    'amount': amount,
    'created_at': createdAt.toIso8601String(),
    'transaction_hash': transactionHash,
  };
}

final class SandboxTransactionRecord {
  SandboxTransactionRecord({
    required this.hash,
    required this.envelopeXdr,
    required this.sourceAccount,
    required this.sequence,
    required this.ledger,
  });

  final String hash;
  final String envelopeXdr;
  final String sourceAccount;
  final String sequence;
  final int ledger;
}

final class SandboxTransport extends http.BaseClient {
  SandboxTransport({
    required this.clock,
    required this.distributorAccountId,
    required this.issuerAccountId,
    this.assetCode = 'REWARD',
  }) {
    _initDefaultState();
  }

  final WalletClock clock;
  final String distributorAccountId;
  final String issuerAccountId;
  final String assetCode;

  final Map<String, SandboxAccountState> _accounts =
      <String, SandboxAccountState>{};
  final Map<String, SandboxTransactionRecord> _transactions =
      <String, SandboxTransactionRecord>{};
  final List<SandboxPaymentRecord> _payments = <SandboxPaymentRecord>[];
  final StellarActivationProtocol _protocol = StellarActivationProtocol();

  WalletSdkFailureCode? pendingFailure;
  int currentLedger = 100;
  int _paymentCounter = 1;

  void _initDefaultState() {
    _accounts.clear();
    _transactions.clear();
    _payments.clear();

    // Configure distributor with native balance and initial Rewards inventory
    _accounts[distributorAccountId] = SandboxAccountState(
      accountId: distributorAccountId,
      sequence: 100,
      nativeBalance: 1000.0,
      nonNativeBalances: <String, double>{
        '$assetCode:$issuerAccountId': 1000000.0,
      },
    );

    // Configure issuer
    _accounts[issuerAccountId] = SandboxAccountState(
      accountId: issuerAccountId,
      sequence: 100,
      nativeBalance: 10000.0,
    );
  }

  void reset() {
    _initDefaultState();
    pendingFailure = null;
    currentLedger = 100;
    _paymentCounter = 1;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (pendingFailure != null) {
      final code = pendingFailure!;
      pendingFailure = null;
      if (code == WalletSdkFailureCode.providerServiceUnavailable ||
          code == WalletSdkFailureCode.providerTimeout) {
        return _streamResponse(
          request,
          statusCode: 504,
          body: jsonEncode(<String, Object>{'title': 'Gateway Timeout'}),
        );
      }
      return _streamResponse(
        request,
        statusCode: 500,
        body: jsonEncode(<String, Object>{
          'title': 'Internal Server Error',
          'code': code.name,
        }),
      );
    }

    final segments = request.url.pathSegments;

    // 1. Root health check
    if (segments.isEmpty || (segments.length == 1 && segments[0].isEmpty)) {
      return _streamResponse(
        request,
        body: jsonEncode(<String, Object>{
          'horizon_version': '2.30.0',
          'core_version': '20.1.0',
          'network_passphrase': StellarActivationProtocol.testNetworkPassphrase,
        }),
      );
    }

    final first = segments.first;

    // 2. Fee stats
    if (first == 'fee_stats') {
      return _streamResponse(
        request,
        body: jsonEncode(<String, Object>{
          'last_ledger_base_fee': '100',
          'fee_charged': <String, String>{
            'p95': '100',
            'min': '100',
            'mode': '100',
          },
        }),
      );
    }

    // 3. Ledgers
    if (first == 'ledgers') {
      if (segments.length > 1) {
        final seq = int.tryParse(segments[1]) ?? currentLedger;
        return _streamResponse(
          request,
          body: jsonEncode(<String, Object>{
            'sequence': seq,
            'base_reserve_in_stroops': 5000000,
            'base_fee_in_stroops': 100,
            'hash': 'a' * 64,
            'closed_at': clock.nowUtc().toIso8601String(),
          }),
        );
      }
      return _streamResponse(
        request,
        body: jsonEncode(<String, Object>{
          '_embedded': <String, Object>{
            'records': <Object>[
              <String, Object>{
                'sequence': currentLedger,
                'base_reserve_in_stroops': 5000000,
                'base_fee_in_stroops': 100,
                'hash': 'a' * 64,
                'closed_at': clock.nowUtc().toIso8601String(),
              },
            ],
          },
        }),
      );
    }

    // 4. Accounts
    if (first == 'accounts' && segments.length >= 2) {
      final accountId = segments[1];

      // Payments for account: /accounts/{accountId}/payments
      if (segments.length >= 3 && segments[2] == 'payments') {
        var matching = _payments
            .where((p) => p.from == accountId || p.to == accountId)
            .toList();
        final order = request.url.queryParameters['order'];
        if (order == 'desc') {
          matching = matching.reversed.toList();
        }
        final limitParam = request.url.queryParameters['limit'];
        if (limitParam != null) {
          final limit = int.tryParse(limitParam);
          if (limit != null && limit < matching.length) {
            matching = matching.sublist(0, limit);
          }
        }
        final history = matching.map((p) => p.toJson()).toList();
        return _streamResponse(
          request,
          body: jsonEncode(<String, Object>{
            '_embedded': <String, Object>{'records': history},
          }),
        );
      }

      // Account detail: /accounts/{accountId}
      final account = _accounts[accountId];
      if (account == null) {
        return _streamResponse(
          request,
          statusCode: 404,
          body: jsonEncode(<String, Object>{
            'status': 404,
            'title': 'Resource Missing',
          }),
        );
      }

      final balances = <Map<String, Object>>[
        <String, Object>{
          'asset_type': 'native',
          'balance': account.nativeBalance.toStringAsFixed(7),
          'selling_liabilities': '0',
          'buying_liabilities': '0',
        },
      ];

      for (final entry in account.nonNativeBalances.entries) {
        final parts = entry.key.split(':');
        final code = parts[0];
        final issuer = parts.length > 1 ? parts[1] : issuerAccountId;
        balances.add(<String, Object>{
          'asset_type': code.length <= 4
              ? 'credit_alphanum4'
              : 'credit_alphanum12',
          'asset_code': code,
          'asset_issuer': issuer,
          'balance': entry.value.toStringAsFixed(7),
          'limit': '1000000000.0000000',
          'selling_liabilities': '0',
          'buying_liabilities': '0',
          'is_authorized': true,
        });
      }

      return _streamResponse(
        request,
        body: jsonEncode(<String, Object>{
          'account_id': account.accountId,
          'sequence': account.sequence.toString(),
          'subentry_count': account.nonNativeBalances.length,
          'num_sponsoring': 0,
          'num_sponsored': 0,
          'thresholds': <String, int>{'med_threshold': 1},
          'data': <String, Object>{},
          'signers': <Object>[
            <String, Object>{
              'key': account.accountId,
              'type': 'ed25519_public_key',
              'weight': 1,
            },
          ],
          'balances': balances,
        }),
      );
    }

    // 5. Transactions
    if (first == 'transactions') {
      if (request.method == 'POST') {
        String? envelopeXdr;
        if (request is http.Request) {
          envelopeXdr = request.bodyFields['tx'] ?? request.body;
        }

        if (envelopeXdr == null || envelopeXdr.isEmpty) {
          return _streamResponse(
            request,
            statusCode: 400,
            body: jsonEncode(<String, Object>{'title': 'Missing tx body'}),
          );
        }

        try {
          final envelope = _protocol.decodeEnvelopeBase64(envelopeXdr);
          final hashBytes = await _protocol.transactionHash(
            envelope,
            StellarActivationProtocol.testNetworkPassphrase,
          );
          final hash = hashBytes
              .map((int b) => b.toRadixString(16).padLeft(2, '0'))
              .join();

          // Apply operations to simulated ledger
          for (final op in envelope.operations) {
            if (op is StellarCreateAccountOperation) {
              final starting = op.startingBalance / 10000000.0;
              _accounts[op.destination] = SandboxAccountState(
                accountId: op.destination,
                sequence: 1,
                nativeBalance: starting,
              );
            } else if (op is StellarChangeTrustOperation) {
              final line = op.asset;
              if (!line.isNative) {
                final targetAccount =
                    op.sourceAccount ?? envelope.sourceAccount;
                final target = _ensureAccount(targetAccount);
                target.nonNativeBalances['${line.code}:${line.issuer}'] = 0.0;
              }
            } else if (op is StellarPaymentOperation) {
              final line = op.asset;
              final amountDouble = op.amount / 10000000.0;
              final source = op.sourceAccount ?? envelope.sourceAccount;
              final dest = op.destination;

              if (line.isNative) {
                _accounts[source]?.nativeBalance -= amountDouble;
                _ensureAccount(dest).nativeBalance += amountDouble;
              } else {
                final key = '${line.code}:${line.issuer}';
                final srcAcct = _accounts[source];
                if (srcAcct != null) {
                  final cur = srcAcct.nonNativeBalances[key] ?? 0.0;
                  srcAcct.nonNativeBalances[key] = (cur - amountDouble).clamp(
                    0.0,
                    double.infinity,
                  );
                }
                final destAcct = _ensureAccount(dest);
                final curDest = destAcct.nonNativeBalances[key] ?? 0.0;
                destAcct.nonNativeBalances[key] = curDest + amountDouble;

                _payments.add(
                  SandboxPaymentRecord(
                    id: (_paymentCounter++).toString(),
                    from: source,
                    to: dest,
                    assetCode: line.code ?? assetCode,
                    assetIssuer: line.issuer ?? issuerAccountId,
                    amount: amountDouble.toStringAsFixed(7),
                    createdAt: clock.nowUtc(),
                    transactionHash: hash,
                  ),
                );
              }
            }
          }

          // Advance source sequence
          final src = _accounts[envelope.sourceAccount];
          if (src != null) {
            src.sequence++;
          }

          _transactions[hash] = SandboxTransactionRecord(
            hash: hash,
            envelopeXdr: envelopeXdr,
            sourceAccount: envelope.sourceAccount,
            sequence: envelope.sequenceNumber.toString(),
            ledger: currentLedger++,
          );

          return _streamResponse(
            request,
            body: jsonEncode(<String, Object>{
              'hash': hash,
              'successful': true,
              'ledger': currentLedger,
            }),
          );
        } catch (_) {
          return _streamResponse(
            request,
            statusCode: 400,
            body: jsonEncode(<String, Object>{
              'title': 'Transaction Malformed',
            }),
          );
        }
      }

      // GET /transactions/{hash}
      if (segments.length >= 2) {
        final hash = segments[1];
        final record = _transactions[hash];
        if (record == null) {
          return _streamResponse(
            request,
            statusCode: 404,
            body: jsonEncode(<String, Object>{
              'status': 404,
              'title': 'Transaction Not Found',
            }),
          );
        }

        return _streamResponse(
          request,
          body: jsonEncode(<String, Object>{
            'hash': record.hash,
            'successful': true,
            'ledger': record.ledger,
            'envelope_xdr': record.envelopeXdr,
            'source_account': record.sourceAccount,
            'source_account_sequence': record.sequence,
          }),
        );
      }
    }

    return _streamResponse(
      request,
      statusCode: 404,
      body: jsonEncode(<String, Object>{
        'status': 404,
        'title': 'Endpoint Not Found',
      }),
    );
  }

  SandboxAccountState _ensureAccount(String id) {
    return _accounts.putIfAbsent(
      id,
      () => SandboxAccountState(accountId: id, sequence: 1, nativeBalance: 5.0),
    );
  }

  http.StreamedResponse _streamResponse(
    http.BaseRequest request, {
    int statusCode = 200,
    required String body,
  }) {
    final bytes = utf8.encode(body);
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      statusCode,
      contentLength: bytes.length,
      headers: <String, String>{
        'content-type': 'application/json; charset=utf-8',
        'latest-ledger': currentLedger.toString(),
      },
      request: request,
    );
  }
}
