#!/usr/bin/env bash
# Outer loop across sessions for OpenCode
set -u
cd "$(dirname "$0")/.." || exit 1
FEATURE="${1:?usage: scripts/run_loop_opencode.sh <feature>}"
MAX=8
for i in $(seq 1 "$MAX"); do
  echo "=== Round $i/$MAX ==="
  if scripts/run_tests.sh "$FEATURE" > last_run.txt 2>&1; then
    echo "PASSED in round $i"; exit 0
  fi
  timeout 20m opencode run "Read AGENTS.md, specs/$FEATURE.md, PROGRESS.md, \
and last_run.txt. Fix the cause of the failure with a small change. \
Update PROGRESS.md. Do not change __tests__/, e2e/, or any locked config."
done
echo "NOT PASSED after $MAX rounds. Check PROGRESS.md and last_run.txt"
exit 1
