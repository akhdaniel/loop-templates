#!/usr/bin/env bash
# Loop luar sesi untuk OpenCode (Bab 8)
set -u
cd "$(dirname "$0")/.." || exit 1
MODULE="${1:-petty_cash}"
MAX=8
for i in $(seq 1 "$MAX"); do
  echo "=== Putaran $i/$MAX ==="
  if scripts/run_tests.sh "$MODULE" > last_run.txt 2>&1; then
    echo "LULUS di putaran $i"; exit 0
  fi
  timeout 20m opencode run "Baca AGENTS.md, specs/$MODULE.md, PROGRESS.md, \
dan last_run.txt. Perbaiki penyebab kegagalan dengan perubahan kecil. \
Update PROGRESS.md. Jangan ubah tests/."
done
echo "BELUM LULUS setelah $MAX putaran. Cek PROGRESS.md dan last_run.txt"
exit 1
