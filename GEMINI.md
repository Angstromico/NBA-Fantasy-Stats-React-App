# NBA Fantasy Stats - Antigravity & Gemini Workspace Instructions

Guidelines and standards for Google Antigravity and Gemini models working on the NBA Fantasy Stats React project.

## Tech Stack & Architecture
- **Framework**: React 18 with TypeScript and Vite.
- **Styling**: Modern CSS with glassmorphism variables, dark mode support, and fluid layouts.
- **Code Organization**:
  - `src/components/`: UI components responsible for rendering and user interactions.
  - `src/utils/`: Pure mathematical computations, statistical aggregations, and leaderboard logic.
  - `src/data/`: Static reference datasets (NBA teams, historical awards, regular/playoff schedules).
  - `src/interfaces/`: TypeScript types and contracts.

## Development Rules
1. **Code Clarity**: Write clean, self-describing TypeScript code. Do not add redundant or unnecessary comments; keep only the fundamentals.
2. **React Hooks & State**:
   - Always invoke hooks unconditionally at the top level of components before any early returns.
   - Never mutate state or props directly. Always return new copies using immutable update patterns.
   - Derive state with `useMemo` or pure functions instead of syncing duplicate state in `useState`.
3. **Separation of Concerns**:
   - Keep data processing and mathematical calculations inside `src/utils/`. Components should focus on UI rendering and event handling.
4. **Season Progression & Records Integrity**:
   - Single-season comparisons against champion awards must evaluate only the current season record, never all-time career totals.
   - When switching or selecting a season, preserve progression: the next game must resume from games already played for that team in that season.
   - Guard destructive operations (season reset, premature season advancement) with confirmation prompts.
5. **Quality Verification**:
   - Linting: `npm run lint` (`eslint .`)
   - Type Checking & Build: `npm run build` (`tsc -b && vite build`)
   - Spell Check: `npx cspell "**/*" --no-must-find-files` (add domain-specific names to `cspell.json` when necessary)
   - Commit Format: Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `style:`, `test:`, `chore:`)
