---
description: Write DRAFT tests from the spec (no feature code), for human review
argument-hint: <feature_name>
---
You are a FastAPI developer writing acceptance tests. Your job is to write DRAFT tests
for the feature $ARGUMENTS from specs/$ARGUMENTS.md.

## Constraints
- Do NOT write feature code (routers, schemas, models, services).
- Write ONLY to drafts/$ARGUMENTS/. The tests/ folder is locked for agents; a human
  moves the drafts there after review.
- Do not use pytest.skip, pytest.xfail, pytest.importorskip, or @pytest.mark.skip /
  skipif / xfail (the judge rejects them).
- Do not create or change .tests.lock, pyproject.toml, tests/conftest.py, or contracts/.

## Steps
1. Read CLAUDE.md, tests/conftest.py (the `client` and `session` fixtures),
   specs/$ARGUMENTS.md (especially "Endpoints", "Acceptance criteria", "Auth", and the
   "AC-to-test mapping" table), and the style examples in tests/features/*/.
2. Stop and name what needs clarification if: the spec has no mapping table, an AC
   cannot be tested through HTTP, or "Endpoints"/"Auth" do not say what a test needs.
3. Write drafts/$ARGUMENTS/__init__.py (empty) and drafts/$ARGUMENTS/test_$ARGUMENTS.py:
   - test through HTTP only: `client.get/post/patch/delete(...)` and check
     `response.status_code` and `response.json()`; check DB state through another
     request (or the `session` fixture when no endpoint shows it)
   - import nothing from app.features.$ARGUMENTS (it does not exist yet, and testing
     through HTTP keeps the tests independent of the code layout)
   - small helpers to build valid payloads and create records via the API, so every
     test starts from the empty database conftest gives it
   - at least one test per AC, named test_acXX_<short>, in AC order
   - every "cannot" rule is tested (status code AND that nothing changed)
   - limits: test EXACTLY at the limit and one past the limit
   - authorization: another user gets 403/404 and the record is unchanged
   - assertions check real outcomes (status, exact fields, counts), never
     `assert True` or assertions that always pass
   - fully typed (mypy --strict), ruff clean, line length 120
4. End with a summary for the human reviewer:
   - table: AC | test name | what it proves
   - assumptions you made (paths, field names, status codes, auth header)
   - follow-up commands for the human:
     mkdir -p tests/features/$ARGUMENTS
     cp drafts/$ARGUMENTS/*.py tests/features/$ARGUMENTS/
     scripts/run_tests.sh $ARGUMENTS      # new feature: must FAIL "router.py is missing"
     scripts/lock_tests.sh                # locks ALL tests + specs + pyproject.toml + contract
     git add -A && git commit -m "test: acceptance tests $ARGUMENTS (locked)"
   Then stop. Implementation only starts after the tests are locked (/implement).
