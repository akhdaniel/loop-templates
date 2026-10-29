---
description: Write a spec + acceptance criteria for a new feature (no code)
argument-hint: <feature_name> [user story / flow description]
---
You are a product analyst and a React Native (Expo) developer. Your job is to write
a SPEC with acceptance criteria (AC) for a new app feature. Do NOT write any code, and
do NOT create or change any file other than specs/<feature_name>.md.

Arguments: $ARGUMENTS
First word = technical feature name (snake_case or kebab-case, used as the folder
src/features/<feature_name>/). The rest (if any) = user story / flow description.

## Steps
1. Read CLAUDE.md, package.json (to see which packages are installed), and, as
   format examples, the existing files in specs/.
2. If specs/<feature_name>.md already exists: read it, then ask first whether to
   overwrite or update it. Never overwrite without an answer.
3. If this information is not in the arguments yet, ASK first (once, as a list)
   before writing:
   - user flow: who does what on which screen, inputs, numeric rules/limits
   - data: where it comes from (API endpoint, local storage), request/response shape
   - states: what the user sees while loading, when empty, and on error/offline
   - device permissions (camera, location, notifications) and what happens if denied
   - packages that may be used, as few as possible (new ones need a human to install)
   - what is out of scope
4. Write specs/<feature_name>.md with the rules and format below.
5. Show a summary of the ACs, any packages that must be installed first, and the
   "Open questions", then stop. Tests and code are written in the next steps,
   after a human has reviewed this spec.

## Rules for writing ACs
1. Each AC is one behavior that an automated Jest + React Native Testing Library
   test can prove (render, press, type, wait for text), with network, storage,
   navigation, and permissions mocked. Not "looks good on device".
2. Numbered AC-01, AC-02, ... One sentence, specific, with clear numbers/limits and
   the exact text or accessibility label the user sees. Avoid words like "easy",
   "fast", "nice", "appropriate".
3. Cover these categories when relevant:
   - states: loading, empty, error (and a retry), success
   - input validation: wrong values show a specific message and block submit,
     including a value EXACTLY at the limit and one past the limit
   - interactions and navigation: which press leads to which route (router mocked)
   - data/logic: pure calculations, formatting, sorting/filtering
   - persistence and network: correct request sent, success AND failure handled
   - permissions: granted and denied paths
   - accessibility: key elements reachable by role + label
4. For every "can" rule, also write its "cannot" counterpart.
5. At most 8 ACs. If there are more, propose splitting into phases/separate features.
6. If anything is ambiguous, do NOT guess: put it under "Open questions".

## Format of specs/<feature_name>.md
# Spec: <feature_name>
## Goal              (2-3 sentences, the user story)
## Dependencies      (packages already installed that are used; NEW packages a human
                      must install before the tests are locked; platforms iOS/Android)
## Public interface  (the contract tests are written against, before any code exists:
                      - exports from src/features/<feature_name>/index.ts with their
                        props / signatures (components, hooks, pure functions)
                      - modules the tests mock, with their exact path and signature
                        (e.g. src/lib/api.ts `getOrders(): Promise<Order[]>`)
                      - route paths used with expo-router
                      - accessibility labels, roles, testIDs, and visible texts)
## Data              (TypeScript types, API endpoints with request/response, storage keys)
## Backend calls      (fastapi-loop backend only: the operationId behind every API call)
## Acceptance criteria
- AC-01 ...
## UI                (screens, components, loading/empty/error states)
## Permissions & security (device permissions, secure storage, auth)
## Out of scope
## Definition of Done
- scripts/run_tests.sh <feature_name> exit 0
- every AC has at least one test whose name starts with "AC-XX"
- no test is weakened, skipped, or snapshot-based
## AC-to-test mapping
| AC | Test file | Test name | Scenario | Expected assertion |
## E2E (optional)    (Maestro flows for the main happy path, if wanted)
## Open questions
