---
description: Write DRAFT tests from the spec (no feature code), for human review
argument-hint: <feature_name>
---
You are a Flutter developer writing acceptance tests. Your job is to write DRAFT
tests for the feature $ARGUMENTS from specs/$ARGUMENTS.md.

## Constraints
- Do NOT write feature code (widgets, models, repositories, logic, routes).
- Write ONLY to drafts/$ARGUMENTS/. The test/ and integration_test/ folders are
  locked for agents; a human moves the drafts there after review.
- Do not use skip:, @Skip, solo:, markTestSkipped, or golden assertions
  (matchesGoldenFile): the judge rejects them.
- Do not create or change .tests.lock, pubspec.yaml, or analysis_options.yaml.

## Steps
1. Read CLAUDE.md, pubspec.yaml, specs/$ARGUMENTS.md (especially "Public interface",
   "Acceptance criteria", and the "AC-to-test mapping" table), and the style
   examples in any existing test/features/*/.
2. Stop and name what needs clarification if: the spec has no mapping table, an AC
   cannot be tested automatically, the "Public interface" does not name what a test
   needs (export, injectable dependency, text/Key), or a package the tests need is
   not in pubspec.yaml.
3. Write drafts/$ARGUMENTS/test/*_test.dart:
   - one file for pure logic and repositories (<feature>_logic_test.dart) and one for
     widgets/screens (<feature>_widget_test.dart), when both exist in the spec
   - import the feature ONLY through
     package:<app_name>/features/$ARGUMENTS/$ARGUMENTS.dart (app name from pubspec.yaml),
     never internal files that do not exist yet
   - API backed by a fastapi-loop backend: keep every mocked response in
     test/features/$ARGUMENTS/fixtures/<operationId>.<status>.json (operationIds from the spec) and load
     it in the mocks, so the backend can check them against its contract
   - fakes: small hand-written classes that implement the abstract dependencies from
     the spec (or mocktail, only if it is in pubspec.yaml), each test setting its own
     success/failure/delay; never real network, timers, or platform channels
   - widget tests: pump the screen inside MaterialApp (plus the providers the spec
     names) with a helper `pumpScreen(tester, {repo})`; use pumpAndSettle or pump
     with a Duration for async states; find by text, tooltip, or the Keys the spec
     names (find.text, find.byTooltip, find.byKey)
   - navigation: assert the destination screen/text appears, or use a NavigatorObserver
   - at least one test per AC, its name starting with "AC-XX", in AC order
   - every "cannot" rule is tested (message shown, submit blocked, fake NOT called)
   - limits: test EXACTLY at the limit and one past the limit
   - assertions check real outcomes (visible text, calls with exact arguments, return
     values), never expect(true, isTrue) or assertions that always pass
   - no `// ignore:` comments; must pass `flutter analyze --fatal-infos`
4. If the spec has an "E2E" section: write drafts/$ARGUMENTS/integration_test/*_test.dart
   using IntegrationTestWidgetsFlutterBinding and the same texts/Keys as the spec.
5. End with a summary for the human reviewer:
   - table: AC | test name | what it proves
   - assumptions you made (texts, Keys, fake/dependency names, default values)
   - follow-up commands for the human:
     mkdir -p test/features/$ARGUMENTS
     cp -R drafts/$ARGUMENTS/test/. test/features/$ARGUMENTS/
     cp -r drafts/$ARGUMENTS/integration_test integration_test/$ARGUMENTS   # only if E2E exists
     scripts/run_tests.sh $ARGUMENTS      # new feature: must FAIL "$ARGUMENTS.dart is missing"
     scripts/lock_tests.sh                # locks ALL tests + pubspec.yaml + analysis_options.yaml
     git add -A && git commit -m "test: acceptance tests $ARGUMENTS (locked)"
   Then stop. Implementation only starts after the tests are locked (/implement).
