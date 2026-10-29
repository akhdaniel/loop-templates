"""Fail on BREAKING changes between the published contract and the current app.

Allowed: new endpoints, new optional request fields, new response fields.
Breaking: removed endpoints or responses, removed or retyped response fields,
response fields no longer required, new required request fields or parameters.
Usage: python scripts/check_contract.py contracts/openapi.json
"""

import json
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.main import app

Schema = dict[str, Any]
problems: list[str] = []


def resolve(doc: Schema, s: Schema) -> Schema:
    while "$ref" in s:
        s = doc["components"]["schemas"][s["$ref"].split("/")[-1]]
    return s


def kind(doc: Schema, s: Schema) -> str:
    s = resolve(doc, s)
    if "anyOf" in s or "oneOf" in s:
        return "|".join(sorted(kind(doc, x) for x in s.get("anyOf", s.get("oneOf", []))))
    return str(s.get("type", "any"))


def compare(
    old_doc: Schema, new_doc: Schema, old: Schema, new: Schema, where: str, request: bool, depth: int = 0
) -> None:
    old, new = resolve(old_doc, old), resolve(new_doc, new)
    if depth > 8:
        return
    if kind(old_doc, old) != kind(new_doc, new):
        problems.append(f"{where}: type {kind(old_doc, old)} -> {kind(new_doc, new)}")
        return
    if old.get("type") == "array":
        compare(old_doc, new_doc, old.get("items", {}), new.get("items", {}), f"{where}[]", request, depth + 1)
        return
    old_props, new_props = old.get("properties", {}), new.get("properties", {})
    old_req, new_req = set(old.get("required", [])), set(new.get("required", []))
    if request:
        for name in sorted(new_req - old_req):
            problems.append(f"{where}.{name}: new required request field")
    else:
        for name in sorted(old_props):
            if name not in new_props:
                problems.append(f"{where}.{name}: response field removed")
        for name in sorted((old_req - new_req) & set(new_props)):
            problems.append(f"{where}.{name}: response field no longer required")
    for name in sorted(set(old_props) & set(new_props)):
        compare(old_doc, new_doc, old_props[name], new_props[name], f"{where}.{name}", request, depth + 1)


def content_schema(obj: Schema) -> Schema | None:
    """Schema of a requestBody or response object (first media type)."""
    content = obj.get("content", {})
    return next(iter(content.values()), {}).get("schema") if content else None


def main(path: str) -> int:
    old_doc: Schema = json.loads(Path(path).read_text())
    new_doc: Schema = app.openapi()
    for route, methods in old_doc.get("paths", {}).items():
        for method, old_op in methods.items():
            where = f"{method.upper()} {route}"
            new_op = new_doc.get("paths", {}).get(route, {}).get(method)
            if new_op is None:
                problems.append(f"{where}: endpoint removed")
                continue
            old_params = {(p["in"], p["name"]) for p in old_op.get("parameters", [])}
            for p in new_op.get("parameters", []):
                if p.get("required") and (p["in"], p["name"]) not in old_params:
                    problems.append(f"{where}: new required {p['in']} parameter '{p['name']}'")
            old_body, new_body = (
                content_schema(old_op.get("requestBody", {})),
                content_schema(new_op.get("requestBody", {})),
            )
            if old_body is None and new_body is not None and new_op["requestBody"].get("required"):
                problems.append(f"{where}: new required request body")
            if old_body is not None and new_body is not None:
                compare(old_doc, new_doc, old_body, new_body, f"{where} body", request=True)
            for status, old_resp in old_op.get("responses", {}).items():
                if not status.startswith("2"):
                    continue
                new_resp = new_op.get("responses", {}).get(status)
                if new_resp is None:
                    problems.append(f"{where}: response {status} removed")
                    continue
                old_s, new_s = content_schema(old_resp), content_schema(new_resp)
                if old_s is not None and new_s is not None:
                    compare(old_doc, new_doc, old_s, new_s, f"{where} {status}", request=False)
    for p in problems:
        print(f"BREAKING: {p}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
