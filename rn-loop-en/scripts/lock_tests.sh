#!/usr/bin/env bash
# For HUMANS only: lock the tests of ALL features, the E2E flows, and the test config.
# Run after reviewing the drafts; agents are not allowed to run this.
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1
if command -v sha256sum >/dev/null; then SHA=(sha256sum); else SHA=(shasum -a 256); fi

CONFIG=(package.json jest.config.js tsconfig.json eslint.config.js)
for f in "${CONFIG[@]}"; do
  [ -f "$f" ] || { echo "missing $f (see README quick start)"; exit 1; }
done

{
  find src/features -path '*/__tests__/*' -type f -exec "${SHA[@]}" {} +
  find e2e -type f ! -name .gitkeep -exec "${SHA[@]}" {} +
  "${SHA[@]}" "${CONFIG[@]}"
} > .tests.lock
echo "Locked $(wc -l < .tests.lock | tr -d ' ') files in .tests.lock"
