---
description: Implement the feature until run_tests.sh passes
agent: build
---
Implement the feature $ARGUMENTS until scripts/run_tests.sh $ARGUMENTS exits 0.
Follow AGENTS.md. Read specs/$ARGUMENTS.md, its tests in test/features/$ARGUMENTS/,
and PROGRESS.md first.
Work in stages: models + $ARGUMENTS.dart exports, pure logic, repositories,
widgets (loading/empty/error states), route/navigation wiring.
Run run_tests.sh after every stage and update PROGRESS.md.
