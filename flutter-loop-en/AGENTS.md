# Project rules: flutter-loop

## Context
- Flutter app (Dart 3, sound null safety)
- Each feature lives in lib/features/<feature>/, with its public API exported from
  lib/features/<feature>/<feature>.dart
- Its tests live in test/features/<feature>/, optional E2E in integration_test/<feature>/
- The spec in specs/<feature>.md is the source of truth

## Definition of done (the only one)
- Run: scripts/run_tests.sh <feature>
- Done ONLY when the exit code is 0 and "=== PASSED ===" is printed
- Never claim done without running it and reading the result

## Working rules
1. Start of session: read the spec and PROGRESS.md
2. Do one small piece per iteration, run the verification, then continue
3. NEVER change, delete, or weaken files in test/ or integration_test/
   (locked through .tests.lock). If a test looks wrong: stop,
   write it down in PROGRESS.md, and ask for human review
4. NEVER change scripts/, .tests.lock, .env.test, pubspec.yaml, or
   analysis_options.yaml (also locked)
5. NEVER add packages. If the spec needs one that is missing: stop,
   write it down in PROGRESS.md, and ask a human to add it
6. Do not add features outside the scope of the spec
7. End of every iteration: write a summary to PROGRESS.md
8. Same error 3 iterations in a row: stop and write down a hypothesis

## Flutter conventions
- Inside a feature: data/ (models, repositories), logic/ (pure functions,
  controllers/notifiers), ui/ (screens, widgets)
- Export exactly what the spec's "Public interface" names from <feature>.dart
- Dependencies (repositories, clients, clock) come in through constructors or the
  state management the spec names, so tests can pass fakes. No global singletons,
  no http calls straight from widgets
- No `// ignore:` / `// ignore_for_file:` comments (the judge rejects them)
- Avoid `dynamic` and the `!` operator on data that comes from outside
- Prefer StatelessWidget and const constructors; keep build() free of side effects
- Icon-only buttons have a tooltip or Semantics label; use the Keys the spec names
- Every screen handles its loading, empty, and error states
- Dynamic lists use ListView.builder / SliverList, never a Column of mapped children
- Secrets and tokens only in flutter_secure_storage, never in SharedPreferences
- No Platform.isIOS / isAndroid branches unless the spec asks for them
- Edit android/ or ios/ only for the permission entries the spec lists
- Generated files (*.g.dart, *.freezed.dart) come from
  `dart run build_runner build`; never edit them by hand
- Never write code that detects the test environment
  (FLUTTER_TEST, Platform.environment); the judge rejects it

## Safety rules
- Never run rm -rf, git push, pub publish, shorebird release/patch, fastlane,
  or firebase deploy (shorebird patch ships code to real users)
- Never run flutter test with --update-goldens
- Never install packages or system tools without permission
- Never use production API keys or endpoints; use only what .env.test points to
