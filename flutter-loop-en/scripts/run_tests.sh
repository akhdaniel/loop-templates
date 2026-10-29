#!/usr/bin/env bash
# Judge: exit 0 = passed. Format + analyze + flutter test (with coverage) for one feature,
# plus optional integration tests on a device. Configuration is read from .env.test.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
[ -f .env.test ] && . ./.env.test

FEATURE="${1:?usage: scripts/run_tests.sh <feature>}"
LIB="lib/features/$FEATURE"
TESTS="test/features/$FEATURE"
LOG="test.log"
read -ra FL <<< "${FLUTTER_BIN:-flutter}"
read -ra DART <<< "${DART_BIN:-dart}"
DEFINES=()
[ -n "${API_BASE_URL:-}" ] && DEFINES=("--dart-define=API_BASE_URL=$API_BASE_URL")
if command -v sha256sum >/dev/null; then SHA=(sha256sum); else SHA=(shasum -a 256); fi
command -v jq >/dev/null || { echo "FAILED: jq is required (brew install jq)"; exit 1; }

# guard: the judge must never run against production
case "${API_BASE_URL:-}" in
  *prod*) echo "FAILED: API_BASE_URL points to production ($API_BASE_URL)"; exit 6 ;;
esac

# 0. tests must exist. 0 tests = a loop that passes by lying
if ! grep -rqE "\b(test|testWidgets)\(" "$TESTS" 2>/dev/null; then
  echo "FAILED: no tests in $TESTS yet"; exit 2
fi

# 0b. tests and test config are locked: any change means failure
if [ -f .tests.lock ] && ! "${SHA[@]}" -c .tests.lock --quiet; then
  echo "FAILED: locked files (tests or config) changed since they were locked"; exit 4
fi

# 0c. skipping, focusing, and golden tests are forbidden
if grep -rnE "\bskip:|@Skip|solo: *true|markTestSkipped|matchesGoldenFile|matchesReferenceImage" "$TESTS"; then
  echo "FAILED: skip/solo or golden test found in $TESTS"; exit 5
fi

# 0d. the feature must have its public entry point
if [ ! -f "$LIB/$FEATURE.dart" ]; then
  echo "FAILED: $LIB/$FEATURE.dart is missing (feature not created yet)"; exit 7
fi

# 0e. no escape hatches or test-environment detection in feature code
if grep -rnE "// *ignore(_for_file)?:|FLUTTER_TEST|Platform\.environment" \
    --include='*.dart' "$LIB" | grep -vE "\.(g|freezed)\.dart:"; then
  echo "FAILED: forbidden escape hatch in feature code (see lines above)"; exit 5
fi

# 1. format + analyze (tests are analyzed too: a missing export shows up here)
"${DART[@]}" format --output=none --set-exit-if-changed "$LIB" || {
  echo "FAILED: dart format (run: ${DART[*]} format $LIB)"; exit 3; }
"${FL[@]}" analyze --fatal-infos --fatal-warnings "$LIB" "$TESTS" || { echo "FAILED: flutter analyze"; exit 3; }

# 2. unit + widget tests, machine-readable
rm -rf coverage
"${FL[@]}" test "$TESTS" --reporter json --coverage "${DEFINES[@]}" > "$LOG" 2>&1
RC=$?

# 3. verdict: exit code AND events in the log
COUNTS=$(jq -R -s -r '[split("\n")[] | fromjson? | select(.type == "testDone" and .hidden == false)]
  | "\(map(select(.result == "success" and .skipped == false)) | length) \(map(select(.result != "success")) | length) \(map(select(.skipped)) | length)"' "$LOG")
read -r PASSED FAILED SKIPPED <<< "${COUNTS:-0 0 0}"
if [ $RC -ne 0 ] || [ "$FAILED" -ne 0 ]; then
  echo "=== FAILED (exit $RC, $FAILED failed). Relevant lines: ==="
  jq -R -s -r '[split("\n")[] | fromjson?] as $e
    | ($e | map(select(.type == "testStart")) | map({key: (.test.id | tostring), value: .test.name}) | from_entries) as $n
    | ($e | map(select(.type == "print")) | group_by(.testID)
       | map({key: (.[0].testID | tostring), value: (map(.message) | join("\n") | split("\n")[:25] | join("\n"))})
       | from_entries) as $p
    | $e[] | select(.type == "error")
    | "● \($n[.testID | tostring] // "loading")\n\($p[.testID | tostring] // "")\n\(.error)\n\(.stackTrace | split("\n")[:8] | join("\n"))"' "$LOG" | head -n 80
  grep -vE '^\{' "$LOG" | tail -n 15
  exit 1
fi

# 4. make sure tests really ran, and none were skipped
if [ "$PASSED" -eq 0 ] || [ "$SKIPPED" -ne 0 ]; then
  echo "=== FAILED: $PASSED passed, $SKIPPED skipped. Check $LOG ==="; exit 1
fi

# 5. coverage of the feature's own code (generated files excluded)
if [ "${COVERAGE_MIN:-0}" -gt 0 ]; then
  LOADED=$(grep -E "^SF:" coverage/lcov.info 2>/dev/null | sed 's/^SF://')
  for f in $(find "$LIB" -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart'); do
    echo "$LOADED" | grep -q "$f$" || { echo "FAILED: $f is never loaded by the tests (dead code or outside the spec?)"; exit 1; }
  done
  PCT=$(awk -v d="$LIB/" '
    /^SF:/ { on = index($0, d) > 0 && $0 !~ /\.(g|freezed)\.dart$/ }
    on && /^DA:/ { split(substr($0, 4), a, ","); t++; if (a[2] > 0) h++ }
    END { printf "%d", t ? 100 * h / t : 0 }' coverage/lcov.info)
  if [ "$PCT" -lt "$COVERAGE_MIN" ]; then
    echo "=== FAILED: line coverage of $LIB is $PCT%, minimum $COVERAGE_MIN% ==="; exit 1
  fi
fi

# 6. optional integration tests (need a booted simulator/emulator or device)
if [ "${RUN_E2E:-0}" = "1" ] && [ -d "integration_test/$FEATURE" ]; then
  "${FL[@]}" test "integration_test/$FEATURE" ${DEVICE_ID:+-d "$DEVICE_ID"} "${DEFINES[@]}" >> "$LOG" 2>&1 || {
    echo "=== FAILED: integration_test/$FEATURE ==="; tail -n 40 "$LOG"; exit 1; }
fi

echo "$PASSED of $((PASSED + SKIPPED)) tests passed, coverage ${PCT:-n/a}%"
echo "=== PASSED ==="
