# rn-loop (English template)

A project template for building React Native (Expo) app features with AI agents
(Claude Code or OpenCode): spec first, tests locked by hash, then an implementation
loop that may only stop when the judge `scripts/run_tests.sh` passes.

The judge, for one feature in `src/features/<feature>/`:
1. refuses missing, skipped, focused, or snapshot tests, and changed locked files
2. refuses `@ts-ignore`, `eslint-disable`, and code that detects Jest
3. runs `tsc --noEmit`, `eslint --max-warnings=0`, and Jest (jest-expo + React Native
   Testing Library) with a coverage minimum on the feature's own code; a feature
   file the tests never load fails too
4. optionally runs Maestro E2E flows from `e2e/<feature>/` (`RUN_E2E=1`)

Talking to a backend built with fastapi-loop? See its [docs/INTEGRATION.md](../fastapi-loop-en/docs/INTEGRATION.md) for contract-checked mock data and end-to-end tests against the real API.

## Quick start
Overlay this template on a new Expo app (TypeScript, Expo Router):
```bash
npx create-expo-app@latest my-app && cd my-app
cp -R ../rn-loop-en/. .                       # adds AGENTS.md, .claude/, scripts/, ...
npx expo install jest-expo jest @types/jest @testing-library/react-native -- --save-dev
npx expo lint                                 # creates eslint.config.js the first time
cp .env.test.example .env.test                # then adjust
git init
```
Requirements: Node 20+, `jq` (for the Claude Code hook). Optional: Maestro for E2E.

In Claude Code (or OpenCode):
```
/spec <feature> [user story]          # 1. spec + public interface + acceptance criteria
```
As a human, install any NEW packages the spec lists (agents are not allowed to), then:
```
/tests <feature>                      # 2. draft tests in drafts/<feature>/
```
As a human, review and lock the tests:
```bash
mkdir -p src/features/<feature>/__tests__
cp -R drafts/<feature>/__tests__/. src/features/<feature>/__tests__/
scripts/run_tests.sh <feature>        # new feature: must FAIL "index.ts is missing"
scripts/lock_tests.sh                 # hashes tests, e2e/, package.json, and test config
git add -A && git commit -m "test: acceptance tests <feature> (locked)"
```
Then implement until the judge prints `=== PASSED ===`:
```
/implement <feature>                  # or: scripts/run_loop.sh <feature>
```
For a self-stopping session in Claude Code, start it with `LOOP_MODE=1 FEATURE=<feature> claude`:
the Stop hook then refuses to stop until the judge passes (max 8 attempts).
Finally, ask the `rn-reviewer` agent to review the diff before you commit.

## Differences from odoo-loop
| odoo-loop | rn-loop |
|---|---|
| addon in `addons/<addon>/` | feature in `src/features/<feature>/` |
| `__manifest__.py` must exist | `index.ts` (public interface) must exist |
| flake8 + pylint-odoo | `tsc --noEmit` + eslint |
| Odoo TransactionCase on a fresh `db_test` | Jest + RNTL, network/storage/router mocked |
| `depends` in the manifest | packages in `package.json` (locked; humans install) |
| locks `tests/` | locks `__tests__/`, `e2e/`, `package.json`, and test config |
| — | coverage minimum, no snapshots, optional Maestro E2E |
