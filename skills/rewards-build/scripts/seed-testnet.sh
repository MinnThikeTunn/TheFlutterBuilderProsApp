#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=== Stellar Testnet Seeding Automation ==="
echo "Repository root: $REPO_ROOT"

cd "$REPO_ROOT/packages/rewards_sdk"
dart run tool/seed_testnet.dart

SECRETS_PATH="$REPO_ROOT/.secrets/testnet-authority.json"
if [ -f "$SECRETS_PATH" ]; then
  echo -e "\n[SUCCESS] Authority secrets saved to: $SECRETS_PATH"
else
  echo "Warning: Secrets file was not found at: $SECRETS_PATH"
fi
