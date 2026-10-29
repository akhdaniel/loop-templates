#!/usr/bin/env bash
# PreToolUse: blokir perintah berbahaya. Exit 2 = blokir, stderr dibaca Claude.
cmd=$(jq -r '.tool_input.command // ""')
if echo "$cmd" | grep -Eqi 'rm -rf|git push|drop database|dropdb|--force|db_prod'; then
  echo "DIBLOKIR: perintah berbahaya ($cmd). Pakai scripts/run_tests.sh saja." >&2
  exit 2
fi
exit 0
