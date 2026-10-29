#!/usr/bin/env bash
# Hakim: exit 0 = lulus. Versi tanpa Docker (odoo-bin langsung).
# Konfigurasi dibaca dari .env.test di root repo (lihat .env.test.example).
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
[ -f .env.test ] && . ./.env.test

MODULE="${1:-petty_cash}"
DB="${TEST_DB:-db_test}"
LOG="test.log"
: "${ODOO_BIN:?isi ODOO_BIN di .env.test}"
: "${ODOO_ADDONS_PATH:?isi ODOO_ADDONS_PATH di .env.test}"
read -ra ODOO_CMD <<< "$ODOO_BIN"
BIN="${VENV_BIN:+$VENV_BIN/}"
export PGHOST="${PGHOST:-localhost}" PGPORT="${PGPORT:-5432}"
export PGUSER="${PGUSER:-odoo}" PGPASSWORD="${PGPASSWORD:-odoo}"

# pengaman: hakim hanya boleh menyentuh database test
case "$DB" in
  *test*) ;;
  *) echo "GAGAL: TEST_DB harus mengandung kata 'test' (sekarang: $DB)"; exit 6 ;;
esac

# 0. test harus ada. 0 test = loop bohong lulus
if ! grep -rq "def test_" "addons/$MODULE/tests" 2>/dev/null; then
  echo "GAGAL: belum ada test di addons/$MODULE/tests"; exit 2
fi

# 0b. test dikunci: berubah berarti gagal
if [ -f .tests.lock ] && ! sha256sum -c .tests.lock --quiet; then
  echo "GAGAL: file test berubah sejak dikunci"; exit 4
fi

# 0c. dilarang skip test
if grep -rnE "skipTest|unittest\.skip|@skip|skipIf" "addons/$MODULE/tests"; then
  echo "GAGAL: ada skip di tests/"; exit 5
fi

# 0d. addon harus punya manifest (kalau tidak, Odoo diam-diam mengabaikan -i)
if [ ! -f "addons/$MODULE/__manifest__.py" ]; then
  echo "GAGAL: addons/$MODULE/__manifest__.py belum ada (addon belum dibuat)"; exit 7
fi

# 1. lint (pip install flake8 pylint-odoo)
"${BIN}flake8" --max-line-length=120 --per-file-ignores="__init__.py:F401" "addons/$MODULE" || { echo "GAGAL: flake8"; exit 3; }
"${BIN}pylint" --rcfile=.pylintrc -d manifest-required-author,missing-readme \
  "addons/$MODULE" || { echo "GAGAL: pylint-odoo"; exit 3; }

# 2. DB bersih, lalu install addon + jalanin test
dropdb --if-exists "$DB" || { echo "GAGAL: tidak bisa drop $DB (cek PostgreSQL)"; exit 1; }

"${ODOO_CMD[@]}" --addons-path="$ODOO_ADDONS_PATH,$PWD/addons" \
  --db_host="$PGHOST" --db_port="$PGPORT" --db_user="$PGUSER" --db_password="$PGPASSWORD" \
  -d "$DB" -i "$MODULE" --test-tags "/$MODULE" --without-demo=all \
  --http-port="${TEST_HTTP_PORT:-8169}" --stop-after-init > "$LOG" 2>&1
RC=$?

# 3. vonis: exit code DAN isi log
PATTERN=" (ERROR|CRITICAL) |FAIL:|Traceback"
if [ $RC -ne 0 ] || grep -qE "$PATTERN" "$LOG"; then
  echo "=== GAGAL (exit $RC). Baris relevan: ==="
  grep -nE -B2 -A12 "$PATTERN" "$LOG" | head -n 80
  exit 1
fi

# 4. pastikan test beneran jalan (bukan 0 test)
if ! grep -qE "of [1-9][0-9]* tests" "$LOG"; then
  echo "=== GAGAL: tidak ada test yang dijalankan. Cek $LOG ==="
  tail -n 20 "$LOG"
  exit 1
fi

grep -E "of [0-9]+ tests" "$LOG" | tail -n 1
echo "=== LULUS ==="
