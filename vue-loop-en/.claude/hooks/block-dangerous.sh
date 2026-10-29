#!/usr/bin/env bash
# PreToolUse: block dangerous commands. Exit 2 = block, stderr is read by Claude.
cmd=$(jq -r '.tool_input.command // ""')
if echo "$cmd" | grep -Eqi 'rm -rf|git push|--force|npm publish|vercel|netlify deploy|firebase deploy|wrangler (deploy|pages)|vitest.* (-u|--update)|lock_tests'; then
  echo "BLOCKED: dangerous command ($cmd). Use scripts/run_tests.sh instead." >&2
  exit 2
fi
if echo "$cmd" | grep -Eqi '(npm (i|install|add)|yarn add|pnpm (add|i|install)|bun (add|i|install)) +[@a-z]'; then
  echo "BLOCKED: adding packages needs a human. Write it down in PROGRESS.md and stop." >&2
  exit 2
fi
exit 0
