---
description: Write DRAFT tests from the spec (no addon code), for human review
argument-hint: <addon_name>
---
You are an Odoo 18 developer writing acceptance tests. Your job is to write DRAFT
tests for the addon $ARGUMENTS from specs/$ARGUMENTS.md.

## Constraints
- Do NOT write addon code (models, views, security, manifest, data).
- Write ONLY to drafts/$ARGUMENTS/tests/. The addons/*/tests/ folders are locked
  for agents; a human moves the drafts there after review.
- Do not use skipTest, @skip, unittest.skip, or skipIf (the judge rejects them).
- Do not create or change .tests.lock.

## Steps
1. Read CLAUDE.md, specs/$ARGUMENTS.md (especially "Acceptance criteria",
   "Security", and the "AC-to-test mapping" table), and the style examples in
   any existing addons/*/tests/.
2. If the spec has no mapping table yet, or an AC cannot be tested
   automatically, stop and name the ACs that need clarification.
3. Write drafts/$ARGUMENTS/tests/__init__.py and
   drafts/$ARGUMENTS/tests/test_$ARGUMENTS.py:
   - from odoo.tests.common import TransactionCase, tagged
   - @tagged('post_install', '-at_install') on the test class
   - setUpClass: create one user per role with the groups from the spec's Security
     section (xml id <addon_name>.group_...), using
     cls.env['res.users'].with_context(no_reset_password=True); group field
     'group_ids' if 'group_ids' in Users._fields else 'groups_id'
   - at least one test per AC, named test_acXX_<short>, in AC order
   - a small helper to create records (like _req in the examples) to keep tests short
   - every "may not" rule is tested with self.assertRaises(ValidationError /
     UserError / AccessError)
   - limits: test EXACTLY at the limit and one past the limit
   - security: call sensitive actions through .with_user(regular_user) and expect
     AccessError; record rules: a regular user cannot see another user's records
   - assertions must check real outcomes (state, field values, record counts),
     never assertTrue(True) or assertions that always pass
   - flake8 clean, max-line-length 120
4. End with a summary for the human reviewer:
   - table: AC | test name | what it proves
   - assumptions you made (group xml ids, field names, default values)
   - follow-up commands for the human:
     mkdir -p addons/$ARGUMENTS/tests
     cp drafts/$ARGUMENTS/tests/*.py addons/$ARGUMENTS/tests/
     scripts/run_tests.sh $ARGUMENTS      # new addon: must FAIL "manifest missing"
     find addons/*/tests -name '*.py' -exec sha256sum {} + > .tests.lock   # lock tests of ALL addons
     git add -A && git commit -m "test: acceptance tests $ARGUMENTS (locked)"
   Then stop. Implementation only starts after the tests are locked (/implement).
