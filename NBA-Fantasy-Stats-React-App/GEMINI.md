# NBA Fantasy Stats Flutter — Antigravity & Gemini Workspace Instructions

Guidelines for Google Antigravity and Gemini models working on the Flutter Android port of NBA Fantasy Stats.

## Tech Stack & Architecture
- **Framework**: Flutter 3.x with Dart, targeting Android (API 24+).
- **Styling**: Material 3, glassmorphism via `BackdropFilter` + `GlassTheme` ThemeExtension, dark mode first.
- **State**: `StatefulWidget` + `setState` for local state. `SharedPreferences` for persistence.
- **Code Organization**:
  - `lib/models/` — Dart data models with JSON serialization.
  - `lib/utils/` — Pure Dart stat calculations (no Flutter imports allowed).
  - `lib/data/` — Static NBA reference data (teams, schedules, awards).
  - `lib/widgets/` — Reusable UI components.
  - `lib/screens/` — Full navigation screens.
  - `lib/theme/` — ThemeData + GlassTheme extension.

## Development Rules
1. **Code Clarity**: Self-describing Dart code. No redundant comments.
2. **Widget State**: Declare all controllers and state at the top of `State` classes before any build logic. Never mutate model instances — produce new copies.
3. **Separation of Concerns**: Widgets call `lib/utils/` functions for calculations. No math inside `build()`.
4. **Season Integrity**: Champion comparison widgets receive only the current season's game list. Never pass career totals.
5. **Destructive Operations**: Season reset and backward season navigation must call `ConfirmationDialog.show()` with the appropriate tone (`ConfirmTone.danger` or `ConfirmTone.warning`) before executing.
6. **Quality Verification**:
   - Static analysis: `flutter analyze`
   - Tests: `flutter test`
   - Format: `dart format --set-exit-if-changed lib/`
   - Build: `flutter build apk --release`
   - Commit Format: Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `style:`, `test:`, `chore:`)
