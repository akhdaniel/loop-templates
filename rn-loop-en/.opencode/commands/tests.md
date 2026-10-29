---
description: Write DRAFT tests from the spec (no feature code), for human review
agent: build
---
You are a React Native (Expo) developer writing acceptance tests. Your job is to write
DRAFT tests for the feature $ARGUMENTS from specs/$ARGUMENTS.md.

## Constraints
- Do NOT write feature code (components, hooks, logic, routes, API client).
- Write ONLY to drafts/$ARGUMENTS/. The src/features/*/__tests__/ and e2e/ folders
  are locked for agents; a human moves the drafts there after review.
- Do not use .skip, .only, .todo, xit, fit, or snapshot assertions
  (toMatchSnapshot / toMatchInlineSnapshot): the judge rejects them.
- Do not create or change .tests.lock, package.json, or any test config.

## Steps
1. Read AGENTS.md, package.json, jest.config.js, specs/$ARGUMENTS.md (especially
   "Public interface", "Acceptance criteria", and the "AC-to-test mapping" table),
   and the style examples in any existing src/features/*/__tests__/.
2. Stop and name what needs clarification if: the spec has no mapping table, an AC
   cannot be tested automatically, the "Public interface" does not name what a test
   needs (export, mocked module path, label/text), or a package the tests need is
   not in package.json.
3. Write drafts/$ARGUMENTS/__tests__/*.test.ts(x):
   - one file for pure logic (<feature>.logic.test.ts) and one for screens/components
     (<feature>.test.tsx), when both exist in the spec
   - import ONLY from '../index' (the public interface) plus the mocked modules;
     never from internal files that do not exist yet
   - import { describe, test, expect, jest } from '@jest/globals' (explicit, so tsc
     does not depend on global test types)
   - import { render, screen, userEvent, waitFor } from '@testing-library/react-native'
     (check its version in package.json: from v14 on, `render` is async: `await render(...)`)
   - query like a user: getByRole / getByLabelText / getByText; getByTestId only when
     the spec names the testID
   - API backed by a fastapi-loop backend: keep every mocked response in
     __tests__/fixtures/<operationId>.<status>.json (operationIds from the spec) and load
     it in the mocks, so the backend can check them against its contract
   - mock network/storage modules with jest.mock('<path from spec>'), and give each
     test its own resolved/rejected value; mock expo-router's useRouter and assert
     the push/replace calls; mock permission APIs for granted AND denied
   - at least one test per AC, its name starting with "AC-XX", in AC order
   - a small helper to render the screen with its default mocks to keep tests short
   - every "cannot" rule is tested (message shown, submit blocked, API NOT called)
   - limits: test EXACTLY at the limit and one past the limit
   - assertions check real outcomes (visible text, calls with exact arguments, return
     values), never expect(true).toBe(true) or assertions that always pass
   - TypeScript strict, no `any`, no @ts-ignore
4. If the spec has an "E2E" section: write drafts/$ARGUMENTS/e2e/*.yaml Maestro flows
   that use the same labels/texts as the spec.
5. End with a summary for the human reviewer:
   - table: AC | test name | what it proves
   - assumptions you made (labels, mocked module paths, default values)
   - follow-up commands for the human:
     mkdir -p src/features/$ARGUMENTS/__tests__
     cp -R drafts/$ARGUMENTS/__tests__/. src/features/$ARGUMENTS/__tests__/
     cp -r drafts/$ARGUMENTS/e2e e2e/$ARGUMENTS     # only if E2E flows exist
     scripts/run_tests.sh $ARGUMENTS      # new feature: must FAIL "index.ts is missing"
     scripts/lock_tests.sh                # locks tests of ALL features + test config
     git add -A && git commit -m "test: acceptance tests $ARGUMENTS (locked)"
   Then stop. Implementation only starts after the tests are locked (/implement).
