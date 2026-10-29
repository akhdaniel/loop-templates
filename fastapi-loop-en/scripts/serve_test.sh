#!/usr/bin/env bash
# Run the API for FRONTEND end-to-end tests: a fresh test database, seeded, on all
# interfaces so simulators, emulators, and phones on the same Wi-Fi can reach it.
#   iOS simulator / Vue / Expo web : http://localhost:8000
#   Android emulator               : http://10.0.2.2:8000
#   physical phone                 : http://<this machine's LAN IP>:8000
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1
CALLER_PORT="${E2E_PORT:-}"            # E2E_PORT=9000 scripts/serve_test.sh wins over .env.test
[ -f .env.test ] && . ./.env.test
BIN="${VENV_BIN:-.venv/bin}/"
PORT="${CALLER_PORT:-${E2E_PORT:-8000}}"
DB_FILE="e2e.test.db"

rm -f "$DB_FILE"
export DATABASE_URL="sqlite:///./$DB_FILE"
"${BIN}python" - <<'EOF'
import importlib.util

from app.db import Base, SessionLocal, engine
import app.main  # noqa: F401  (imports every feature router, so every model is registered)

Base.metadata.create_all(engine)
if importlib.util.find_spec("app.seed"):
    from app.seed import seed
    with SessionLocal() as session:
        seed(session)
        session.commit()
    print("Seeded test data from app/seed.py")
EOF
echo "API for E2E on http://0.0.0.0:$PORT (Ctrl+C to stop)"
exec "${BIN}uvicorn" app.main:app --host 0.0.0.0 --port "$PORT"
