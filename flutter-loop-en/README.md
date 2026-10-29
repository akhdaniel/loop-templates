# flutter-loop (English template)

A project template for building Flutter app features with AI agents (Claude Code or
OpenCode): spec first, tests locked by hash, then an implementation loop that may only
stop when the judge `scripts/run_tests.sh` passes.

The judge, for one feature in `lib/features/<feature>/`:
1. refuses missing, skipped, solo, or golden tests, and changed locked files
2. refuses `// ignore:` comments and code that detects the test environment
3. runs `dart format`, `flutter analyze --fatal-infos`, and `flutter test` on
   `test/features/<feature>/`, with a coverage minimum on the feature's own code
4. optionally runs `integration_test/<feature>/` on a device (`RUN_E2E=1`)

Talking to a backend built with fastapi-loop? See its [docs/INTEGRATION.md](../fastapi-loop-en/docs/INTEGRATION.md) for contract-checked mock data and end-to-end tests against the real API.

## Quick start
Overlay this template on a new or existing Flutter app:
```bash
flutter create my_app && cd my_app
cp -R ../flutter-loop-en/. .                  # adds AGENTS.md, .claude/, scripts/, ...
cp .env.test.example .env.test                # then adjust (FVM users: "fvm flutter")
git init
```
Requirements: Flutter 3.x, `jq` (used by the judge and the Claude Code hook).

In Claude Code (or OpenCode):
```
/spec <feature> [user story]          # 1. spec + public interface + acceptance criteria
```
As a human, add any NEW packages the spec lists (agents are not allowed to), then:
```
/tests <feature>                      # 2. draft tests in drafts/<feature>/
```
As a human, review and lock the tests:
```bash
mkdir -p test/features/<feature>
cp -R drafts/<feature>/test/. test/features/<feature>/
scripts/run_tests.sh <feature>        # new feature: must FAIL "<feature>.dart is missing"
scripts/lock_tests.sh                 # hashes test/, integration_test/, pubspec.yaml, analysis_options.yaml
git add -A && git commit -m "test: acceptance tests <feature> (locked)"
```
Then implement until the judge prints `=== PASSED ===`:
```
/implement <feature>                  # or: scripts/run_loop.sh <feature>
```
For a self-stopping session in Claude Code, start it with `LOOP_MODE=1 FEATURE=<feature> claude`:
the Stop hook then refuses to stop until the judge passes (max 8 attempts).
Finally, ask the `flutter-reviewer` agent to review the diff before you commit.

## Differences from odoo-loop
| odoo-loop | flutter-loop |
|---|---|
| addon in `addons/<addon>/` | feature in `lib/features/<feature>/` |
| `__manifest__.py` must exist | `<feature>.dart` (public interface) must exist |
| flake8 + pylint-odoo | `dart format` + `flutter analyze --fatal-infos` |
| Odoo TransactionCase on a fresh `db_test` | `flutter test` unit + widget tests with fakes |
| `depends` in the manifest | packages in `pubspec.yaml` (locked; humans add) |
| locks `tests/` | locks `test/`, `integration_test/`, `pubspec.yaml`, `analysis_options.yaml` |
| — | coverage minimum, no golden tests, optional integration tests |
