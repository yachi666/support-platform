@AGENTS.md

# Support Platform — Claude Code Guide

> Git superproject with submodules (`support-roster-server/`, `support-roster-ui/`)
> Last reviewed: 2026-07-01

## Quick start

```bash
# Run the full stack
cd support-roster-server && ./mvnw spring-boot:run  # backend → localhost:8080
cd support-roster-ui   && pnpm dev                  # frontend → localhost:5173
# Browser automation
cd automationtest && npm run precheck && npm run test:smoke
# Submodule sync
git submodule update --init --recursive && git submodule status
```

## Test commands

```bash
cd support-roster-server && ./mvnw test              # backend unit/integration tests
cd support-roster-ui     && pnpm test                # vitest
cd support-roster-ui     && pnpm lint                # eslint
cd automationtest        && npm run test:smoke       # Playwright smoke tests
cd automationtest        && npm run test             # full Playwright suite
```

## Project structure

```
support/
├── support-roster-server/   [submodule] Java / Spring Boot (port 8080)
├── support-roster-ui/       [submodule] React / Vite (port 5173)
├── automationtest/          Playwright E2E tests
├── docs/                    Documentation
└── scripts/                 Utility scripts
```

## Workflow

### Submodule operations
1. `cd <submodule>` → modify → `git commit` → `git push`
2. Back in parent: `git add <submodule>`, commit the gitlink SHA update
3. **Submodule PR merges first**, parent PR merges second

### Commit conventions
- Conventional commits: `type(scope): message` — `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `perf`
- Parent repo commits only for: submodule gitlink updates, automationtest, docs, scripts
- Feature changes always go inside submodule commits

## Hard constraints

- **NEVER modify submodule files from the parent repo** — `cd` into the submodule first
- **Spec sync is mandatory** — code and `.specs/` docs always updated in the same task
- **No ad-hoc browser scripts** — all browser automation in `automationtest/`

## Gotchas

- After `git submodule update --init`, submodules are in **detached HEAD** — normal, not an error
- `git status` shows "modified" when submodule HEAD ≠ recorded SHA — this is the gitlink diff, not content changes
- "Local is up to date" is ambiguous — check parent repo, submodule `main`, and recorded SHA separately
- Submodule `AGENTS.md` files have their own rules — read them inside the submodule

## Coding discipline

- **Think before coding** — state assumptions, surface tradeoffs, ask when unclear
- **Simplicity first** — minimum code that solves the problem, no speculative abstractions
- **Surgical changes** — touch only what the task requires; match existing style
- **Goal-driven** — define verifiable success criteria, loop until met

## Documentation index

| Document | Location | Purpose |
|----------|----------|---------|
| Root agent instructions | `@AGENTS.md` | Superproject structure, submodule workflow, automation test setup |
| Server agent instructions | `support-roster-server/AGENTS.md` | Spec maintenance, server conventions |
| UI agent instructions | `support-roster-ui/AGENTS.md` | Spec maintenance, product update logs, UI conventions |
| Server specs | `support-roster-server/.specs/` | API, domain, data, constraints, features |
| UI specs | `support-roster-ui/.specs/` | Modules, workspace, architecture, UI design |
| Automation tests | `automationtest/README.md` | Browser test setup, fixtures, lifecycle |
