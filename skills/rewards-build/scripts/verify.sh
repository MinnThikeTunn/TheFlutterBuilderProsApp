#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ACT="${1:-1}"

echo "=========================================================="
echo "   REWARDS BUILD VERIFICATION GATE (Act $ACT)            "
echo "=========================================================="
echo "Root: $REPO_ROOT"
echo ""

FAILURES=0

run_step() {
  local name="$1"
  shift
  echo -n "[CHECK] $name..."
  if "$@"; then
    echo " [PASS]"
  else
    echo " [FAIL]"
    FAILURES=$((FAILURES + 1))
  fi
}

update_rewards_state() {
  local act_num="$1"
  mkdir -p "$REPO_ROOT/.rewards"
  cat <<EOF > "$REPO_ROOT/.rewards/state.json"
{
  "act": $act_num,
  "flutter": "$(flutter --version | head -n 1)",
  "platform": "$(uname -s)",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
}

if [ "$ACT" -eq 0 ]; then
  run_step "Flutter toolchain availability" flutter --version
  run_step "Dart SDK availability" dart --version
  run_step "Working branch isolation" test "$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)" = "feature/rewards-build"
  if [ "$FAILURES" -eq 0 ]; then
    update_rewards_state 0
  fi
elif [ "$ACT" -eq 1 ]; then
  run_step "Dart format validation (packages/rewards_sdk)" dart format --output=none --set-exit-if-changed "$REPO_ROOT/packages/rewards_sdk"
  run_step "Dart format validation (templates/rewards_harness)" dart format --output=none --set-exit-if-changed "$REPO_ROOT/templates/rewards_harness"
  run_step "Static analysis (packages/rewards_sdk)" bash -c "cd '$REPO_ROOT/packages/rewards_sdk' && flutter analyze"
  run_step "Static analysis (templates/rewards_harness)" bash -c "cd '$REPO_ROOT/templates/rewards_harness' && flutter analyze"
  run_step "Sandbox 6-flow headless test (<5s, 0 network calls)" bash -c "cd '$REPO_ROOT/packages/rewards_sdk' && flutter test test/sandbox_test.dart"
  run_step "rewards_sdk unit test suite (all 130 tests)" bash -c "cd '$REPO_ROOT/packages/rewards_sdk' && flutter test"
  run_step "templates/rewards_harness smoke test" bash -c "cd '$REPO_ROOT/templates/rewards_harness' && flutter test test/smoke_test.dart"
  run_step "Host app import boundary & regression checks" bash -c "cd '$REPO_ROOT' && flutter test test/wallet_sdk_import_boundary_test.dart test/qr_input_adapter_test.dart"
  if [ "$FAILURES" -eq 0 ]; then
    update_rewards_state 1
  fi
elif [ "$ACT" -eq 2 ]; then
  run_step "Testnet authority secrets presence" test -f "$REPO_ROOT/.secrets/testnet-authority.json"
  run_step "Stellar Testnet Horizon connectivity" curl -sf "https://horizon-testnet.stellar.org"
  if [ "$FAILURES" -eq 0 ]; then
    update_rewards_state 2
  fi
elif [ "$ACT" -eq 3 ]; then
  run_step "Assert zero sandbox.dart imports in host application" bash -c "! grep -rn 'rewards_sdk/sandbox.dart' '$REPO_ROOT/lib'"
  if [ "$FAILURES" -eq 0 ]; then
    update_rewards_state 3
  fi
else
  echo "Unknown Act: $ACT. Supported: 0, 1, 2, 3"
  exit 1
fi

echo ""
echo "=========================================================="
if [ "$FAILURES" -eq 0 ]; then
  echo "   ACT $ACT VERIFICATION GATE PASSED! (0 errors)"
  echo "=========================================================="
  exit 0
else
  echo "   VERIFICATION FAILED: $FAILURES check(s) failed."
  echo "=========================================================="
  exit 1
fi
