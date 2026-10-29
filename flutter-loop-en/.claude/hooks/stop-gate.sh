#!/usr/bin/env bash
# Stop hook: Claude may only stop once the judge passes (active when LOOP_MODE=1 and FEATURE is set).
[ "${LOOP_MODE:-0}" = "1" ] && [ -n "${FEATURE:-}" ] || exit 0
MAX=8
F=".claude/.stop_count"
n=$(cat "$F" 2>/dev/null || echo 0)

if [ "$n" -ge "$MAX" ]; then
  rm -f "$F"; exit 0              # give up: a human takes over
fi

if out=$(scripts/run_tests.sh "$FEATURE" 2>&1); then
  rm -f "$F"; exit 0              # passed: allowed to stop
fi

echo $((n + 1)) > "$F"
{
  echo "Verification FAILED (attempt $((n + 1))/$MAX). Fix it, do not stop before it passes."
  echo "$out" | tail -n 60
} >&2
exit 2
