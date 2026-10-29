#!/usr/bin/env bash
# For HUMANS only: lock ALL tests, the reviewed specs, the published contract, and the config.
# Run after reviewing the drafts (and after scripts/export_openapi.py); agents may not run this.
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1
if command -v sha256sum >/dev/null; then SHA=(sha256sum); else SHA=(shasum -a 256); fi

LOCKED=(pyproject.toml)
[ -f contracts/openapi.json ] && LOCKED+=(contracts/openapi.json)
{
  find tests -type f -name '*.py' -exec "${SHA[@]}" {} +
  find specs -type f -name '*.md' -exec "${SHA[@]}" {} +
  "${SHA[@]}" "${LOCKED[@]}"
} > .tests.lock
echo "Locked $(wc -l < .tests.lock | tr -d ' ') files in .tests.lock"
