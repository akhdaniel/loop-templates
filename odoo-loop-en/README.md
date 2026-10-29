# odoo-loop (English template)

A project template for building Odoo 18 addons with AI agents (Claude Code or OpenCode):
spec first, tests locked by hash, then an implementation loop that may only stop when the
judge `scripts/run_tests.sh` passes.

Full step-by-step guide: [docs/odoo-loop-user-guide.pdf](docs/odoo-loop-user-guide.pdf)

## Quick start
```bash
cp .env.test.example .env.test        # then set your Odoo 18 / venv / PostgreSQL paths
git init
```
In Claude Code (or OpenCode):
```
/spec <addon> [business process]      # 1. spec + acceptance criteria
/tests <addon>                        # 2. draft tests in drafts/<addon>/tests/
```
As a human, review and lock the tests:
```bash
mkdir -p addons/<addon>/tests
cp drafts/<addon>/tests/*.py addons/<addon>/tests/
scripts/run_tests.sh <addon>          # new addon: must FAIL "manifest is missing"
find addons/*/tests -name '*.py' -exec sha256sum {} + > .tests.lock
git add -A && git commit -m "test: acceptance tests <addon> (locked)"
```
Then implement until the judge prints `=== PASSED ===`:
```
/implement <addon>                    # or: scripts/run_loop.sh <addon>
```
