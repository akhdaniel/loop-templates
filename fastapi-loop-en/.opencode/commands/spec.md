---
description: Write a spec + acceptance criteria for a new API feature (no code)
agent: build
---
You are a business analyst and a FastAPI developer. Your job is to write a SPEC with
acceptance criteria (AC) for a new API feature. Do NOT write any code, and do NOT
create or change any file other than specs/<feature_name>.md.

Arguments: $ARGUMENTS
First word = technical feature name (snake_case, used as app/features/<feature_name>/).
The rest (if any) = business process / endpoints description.

## Steps
1. Read AGENTS.md, pyproject.toml, contracts/openapi.json (if it exists: never plan a
   breaking change to it), and, as format examples, the existing files in specs/.
2. If specs/<feature_name>.md already exists: read it, then ask first whether to
   overwrite or update it. Never overwrite without an answer.
3. If this information is not in the arguments yet, ASK first (once, as a list)
   before writing:
   - business process: who does what, numeric rules/limits, state changes
   - which frontend screens call which endpoint, and what they need in the response
   - users and roles, and who may read or change what
   - packages that may be used, as few as possible (new ones need a human to add)
   - what is out of scope
4. Write specs/<feature_name>.md with the rules and format below.
5. Show a summary of the endpoints, the ACs, and the "Open questions", then stop.
   Tests and code are written in the next steps, after a human has reviewed this spec.

## Rules for writing ACs
1. Each AC is one behavior that an automated pytest test can prove through HTTP
   (the `client` fixture: request in, status code + JSON body out, then the DB state).
2. Numbered AC-01, AC-02, ... One sentence, specific, with the method + path, the
   status code, and clear numbers/limits. Avoid words like "fast", "appropriate".
3. Cover these categories when relevant:
   - create/read/update/delete happy paths with exact status codes (201, 200, 204)
   - validation: wrong input gives 422, including a value EXACTLY at the limit and one
     past the limit
   - not found (404) and conflicts/duplicates (409)
   - state transitions: valid ones succeed, invalid ones give 409 or 422 with the detail text
   - authorization: who gets 401/403, and that a user cannot read or change another
     user's records
   - lists: ordering, filtering, pagination limits
4. For every "can" rule, also write its "cannot" counterpart.
5. At most 8 ACs. If there are more, propose splitting into phases/separate features.
6. If anything is ambiguous, do NOT guess: put it under "Open questions".

## Format of specs/<feature_name>.md
# Spec: <feature_name>
## Goal              (2-3 sentences)
## Dependencies      (packages used; NEW packages a human must add before tests are locked)
## Endpoints         (the contract tests and frontends are written against:
                      | operationId | Method | Path | Request body | Responses (status: body) |
                      operationId is snake_case and unique, e.g. list_orders)
## Data              (Pydantic schemas with field types and constraints; SQLAlchemy
                      tables with columns, keys, and indexes)
## Acceptance criteria
- AC-01 ...
## Auth              (how a caller is identified in tests, e.g. an X-User-Id header or a
                      token helper; roles and what each may do)
## E2E seed data     (records app/seed.py creates for frontend end-to-end tests)
## Out of scope
## Definition of Done
- scripts/run_tests.sh <feature_name> exit 0
- every AC has at least one test named test_acXX_...
- no test is weakened, skipped, or xfailed
- no breaking change against contracts/openapi.json
## AC-to-test mapping
| AC | Test name | Request | Expected status + assertion |
## Open questions
