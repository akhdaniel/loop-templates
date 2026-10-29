#!/usr/bin/env bash
# Loop luar sesi untuk Claude Code (Cara B, Bab 7)
set -u
cd "$(dirname "$0")/.." || exit 1
MODULE="${1:-petty_cash}"
MAX=8
for i in $(seq 1 "$MAX"); do
  echo "=== Putaran $i/$MAX ==="
  if scripts/run_tests.sh "$MODULE" > last_run.txt 2>&1; then
    echo "LULUS di putaran $i"; exit 0
  fi
  claude -p "Baca CLAUDE.md, specs/$MODULE.md, PROGRESS.md, dan last_run.txt. \
Perbaiki penyebab kegagalan dengan perubahan kecil. Update PROGRESS.md. \
Jangan ubah tests/." \
    --max-turns 30 --max-budget-usd 3 \
    --allowedTools "Read,Edit,Write,Bash(scripts/run_tests.sh:*),Bash(git:*)"
done
echo "BELUM LULUS setelah $MAX putaran. Cek PROGRESS.md dan last_run.txt"
exit 1
