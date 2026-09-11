---
name: nba-fantasy-stats-standards
description: Engineering and architectural standards for the NBA Fantasy Stats React project, optimized for Antigravity and Gemini models.
---

# Project Quality & Architectural Guidelines (SKILL)

This document defines the engineering standards for the NBA Fantasy Stats React project. All contributions must adhere to these rules to ensure scalability, maintainability, type safety, and performance.

## 🏛️ Architectural Standards

### 1. Component & Module Organization

The project follows a modular structure separated by responsibilities:

- **`src/components/`**: UI components responsible solely for rendering, event handling, and local presentation state.
- **`src/utils/`**: Pure, deterministic business logic, statistical calculations, and record computations. Keep math and complex algorithms outside React component bodies.
- **`src/data/`**: Static datasets, reference schedules, awards, and team metadata.
- **`src/interfaces/`**: Shared TypeScript types, models, and contracts.

### 2. React State Management & Hooks

- **Single Source of Truth**: Keep state normalized and minimal. Derive values using `useMemo` or pure functions instead of duplicating state in `useState`.
- **Immutability**: Never mutate state or props directly. Always return new copies using array/object spread syntax or functional updates.
- **Rules of Hooks**: Always invoke hooks at the top level of components. Never call hooks inside loops, conditions, or after early returns.
- **Side Effects**: Restrict `useEffect` to synchronization with external systems (such as `localStorage` persistence or DOM side effects). Avoid triggering cascading state updates across effects.

## 🛠️ Coding Principles

### 1. SOLID Principles in React & TypeScript

- **S (Single Responsibility)**: Each component, custom hook, or utility function must address one specific concern.
- **O (Open/Closed)**: Design components to be extensible through composition, props, and children rather than modifying existing stable components.
- **L (Liskov Substitution)**: Shared types and sub-components must adhere to their contracted interfaces without breaking consumers.
- **I (Interface Segregation)**: Define focused, minimal prop interfaces. Components should only receive the props they directly require.
- **D (Dependency Inversion)**: High-level UI components should depend on abstractions (interfaces, utility contracts), not tightly coupled implementation details.

### 2. DRY (Don't Repeat Yourself)

- Extract repeated statistical calculations, formatting rules, and schedule lookups into `src/utils/`.
- Maintain unified season and team resolvers rather than duplicating filtering logic across views.

### 3. KISS (Keep It Simple, Stupid)

- Write concise, readable React code.
- Avoid over-engineered abstractions, deeply nested component trees, or redundant wrapper layers.
- Do not add unnecessary comments in the code; write self-describing TypeScript code with clear naming.

### 4. YAGNI (You Aren't Gonna Need It)

- Implement only the features, props, and data fields required by current active user requirements.
- Do not write speculative helper functions, placeholder state, or unused interface properties.

## 🛡️ React Best Practices & Reliability

### 1. TypeScript Strictness

- Explicitly type component props using `React.FC<Props>` or typed props definitions.
- Avoid `any` or loose casts (`as unknown as ...`). Use discriminated unions where appropriate.

### 2. Performance & Responsiveness

- **Memoization**: Wrap expensive filtering and statistical aggregations in `useMemo`.
- **Responsive Layout**: Build fluid grid and flex layouts supporting mobile and desktop screens.
- **CSS Architecture**: Use CSS variables for consistent glass-card themes, colors, and typography.

### 3. Data Integrity & Persistence

- Validate and guard `localStorage` reading with safe JSON parsing and fallback defaults.
- Ensure state progression integrity (e.g. game numbers, streak counts, playoff transitions) before committing updates.

## 🏁 Verification Checklist

- [ ] Does `bun run lint` pass without errors or warnings?
- [ ] Does `bun run build` (`tsc -b && vite build`) compile cleanly?
- [ ] Are complex calculations placed in `src/utils/` rather than inlined in UI components?
- [ ] Are state updates strictly immutable?
- [ ] Are all React Hooks called unconditionally at the top level?
- [ ] Are prop interfaces clean, focused, and free of unused fields?
- [ ] Is the code free of unnecessary comments and dead code?
