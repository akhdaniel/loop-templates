#!/usr/bin/env bash
# PreToolUse: block dangerous commands. Exit 2 = block, stderr is read by Claude.
cmd=$(jq -r '.tool_input.command // ""')
if echo "$cmd" | grep -Eqi 'rm -rf|git push|--force|drop (database|table)|dropdb|fly deploy|railway up|gcloud .*deploy|docker push|alembic (upgrade|downgrade)|lock_tests|export_openapi'; then
  echo "BLOCKED: dangerous command ($cmd). Use scripts/run_tests.sh instead." >&2
  exit 2
fi
if echo "$cmd" | grep -Eqi '(pip3? install|uv (add|pip install)|poetry add) +[a-z]'; then
  echo "BLOCKED: adding packages needs a human. Write it down in PROGRESS.md and stop." >&2
  exit 2
fi
exit 0
