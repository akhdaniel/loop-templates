# Project rules: odoo-loop

## Context
- Odoo 18, custom addons live in addons/
- The spec in specs/<addon>.md is the source of truth

## Definition of done (the only one)
- Run: scripts/run_tests.sh <addon_name>
- Done ONLY when the exit code is 0 and "=== PASSED ===" is printed
- Never claim done without running it and reading the result

## Working rules
1. Start of session: read the spec and PROGRESS.md
2. Do one small piece per iteration, run the verification, then continue
3. NEVER change, delete, or weaken files in tests/
   (locked through .tests.lock). If a test looks wrong: stop,
   write it down in PROGRESS.md, and ask for human review
4. NEVER change scripts/, .tests.lock, .pylintrc, or .env.test
5. Do not add features outside the scope of the spec
6. End of every iteration: write a summary to PROGRESS.md
7. Same error 3 iterations in a row: stop and write down a hypothesis

## Odoo 18 conventions
- List views use <list>, not <tree>
- No attrs/states: use invisible="state != 'draft'"
- Forms use <chatter/>, models use _inherit = ['mail.thread']
- Every model has a line in ir.model.access.csv, plus record rules when needed
- Manifest: version 18.0.x.y.z, license, every data file listed, complete depends
- Translatable text uses self.env._('...'), not the global _()
- Errors for users: UserError / ValidationError / AccessError, never assert
- Computes and constraints must work on a NEW record in the form (onchange), where
  company_id / currency_id can still be empty. Never call currency_id.compare_amounts /
  .round / .is_zero directly; fall back first:
  `currency = rec.currency_id or (rec.company_id or self.env.company).currency_id`
  (otherwise: "ValueError: Expected singleton: res.currency()" on clicking New)
- A form only loads defaults for fields that are in the view. If company_id is shown
  with groups="base.group_multi_company", also add `<field name="company_id" invisible="1"/>`
  so related fields (currency_id) are filled for single-company users
- TransactionCase tests create records through the ORM and never run the form onchange,
  so green tests do not prove the New button works: open the form once by hand
  
## Safety rules
- Never touch any database other than db_test
- Never run rm -rf, git push, dropdb, or DROP DATABASE
  except through scripts/run_tests.sh
- Never install system packages without permission
