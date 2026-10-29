#!/usr/bin/env bash
# Judge: exit 0 = passed. Typecheck + lint + Jest (jest-expo + RNTL) for one feature,
# plus optional Maestro E2E flows. Configuration is read from .env.test (see .env.test.example).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
[ -f .env.test ] && . ./.env.test

FEATURE="${1:?usage: scripts/run_tests.sh <feature>}"
DIR="src/features/$FEATURE"
TESTS="$DIR/__tests__"
LOG="test.log"
RESULT=".jest-result.json"
read -ra X <<< "${PKG_EXEC:-npx --no-install}"
if command -v sha256sum >/dev/null; then SHA=(sha256sum); else SHA=(shasum -a 256); fi

# guard: the judge must never run against production
case "${EXPO_PUBLIC_API_URL:-}" in
  *prod*) echo "FAILED: EXPO_PUBLIC_API_URL points to production (${EXPO_PUBLIC_API_URL})"; exit 6 ;;
esac

# 0. tests must exist. 0 tests = a loop that passes by lying
if ! grep -rqE "\b(it|test)\(" "$TESTS" 2>/dev/null; then
  echo "FAILED: no tests in $TESTS yet"; exit 2
fi

# 0b. tests and test config are locked: any change means failure
if [ -f .tests.lock ] && ! "${SHA[@]}" -c .tests.lock --quiet; then
  echo "FAILED: locked files (tests or config) changed since they were locked"; exit 4
fi

# 0c. skipping, focusing, and snapshot tests are forbidden
if grep -rnE "\b(it|test|describe)\.(skip|only|todo)\b|\b(xit|xtest|xdescribe|fit|fdescribe)\(|toMatch(Inline)?Snapshot" "$TESTS"; then
  echo "FAILED: skip/only/todo or snapshot found in $TESTS"; exit 5
fi

# 0d. the feature must have its public entry point
if [ ! -f "$DIR/index.ts" ] && [ ! -f "$DIR/index.tsx" ]; then
  echo "FAILED: $DIR/index.ts is missing (feature not created yet)"; exit 7
fi

# 0e. no escape hatches or test-environment detection in feature code
if grep -rnE "@ts-(ignore|nocheck|expect-error)|eslint-disable|JEST_WORKER_ID|NODE_ENV *[!=]==? *['\"]test" \
    --include='*.ts' --include='*.tsx' --exclude-dir=__tests__ "$DIR" src/app app 2>/dev/null; then
  echo "FAILED: forbidden escape hatch in feature code (see lines above)"; exit 5
fi

# 1. typecheck (only errors in this feature, the routes, or the config count) + lint
TSC_OUT=$("${X[@]}" tsc --noEmit --pretty false 2>&1)
if echo "$TSC_OUT" | grep -E "^($DIR/|src/app/|app/|error )"; then
  echo "FAILED: tsc"; exit 3
fi
"${X[@]}" eslint --max-warnings=0 "$DIR" || { echo "FAILED: eslint"; exit 3; }

# 2. unit + component tests (--ci: never writes snapshots)
rm -f "$RESULT"
COV_ARGS=()
if [ "${COVERAGE_MIN:-0}" -gt 0 ]; then
  rm -rf coverage
  COV_ARGS=(--coverage --coverageReporters=text-summary --coverageReporters=json-summary
    "--collectCoverageFrom=$DIR/**/*.{ts,tsx}" "--collectCoverageFrom=!$DIR/__tests__/**"
    "--coverageThreshold={\"global\":{\"lines\":${COVERAGE_MIN}}}")
fi
"${X[@]}" jest --ci --silent --no-watchman "$TESTS" --json --outputFile="$RESULT" "${COV_ARGS[@]}" > "$LOG" 2>&1
RC=$?

# 3. verdict: exit code AND result content
if [ $RC -ne 0 ] || [ ! -f "$RESULT" ]; then
  echo "=== FAILED (exit $RC). Relevant lines: ==="
  grep -nE -B2 -A15 "●|FAIL |Error:|threshold" "$LOG" | head -n 80 || tail -n 30 "$LOG"
  exit 1
fi

# 4. make sure tests really ran, and none were skipped
SUMMARY=$(node -e '
  const r = require(process.argv[1]);
  const bad = r.numFailedTests || r.numPendingTests || r.numTodoTests || !r.numPassedTests;
  console.log(`${r.numPassedTests} of ${r.numTotalTests} tests passed, ${r.numPendingTests} skipped`);
  process.exit(bad ? 1 : 0);
' "$PWD/$RESULT") || { echo "=== FAILED: $SUMMARY ==="; exit 1; }

# 4b. every file of the feature must be loaded by the tests (else: dead code or outside the spec)
if [ "${COVERAGE_MIN:-0}" -gt 0 ]; then
  node -e '
    const s = require(process.argv[1]);
    const dead = Object.entries(s).filter(([f, c]) => f !== "total" && c.lines.total > 0 && c.lines.covered === 0);
    dead.forEach(([f]) => console.log(`FAILED: ${f.replace(process.cwd() + "/", "")} is never loaded by the tests (dead code or outside the spec?)`));
    process.exit(dead.length ? 1 : 0);
  ' "$PWD/coverage/coverage-summary.json" || exit 1
fi

# 5. optional E2E (needs a running simulator/emulator with the dev build installed)
if [ "${RUN_E2E:-0}" = "1" ] && [ -d "e2e/$FEATURE" ]; then
  "${MAESTRO_BIN:-maestro}" test "e2e/$FEATURE" >> "$LOG" 2>&1 || {
    echo "=== FAILED: maestro e2e/$FEATURE ==="; tail -n 40 "$LOG"; exit 1; }
fi

echo "$SUMMARY"
echo "=== PASSED ==="
