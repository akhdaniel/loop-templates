---
description: Implement the feature until run_tests.sh passes
agent: build
---
Implement the feature $ARGUMENTS until scripts/run_tests.sh $ARGUMENTS exits 0.
Follow AGENTS.md. Read specs/$ARGUMENTS.md, its tests in
src/features/$ARGUMENTS/__tests__/, and PROGRESS.md first.
Work in stages: types + index.ts exports, pure logic, API/storage modules,
components (loading/empty/error states), route in src/app/.
Run run_tests.sh after every stage and update PROGRESS.md.
