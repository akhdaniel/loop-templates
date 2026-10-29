# Project rules: vue-loop

## Context
- Vue 3 + Vite + TypeScript app (Vue Router, Pinia), scaffolded with create-vue
- Each feature lives in src/features/<feature>/, with its public API in index.ts
- Routes live in src/router/ and pages in src/views/; they only import from src/features/
- The spec in specs/<feature>.md is the source of truth

## Definition of done (the only one)
- Run: scripts/run_tests.sh <feature>
- Done ONLY when the exit code is 0 and "=== PASSED ===" is printed
- Never claim done without running it and reading the result

## Working rules
1. Start of session: read the spec and PROGRESS.md
2. Do one small piece per iteration, run the verification, then continue
3. NEVER change, delete, or weaken files in __tests__/ or e2e/
   (locked through .tests.lock). If a test looks wrong: stop,
   write it down in PROGRESS.md, and ask for human review
4. NEVER change scripts/, .tests.lock, .env.test, package.json, vite/vitest config,
   tsconfig*.json, or eslint/oxlint config (also locked)
5. NEVER add npm packages. If the spec needs one that is missing: stop,
   write it down in PROGRESS.md, and ask a human to install it
6. Do not add features outside the scope of the spec
7. End of every iteration: write a summary to PROGRESS.md
8. Same error 3 iterations in a row: stop and write down a hypothesis

## Vue conventions
- Composition API with <script setup lang="ts"> only, no Options API
- Typed props and emits: defineProps<{...}>() and defineEmits<{...}>()
- Business logic in plain functions or composables (useX.ts), not in templates
- Shared state in Pinia setup stores; no module-level mutable state
- Export exactly what the spec's "Public interface" names, from src/features/<feature>/index.ts
- Use the texts and data-testid attributes the spec names; tests find elements by them
- Every v-for has a stable :key; never v-if and v-for on the same element
- Never v-html with user or API data (XSS)
- Accessibility: inputs have a <label>, icon-only buttons have aria-label,
  use real <button>/<a> elements instead of clickable <div>s
- Every page handles its loading, empty, and error states
- Network calls only through the API module the spec names (tests mock it)
- Routes are lazy-loaded: component: () => import('...')
- Everything in VITE_* env vars ships to the browser: no secrets there or in code
- TypeScript strict: no `any`, no @ts-ignore / @ts-nocheck / eslint-disable
  (the judge rejects them)
- Never write code that detects the test environment
  (import.meta.env.VITEST, process.env.VITEST, MODE === 'test'); the judge rejects it

## Safety rules
- Never run rm -rf, git push, npm publish, or any deploy command
  (vercel, netlify deploy, firebase deploy, wrangler deploy)
- Never run vitest with -u / --update (snapshots are forbidden anyway)
- Never install packages or system tools without permission
- Never use production API keys or endpoints; use only what .env.test points to
