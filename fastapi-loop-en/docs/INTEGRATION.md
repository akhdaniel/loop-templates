# Testing the API together with a frontend

This backend is built with fastapi-loop; the app is built with rn-loop (React Native),
flutter-loop, or vue-loop. Each loop has its own judge, and each judge tests its side
alone: the backend with a real database, the frontend with the API mocked. That is fast
and reliable, but it leaves one gap: **the frontend's mocks can drift from what the API
really returns**, and both judges keep passing.

Three layers close that gap, from cheap to expensive:

| Layer | Runs | Catches |
|---|---|---|
| 1. Each judge alone | every loop iteration | logic bugs on either side |
| 2. Contract | every judge run + when fixtures change | shape mismatches: renamed field, missing field, wrong type, removed endpoint |
| 3. End-to-end on a real API | before a release, or per feature with `RUN_E2E=1` | wiring: URLs, auth headers, CORS, serialization, real data |

## Layer 1: each side alone
Nothing extra to do. The backend judge calls the API through `TestClient` with a fresh
database per test. The frontend judges mock the API module named in their spec.

## Layer 2: the contract (`contracts/openapi.json`)
The contract is the hand-off between the repos. Three rules keep both sides honest.

**a. The backend publishes, and may not break it.** After a backend feature passes the
judge and has been reviewed, a human publishes and locks it:
```bash
.venv/bin/python scripts/export_openapi.py      # writes contracts/openapi.json
scripts/lock_tests.sh                            # the contract is locked like the tests
git add -A && git commit -m "api: publish contract for <feature>"
```
From then on the backend judge fails on any breaking change against it: a removed
endpoint or response field, a changed type, or a new required request field. Adding
endpoints and optional fields stays allowed.

**b. The frontend generates its types from it.** Then a contract change shows up as a
type error in the frontend's judge, instead of at runtime.
- React Native / Vue:
  `npx openapi-typescript ../api/contracts/openapi.json -o src/lib/api-types.ts`
  (a human runs this and installs `openapi-typescript`; agents may not add packages)
- Flutter: `openapi-generator-cli generate -g dart-dio -i ../api/contracts/openapi.json -o packages/api_client`,
  or hand-written models whose tests decode the fixtures below

**c. The frontend's mock data is checked against it.** In the frontend spec, name the
`operationId` behind every API call. Store each mocked response as a JSON fixture named
after it, next to the tests:
```
src/features/orders/__tests__/fixtures/list_orders.200.json     # React Native, Vue
test/features/orders/fixtures/list_orders.200.json              # Flutter
create_order.422.json   create_order.request.json               # errors, request bodies
```
Tests load these files instead of writing objects inline:
- Jest / Vitest: `import orders from './fixtures/list_orders.200.json'` then
  `vi.mocked(api.listOrders).mockResolvedValue(orders)` (or `jest.mocked(...)`)
- Flutter: a fake repository that returns
  `jsonDecode(File('test/features/orders/fixtures/list_orders.200.json').readAsStringSync())`

Check every fixture against the contract, from the backend repo:
```bash
.venv/bin/python scripts/validate_fixtures.py contracts/openapi.json ../my-app/src/features/orders/__tests__/fixtures
```
Run this when the frontend tests are locked, and again whenever the contract is
published (in CI: once per frontend repo). A failure names the fixture, the field, and
the problem, for example `items/0/total: 'abc' is not of type 'number'`.

## Layer 3: end-to-end on a real API
Start the API with a fresh, seeded test database:
```bash
scripts/serve_test.sh            # http://0.0.0.0:8000, data from app/seed.py
```
Put the seed data the E2E flows need in `app/seed.py` (`def seed(session) -> None`), and
list it in the backend spec's "E2E seed data" section so the frontend flows can rely on it.

Then point the frontend at it and turn on its E2E step:

| Frontend | `.env.test` | Address of the API | E2E tool |
|---|---|---|---|
| React Native (rn-loop) | `EXPO_PUBLIC_API_URL`, `RUN_E2E=1` | iOS simulator `http://localhost:8000`, Android emulator `http://10.0.2.2:8000` | Maestro flows in `e2e/<feature>/` |
| Flutter (flutter-loop) | `API_BASE_URL`, `RUN_E2E=1`, `DEVICE_ID` | same as React Native | `integration_test/<feature>/` |
| Vue (vue-loop) | `VITE_API_URL`, `RUN_E2E=1` | `http://localhost:8000` | Playwright specs in `e2e/<feature>/` |

A physical phone uses this machine's LAN IP (`ipconfig getifaddr en0` on macOS) and must
be on the same Wi-Fi.

Things that only break at this layer:
- **CORS (web only):** the browser blocks the API unless the frontend's origin is in
  `CORS_ORIGINS` (`.env` of the API, e.g. `["http://localhost:5173"]`). Native apps do
  not use CORS.
- **Plain HTTP on Android:** release builds block `http://`. Debug builds of Expo and
  Flutter allow it; if not, set `android:usesCleartextTraffic="true"` in the debug
  manifest only.
- **Production guard:** every judge refuses an API URL containing `prod`.

## Order of work across the two repos
1. API repo: `/spec <feature>` names the endpoints, their `operationId`s, and E2E seed data
2. API repo: `/tests`, human review + lock, `/implement` until the judge passes
3. API repo: human publishes the contract (layer 2a)
4. App repo: regenerate types (2b); `/spec <feature>` names the `operationId` behind each
   call; human adds the fixtures and validates them (2c)
5. App repo: `/tests`, human review + lock, `/implement` until its judge passes
6. Both: `scripts/serve_test.sh` in the API repo, `RUN_E2E=1` in the app repo (layer 3)
