#!/usr/bin/env bash
# PreToolUse: block dangerous commands. Exit 2 = block, stderr is read by Claude.
cmd=$(jq -r '.tool_input.command // ""')
if echo "$cmd" | grep -Eqi 'rm -rf|git push|--force|pub publish|shorebird (release|patch)|fastlane|firebase deploy|update-goldens|lock_tests'; then
  echo "BLOCKED: dangerous command ($cmd). Use scripts/run_tests.sh instead." >&2
  exit 2
fi
if echo "$cmd" | grep -Eqi '(flutter|dart) pub (add|upgrade|remove)'; then
  echo "BLOCKED: changing packages needs a human. Write it down in PROGRESS.md and stop." >&2
  exit 2
fi
exit 0
