import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

Future<void> main(List<String> args) async {
  stdout.writeln('=== Rewards SDK Packaging & Hash Normalizer ===');

  final packageRoot =
      Directory.current.path.endsWith(
        'packages${Platform.pathSeparator}rewards_sdk',
      )
      ? Directory.current
      : Directory('packages/rewards_sdk');

  if (!packageRoot.existsSync()) {
    stderr.writeln('Error: Could not locate packages/rewards_sdk.');
    exit(1);
  }

  final libDir = Directory('${packageRoot.path}/lib');
  final fileHashes = <String, String>{};
  final sha256 = Sha256();

  final dartFiles =
      libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in dartFiles) {
    final relativePath = file.path
        .substring(packageRoot.path.length + 1)
        .replaceAll(r'\', '/');
    final rawText = file.readAsStringSync();
    // Normalize CRLF to LF for cross-platform deterministic hashing
    final normalized = rawText.replaceAll('\r\n', '\n');
    final digest = await sha256.hash(utf8.encode(normalized));
    final hashHex = digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    fileHashes[relativePath] = hashHex;
  }

  final license = <String, Object>{
    'customer': 'TheBuilderPros',
    'version': '0.1.0',
    'issuedAt': DateTime.now().toUtc().toIso8601String(),
    'fileHashes': fileHashes,
  };

  final licenseFile = File('${packageRoot.path}/license.json');
  licenseFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(license),
  );

  stdout.writeln(
    'Generated license.json with ${fileHashes.length} file hashes:',
  );
  stdout.writeln('  -> ${licenseFile.path}');
  stdout.writeln('\nPackaging completed successfully.');
}
