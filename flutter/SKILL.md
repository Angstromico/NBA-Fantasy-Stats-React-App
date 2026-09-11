---
name: nba-fantasy-stats-flutter
description: Engineering and architectural standards for the NBA Fantasy Stats Flutter Android project, optimized for Antigravity and Gemini models.
---

# Flutter Project Quality & Architectural Guidelines (SKILL)

This document defines the engineering standards for the Flutter port of NBA Fantasy Stats. All contributions must adhere to these rules.

## Architecture

- `lib/models/` — Dart data models (fromJson/toJson). Mirror of `src/interfaces/`.
- `lib/utils/` — Pure Dart functions: stat calculations, streaks, milestones, leaderboards. No Flutter imports.
- `lib/data/` — Static NBA data: teams, schedules, historical awards.
- `lib/widgets/` — Reusable UI widgets: `GlassCard`, `StatRow`, `StatField`, `ConfirmationDialog`, `MilestonesFlipCard`.
- `lib/screens/` — Full-page screens: `LoginScreen`, `TrackerScreen`, `SummaryScreen`, `RecordsScreen`.
- `lib/theme/` — `AppTheme`, `GlassTheme` extension, dark/light `ThemeData`.

## Coding Rules

1. **Code Clarity**: Write clean, self-describing Dart. No redundant comments.
2. **State Management**: Use `StatefulWidget` + `setState` for local UI state. For shared state, use `InheritedWidget` or a lightweight provider.
3. **Immutability**: Never mutate model fields directly. Produce new instances via `copyWith` patterns.
4. **Pure Utils**: All stat math lives in `lib/utils/`. Screens and widgets only call these functions — no calculation logic inline.
5. **Season Integrity**: Current-season comparisons use only that season's `GameStats` list. Never pass all-time career data to champion comparison widgets.
6. **Confirmation Guards**: Any destructive action (season reset, backward season navigation) must use `ConfirmationDialog.show()` before proceeding.
7. **Theme**: Always read colors from `Theme.of(context).colorScheme` and `Theme.of(context).extension<GlassTheme>()`. Never hardcode hex colors in widgets.

## Verification Checklist

- [ ] `flutter analyze` passes with no issues
- [ ] `flutter test` passes
- [ ] `dart format --set-exit-if-changed lib/` passes
- [ ] No calculation logic is inside widget `build()` methods
- [ ] All destructive actions are guarded with `ConfirmationDialog`
- [ ] Champion comparison receives only current-season games

## Commit Format

Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `style:`, `test:`, `chore:`

Examples:
- `feat(tracker): add absence type selector to game form`
- `fix(storage): handle null SharedPreferences value on first launch`
- `refactor(utils): extract milestone threshold logic into pure function`
