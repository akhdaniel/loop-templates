#!/usr/bin/env bash
# Judge: exit 0 = passed. Lint + types + pytest (with coverage) for one feature, the
# schema-driven contract test for the whole API, and a breaking-change check against
# contracts/openapi.json. Configuration is read from .env.test (see .env.test.example).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
[ -f .env.test ] && . ./.env.test

FEATURE="${1:?usage: scripts/run_tests.sh <feature>}"
DIR="app/features/$FEATURE"
TESTS="tests/features/$FEATURE"
LOG="test.log"
RESULT=".pytest-result.xml"
BIN="${VENV_BIN:-.venv/bin}/"
export TEST_DATABASE_URL="${TEST_DATABASE_URL:-sqlite://}"
if command -v sha256sum >/dev/null; then SHA=(sha256sum); else SHA=(shasum -a 256); fi

# guard: the judge may only touch a test database
case "$TEST_DATABASE_URL" in
  sqlite://|*test*) ;;
  *) echo "FAILED: TEST_DATABASE_URL must contain the word 'test' (now: $TEST_DATABASE_URL)"; exit 6 ;;
esac

# 0. tests must exist. 0 tests = a loop that passes by lying
if ! grep -rqE "^\s*(async )?def test_" "$TESTS" 2>/dev/null; then
  echo "FAILED: no tests in $TESTS yet"; exit 2
fi

# 0b. tests, contract, and config are locked: any change means failure
if [ -f .tests.lock ] && ! "${SHA[@]}" -c .tests.lock --quiet; then
  echo "FAILED: locked files (tests, specs, contract, or config) changed since they were locked"; exit 4
fi

# 0c. skipping or expecting failure is forbidden
if grep -rnE "pytest\.(skip|xfail|importorskip)|mark\.(skip|skipif|xfail)" tests/; then
  echo "FAILED: skip/xfail found in tests/"; exit 5
fi

# 0d. the feature must have its router (otherwise nothing is served)
if [ ! -f "$DIR/__init__.py" ] || [ ! -f "$DIR/router.py" ]; then
  echo "FAILED: $DIR/__init__.py or $DIR/router.py is missing (feature not created yet)"; exit 7
fi

# 0e. no escape hatches or test-environment detection in app code
if grep -rnE "#\s*(type:\s*ignore|noqa|pragma:\s*no\s*cover)|PYTEST|[\"']pytest[\"']\s+in\s+sys\.modules" \
    --include='*.py' app; then
  echo "FAILED: forbidden escape hatch in app code (see lines above)"; exit 5
fi

# 1. lint + format + types
"${BIN}ruff" check app tests || { echo "FAILED: ruff check"; exit 3; }
"${BIN}ruff" format --check app || { echo "FAILED: ruff format (run: ruff format app)"; exit 3; }
"${BIN}mypy" app || { echo "FAILED: mypy"; exit 3; }

# 2. feature tests with coverage (only the locked feature tests count for coverage)
"${BIN}pytest" "$TESTS" -q -rfE --junitxml="$RESULT" \
  --cov="$DIR" --cov-report=term-missing:skip-covered --cov-report=json:coverage.json \
  --cov-fail-under="${COVERAGE_MIN:-0}" > "$LOG" 2>&1
RC=$?

# 3. verdict: exit code AND result content
if [ $RC -ne 0 ] || [ ! -f "$RESULT" ]; then
  echo "=== FAILED (exit $RC). Relevant lines: ==="
  grep -nE -A25 "^(_{3,}|E |FAILED|ERROR)|Coverage failure|Required test coverage" "$LOG" | head -n 80 || tail -n 30 "$LOG"
  exit 1
fi

# 4. tests really ran, none skipped; every feature file is loaded by the tests
SUMMARY=$("${BIN}python" - "$RESULT" "$DIR" <<'EOF'
import json, sys, xml.etree.ElementTree as ET
s = ET.parse(sys.argv[1]).getroot()
s = s.find("testsuite") if s.tag == "testsuites" else s
n, bad = int(s.get("tests")), sum(int(s.get(k)) for k in ("failures", "errors", "skipped"))
print(f"{n - bad} of {n} tests passed, {s.get('skipped')} skipped")
dead = [f for f, d in json.load(open("coverage.json"))["files"].items()
        if d["summary"]["num_statements"] and not d["summary"]["covered_lines"]]
for f in dead:
    print(f"FAILED: {f} is never loaded by the tests (dead code or outside the spec?)")
sys.exit(1 if n == 0 or bad or dead else 0)
EOF
) || { echo "=== FAILED ==="; echo "$SUMMARY"; exit 1; }

# 4b. every endpoint the app serves must be named in a spec (no endpoints outside the scope)
"${BIN}python" - <<'EOF' || exit 1
import re, sys
from pathlib import Path
from app.main import app
specs = " ".join(p.read_text() for p in Path("specs").glob("*.md"))
ops = [op.get("operationId", f"{m.upper()} {path}") for path, ms in app.openapi()["paths"].items() for m, op in ms.items()]
extra = [o for o in ops if o != "health" and not re.search(rf"\b{re.escape(o)}\b", specs)]
for o in extra:
    print(f"FAILED: endpoint '{o}' is not in any spec (outside the scope, or missing operation_id?)")
sys.exit(1 if extra else 0)
EOF

# 5. contract test for the whole API: schema-generated requests, no 500s, responses match
"${BIN}pytest" tests/test_contract.py -q -rfE >> "$LOG" 2>&1 || {
  echo "=== FAILED: contract test (an endpoint breaks its own OpenAPI schema) ==="
  grep -nE -A25 "^(_{3,}|E |FAILED|ERROR)" "$LOG" | tail -n 60; exit 1; }

# 6. no breaking change against the published contract (adding is fine)
if [ -f contracts/openapi.json ]; then
  "${BIN}python" scripts/check_contract.py contracts/openapi.json || {
    echo "FAILED: breaking API change (see above). Frontends depend on contracts/openapi.json"; exit 8; }
fi

echo "$SUMMARY"
echo "=== PASSED ==="
