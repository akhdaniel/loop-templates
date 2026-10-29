---
description: Implement the API feature until run_tests.sh passes
agent: build
---
Implement the feature $ARGUMENTS until scripts/run_tests.sh $ARGUMENTS exits 0.
Follow AGENTS.md. Read specs/$ARGUMENTS.md, its tests in tests/features/$ARGUMENTS/,
and PROGRESS.md first.
Work in stages: models.py + schemas.py, service.py (business rules), router.py with the
operationIds from the spec, include the router in app/main.py, then app/seed.py if the
spec has "E2E seed data".
Run run_tests.sh after every stage and update PROGRESS.md.
