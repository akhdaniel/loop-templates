#!/usr/bin/env bash
# Judge: exit 0 = passed. Version without Docker (odoo-bin directly).
# Configuration is read from .env.test in the repo root (see .env.test.example).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
[ -f .env.test ] && . ./.env.test

MODULE="${1:-petty_cash}"
DB="${TEST_DB:-db_test}"
LOG="test.log"
: "${ODOO_BIN:?set ODOO_BIN in .env.test}"
: "${ODOO_ADDONS_PATH:?set ODOO_ADDONS_PATH in .env.test}"
read -ra ODOO_CMD <<< "$ODOO_BIN"
BIN="${VENV_BIN:+$VENV_BIN/}"
export PGHOST="${PGHOST:-localhost}" PGPORT="${PGPORT:-5432}"
export PGUSER="${PGUSER:-odoo}" PGPASSWORD="${PGPASSWORD:-odoo}"

# guard: the judge may only touch a test database
case "$DB" in
  *test*) ;;
  *) echo "FAILED: TEST_DB must contain the word 'test' (now: $DB)"; exit 6 ;;
esac

# 0. tests must exist. 0 tests = a loop that passes by lying
if ! grep -rq "def test_" "addons/$MODULE/tests" 2>/dev/null; then
  echo "FAILED: no tests in addons/$MODULE/tests yet"; exit 2
fi

# 0b. tests are locked: any change means failure
if [ -f .tests.lock ] && ! sha256sum -c .tests.lock --quiet; then
  echo "FAILED: test files changed since they were locked"; exit 4
fi

# 0c. skipping tests is forbidden
if grep -rnE "skipTest|unittest\.skip|@skip|skipIf" "addons/$MODULE/tests"; then
  echo "FAILED: skip found in tests/"; exit 5
fi

# 0d. the addon must have a manifest (otherwise Odoo silently ignores -i)
if [ ! -f "addons/$MODULE/__manifest__.py" ]; then
  echo "FAILED: addons/$MODULE/__manifest__.py is missing (addon not created yet)"; exit 7
fi

# 1. lint (pip install flake8 pylint-odoo)
"${BIN}flake8" --max-line-length=120 --per-file-ignores="__init__.py:F401" "addons/$MODULE" || { echo "FAILED: flake8"; exit 3; }
"${BIN}pylint" --rcfile=.pylintrc -d manifest-required-author,missing-readme \
  "addons/$MODULE" || { echo "FAILED: pylint-odoo"; exit 3; }

# 2. clean DB, then install the addon + run the tests
dropdb --if-exists "$DB" || { echo "FAILED: cannot drop $DB (check PostgreSQL)"; exit 1; }

"${ODOO_CMD[@]}" --addons-path="$ODOO_ADDONS_PATH,$PWD/addons" \
  --db_host="$PGHOST" --db_port="$PGPORT" --db_user="$PGUSER" --db_password="$PGPASSWORD" \
  -d "$DB" -i "$MODULE" --test-tags "/$MODULE" --without-demo=all \
  --http-port="${TEST_HTTP_PORT:-8169}" --stop-after-init > "$LOG" 2>&1
RC=$?

# 3. verdict: exit code AND log content
PATTERN=" (ERROR|CRITICAL) |FAIL:|Traceback"
if [ $RC -ne 0 ] || grep -qE "$PATTERN" "$LOG"; then
  echo "=== FAILED (exit $RC). Relevant lines: ==="
  grep -nE -B2 -A12 "$PATTERN" "$LOG" | head -n 80
  exit 1
fi

# 4. make sure tests really ran (not 0 tests)
if ! grep -qE "of [1-9][0-9]* tests" "$LOG"; then
  echo "=== FAILED: no tests were run. Check $LOG ==="
  tail -n 20 "$LOG"
  exit 1
fi

grep -E "of [0-9]+ tests" "$LOG" | tail -n 1
echo "=== PASSED ==="
