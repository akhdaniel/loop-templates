#!/usr/bin/env bash
# Stop hook: Claude hanya boleh berhenti kalau hakim lulus (aktif jika LOOP_MODE=1).
[ "${LOOP_MODE:-0}" = "1" ] || exit 0
MAX=8
F=".claude/.stop_count"
n=$(cat "$F" 2>/dev/null || echo 0)

if [ "$n" -ge "$MAX" ]; then
  rm -f "$F"; exit 0              # menyerah: manusia ambil alih
fi

if out=$(scripts/run_tests.sh "${MODULE:-petty_cash}" 2>&1); then
  rm -f "$F"; exit 0              # lulus: boleh berhenti
fi

echo $((n + 1)) > "$F"
{
  echo "Verifikasi GAGAL (percobaan $((n + 1))/$MAX). Perbaiki, jangan berhenti sebelum lulus."
  echo "$out" | tail -n 60
} >&2
exit 2
