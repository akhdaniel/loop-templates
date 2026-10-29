# fastapi-loop (English template)

A project template for building a FastAPI backend with AI agents (Claude Code or
OpenCode): spec first, tests locked by hash, then an implementation loop that may only
stop when the judge `scripts/run_tests.sh` passes. Made to pair with the frontend
templates rn-loop, flutter-loop, and vue-loop: see [docs/INTEGRATION.md](docs/INTEGRATION.md).

The judge, for one feature in `app/features/<feature>/`:
1. refuses missing, skipped, or xfailed tests, and changed locked files
2. refuses `# type: ignore`, `# noqa`, `# pragma: no cover`, and code that detects pytest
3. runs ruff (lint + format), `mypy --strict`, and the feature's pytest tests (real HTTP
   through `TestClient`, a fresh database per test) with a coverage minimum; a feature
   file the tests never load fails too
4. refuses endpoints whose `operationId` is not named in any spec (scope creep)
5. runs a Schemathesis contract test over the whole API: requests generated from the
   OpenAPI schema, no 500s, every response matches its schema
6. refuses breaking changes against the published `contracts/openapi.json`

## Quick start
This template is the whole project skeleton (unlike the frontend templates):
```bash
cp -R fastapi-loop-en my-api && cd my-api
python3 -m venv .venv && .venv/bin/pip install -e ".[dev]"     # or: uv venv && uv pip install -e ".[dev]"
cp .env.test.example .env.test                                 # then adjust
git init
```
Requirements: Python 3.11+, `jq` (for the Claude Code hook).

In Claude Code (or OpenCode):
```
/spec <feature> [business process]    # 1. spec + endpoints (operationIds) + acceptance criteria
/tests <feature>                      # 2. draft tests in drafts/<feature>/
```
As a human, review and lock the tests:
```bash
mkdir -p tests/features/<feature>
cp drafts/<feature>/*.py tests/features/<feature>/
scripts/run_tests.sh <feature>        # new feature: must FAIL "router.py is missing"
scripts/lock_tests.sh                 # hashes tests/, specs/, pyproject.toml, and the contract
git add -A && git commit -m "test: acceptance tests <feature> (locked)"
```
Then implement until the judge prints `=== PASSED ===`:
```
/implement <feature>                  # or: scripts/run_loop.sh <feature>
```
For a self-stopping session in Claude Code, start it with `LOOP_MODE=1 FEATURE=<feature> claude`:
the Stop hook then refuses to stop until the judge passes (max 8 attempts).
Ask the `api-reviewer` agent to review the diff, then publish the contract for the frontends:
```bash
.venv/bin/python scripts/export_openapi.py && scripts/lock_tests.sh
git add -A && git commit -m "api: publish contract for <feature>"
```

## Scripts
| Script | Who | What |
|---|---|---|
| `run_tests.sh <feature>` | agent + human | the judge |
| `lock_tests.sh` | human | lock tests, `pyproject.toml`, and the contract |
| `export_openapi.py` | human | publish `contracts/openapi.json` |
| `check_contract.py` | judge | breaking-change check against the contract |
| `validate_fixtures.py <contract> <dir>` | human / CI | check a frontend's mock data against the contract |
| `serve_test.sh` | human | API with a fresh seeded test DB for frontend E2E |
| `run_loop.sh`, `run_loop_opencode.sh` | human | outer loop across agent sessions |

Database migrations (Alembic) are not part of the loop: the tests build the schema from
the models. Add Alembic when the first real database exists.

## Differences from odoo-loop
| odoo-loop | fastapi-loop |
|---|---|
| addon in `addons/<addon>/` | feature in `app/features/<feature>/` |
| `__manifest__.py` must exist | `router.py` must exist and be included in `app/main.py` |
| flake8 + pylint-odoo | ruff + `mypy --strict` |
| TransactionCase on a fresh `db_test` | pytest over HTTP, fresh SQLite (or PostgreSQL `*test*`) DB per test |
| — | Schemathesis contract test, no breaking changes to `contracts/openapi.json` |
| — | `validate_fixtures.py` + `serve_test.sh` to test against the frontends |
