#!/usr/bin/env bash
# Outer loop across sessions for OpenCode
set -u
cd "$(dirname "$0")/.." || exit 1
MODULE="${1:-petty_cash}"
MAX=8
for i in $(seq 1 "$MAX"); do
  echo "=== Round $i/$MAX ==="
  if scripts/run_tests.sh "$MODULE" > last_run.txt 2>&1; then
    echo "PASSED in round $i"; exit 0
  fi
  timeout 20m opencode run "Read AGENTS.md, specs/$MODULE.md, PROGRESS.md, \
and last_run.txt. Fix the cause of the failure with a small change. \
Update PROGRESS.md. Do not change tests/."
done
echo "NOT PASSED after $MAX rounds. Check PROGRESS.md and last_run.txt"
exit 1
