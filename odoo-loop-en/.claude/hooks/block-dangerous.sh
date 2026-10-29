#!/usr/bin/env bash
# PreToolUse: block dangerous commands. Exit 2 = block, stderr is read by Claude.
cmd=$(jq -r '.tool_input.command // ""')
if echo "$cmd" | grep -Eqi 'rm -rf|git push|drop database|dropdb|--force|db_prod'; then
  echo "BLOCKED: dangerous command ($cmd). Use scripts/run_tests.sh instead." >&2
  exit 2
fi
exit 0
