"""Check that a FRONTEND's mock data still matches this API's contract.

Frontend tests mock the API with JSON fixtures. If the backend changes, those mocks
silently go stale and frontend tests keep passing against data the API never returns.
Name fixtures after the operation they fake:
  <operationId>.<status>.json   e.g. list_orders.200.json, create_order.422.json
  <operationId>.request.json    a request body the frontend sends
Usage (from this backend repo):
  .venv/bin/python scripts/validate_fixtures.py contracts/openapi.json ../my-app/src/features/orders/__tests__/fixtures
"""

import json
import sys
from pathlib import Path
from typing import Any

from openapi_schema_validator import OAS31Validator


def main(contract: str, fixtures_dir: str) -> int:
    doc: dict[str, Any] = json.loads(Path(contract).read_text())
    ops = {op["operationId"]: op for methods in doc["paths"].values() for op in methods.values() if "operationId" in op}
    files = sorted(Path(fixtures_dir).rglob("*.json"))
    if not files:
        print(f"FAILED: no *.json fixtures in {fixtures_dir}")
        return 1
    errors = 0
    for path in files:
        f = path.relative_to(fixtures_dir)
        name, _, rest = f.name.removesuffix(".json").partition(".")
        op = ops.get(name)
        if op is None:
            print(f"FAILED {f}: no operationId '{name}' in the contract")
            errors += 1
            continue
        holder = op.get("requestBody", {}) if rest == "request" else op.get("responses", {}).get(rest)
        if holder is None:
            print(f"FAILED {f}: '{name}' has no {'request body' if rest == 'request' else f'response {rest}'}")
            errors += 1
            continue
        schema = next(iter(holder.get("content", {}).values()), {}).get("schema", {})
        schema = {**schema, "components": doc.get("components", {})}
        found = sorted(OAS31Validator(schema).iter_errors(json.loads(path.read_text())), key=str)
        for e in found:
            print(f"FAILED {f}: {'/'.join(map(str, e.absolute_path)) or '(root)'}: {e.message}")
        errors += len(found)
        if not found:
            print(f"ok     {f}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2]))
