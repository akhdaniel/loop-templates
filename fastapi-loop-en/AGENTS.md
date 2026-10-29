# Project rules: fastapi-loop

## Context
- FastAPI backend (Python 3.11+, Pydantic v2, SQLAlchemy 2.0) for mobile and web frontends
- Each feature lives in app/features/<feature>/ and exposes `router` from its __init__.py;
  app/main.py includes every feature router
- Its tests live in tests/features/<feature>/; tests/conftest.py gives each test a
  fresh database and a `client`
- contracts/openapi.json is the published API that frontends are built against
- The spec in specs/<feature>.md is the source of truth

## Definition of done (the only one)
- Run: scripts/run_tests.sh <feature>
- Done ONLY when the exit code is 0 and "=== PASSED ===" is printed
- Never claim done without running it and reading the result

## Working rules
1. Start of session: read the spec and PROGRESS.md
2. Do one small piece per iteration, run the verification, then continue
3. NEVER change, delete, or weaken files in tests/ (locked through .tests.lock).
   If a test looks wrong: stop, write it down in PROGRESS.md, and ask for human review
4. NEVER change scripts/, .tests.lock, .env.test, pyproject.toml, contracts/, or a
   reviewed spec (also locked). Only a human publishes a new contract
   Every endpoint's operation_id must appear in a spec, or the judge fails
5. NEVER add packages. If the spec needs one that is missing: stop,
   write it down in PROGRESS.md, and ask a human to add it
6. Do not add features outside the scope of the spec
7. End of every iteration: write a summary to PROGRESS.md
8. Same error 3 iterations in a row: stop and write down a hypothesis

## FastAPI conventions
- Inside a feature: router.py (endpoints), schemas.py (Pydantic request/response
  models), models.py (SQLAlchemy tables), service.py (business logic, no FastAPI imports)
- Every endpoint has an explicit operation_id (the name frontends and fixtures use),
  a response_model, and the status_code from the spec
- Request and response bodies are Pydantic models, never raw dicts or ORM objects;
  response models never contain passwords, hashes, or internal fields
- Validation in Pydantic (Field(gt=0, max_length=...)) so it shows in the contract
- Integer ids in paths and queries are bounded, e.g. Path(ge=1, le=2**63 - 1): the
  contract test sends huge numbers, and an unbounded id crashes the database driver
- Errors: raise HTTPException with the status code and detail text the spec names
  (404 not found, 409 conflict, 403 forbidden, 422 validation)
- The DB session comes from Depends(get_session); never create engines or sessions
  in a feature
- List endpoints that can grow are paginated (limit/offset or cursor, as the spec says)
- Type hints everywhere; mypy --strict must pass. No `# type: ignore`, `# noqa`,
  or `# pragma: no cover` (the judge rejects them)
- No breaking API changes: never remove or rename endpoints or response fields, never
  add required request fields to existing endpoints (the judge checks the contract)
- Never write code that detects the test environment (PYTEST_CURRENT_TEST,
  "pytest" in sys.modules); the judge rejects it
- Secrets only from environment variables through app/config.py, never in code

## Safety rules
- Never run rm -rf, git push, or any deploy command
  (fly deploy, railway up, gcloud run deploy, docker push, alembic upgrade on a real DB)
- Never touch any database other than the test database
- Never install packages or system tools without permission
