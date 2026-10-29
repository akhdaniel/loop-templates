"""For HUMANS only: publish the current API as contracts/openapi.json.

Run after a feature passes the judge and has been reviewed. Frontends generate their
types/clients from this file, and the judge refuses breaking changes against it.
Usage: .venv/bin/python scripts/export_openapi.py
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.main import app

out = Path("contracts/openapi.json")
out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(app.openapi(), indent=2, sort_keys=True) + "\n")
print(f"Wrote {out} ({len(app.openapi()['paths'])} paths). Commit it, then re-run scripts/lock_tests.sh")
