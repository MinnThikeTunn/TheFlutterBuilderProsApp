#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=== Rewards SDK Bootstrap ==="
echo "Repository root: $REPO_ROOT"

echo -e "\n1. Verifying Toolchains..."
flutter --version | head -n 1

echo -e "\n2. Verifying Working Branch..."
cd "$REPO_ROOT"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "Current git branch: $CURRENT_BRANCH"

echo -e "\n3. Resolving Dependencies across packages..."
if [ -d "$REPO_ROOT/packages/rewards_sdk" ]; then
  cd "$REPO_ROOT/packages/rewards_sdk"
  flutter pub get
fi

if [ -d "$REPO_ROOT/templates/rewards_harness" ]; then
  cd "$REPO_ROOT/templates/rewards_harness"
  flutter pub get
fi

cd "$REPO_ROOT"
flutter pub get

mkdir -p "$REPO_ROOT/.rewards"
cat <<EOF > "$REPO_ROOT/.rewards/installed.json"
{
  "installedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "packagePath": "packages/rewards_sdk",
  "version": "0.1.0"
}
EOF

echo -e "\n[BOOTSTRAP COMPLETE] All dependencies resolved and toolchains ready."
