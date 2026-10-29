#!/usr/bin/env bash
# For HUMANS only: lock ALL tests (test/, integration_test/) and the test config.
# Run after reviewing the drafts; agents are not allowed to run this.
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1
if command -v sha256sum >/dev/null; then SHA=(sha256sum); else SHA=(shasum -a 256); fi

CONFIG=(pubspec.yaml analysis_options.yaml)
for f in "${CONFIG[@]}"; do
  [ -f "$f" ] || { echo "missing $f (see README quick start)"; exit 1; }
done

{
  find test integration_test -type f ! -name .gitkeep ! -name .DS_Store -exec "${SHA[@]}" {} +
  "${SHA[@]}" "${CONFIG[@]}"
} > .tests.lock
echo "Locked $(wc -l < .tests.lock | tr -d ' ') files in .tests.lock"
