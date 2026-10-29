---
description: Implement the feature until run_tests.sh passes
argument-hint: <feature_name>
---
Implement the feature $ARGUMENTS until scripts/run_tests.sh $ARGUMENTS exits 0.
Follow CLAUDE.md. Read specs/$ARGUMENTS.md, its tests in
src/features/$ARGUMENTS/__tests__/, and PROGRESS.md first.
Work in stages: types + index.ts exports, pure logic, API module + store,
components (loading/empty/error states), page in src/views/ + route in src/router/.
Run run_tests.sh after every stage and update PROGRESS.md.
