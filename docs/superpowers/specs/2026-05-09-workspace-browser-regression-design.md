# Workspace browser regression design

## Problem

We fixed six workspace/viewer regressions in code, but they are currently protected mostly by unit and service tests. We need browser-level coverage in `automationtest/` so future regressions are caught from the user workflow perspective.

Covered issues:

1. Workspace export includes the `name` column.
2. Shift definitions handle long shift codes without breaking the list UI.
3. Validation Center multi-select enables bulk actions for cleanup/remediation issues.
4. Validation Center "Open related area" jumps directly to the target record and reveals it.
5. Cleanup confirmation shows record-level details before deletion.
6. Viewer shows shifts when `visible=true` even if `primaryShift=false`.

## Goals

- Add browser regression coverage for all six issues.
- Keep the suite aligned with the existing `automationtest` structure.
- Prefer API-driven data setup and use DB seeding only for states that cannot be created reliably through public/workspace APIs.
- Make failures easy to localize by grouping related scenarios instead of creating one oversized end-to-end flow.

## Non-goals

- Rebuild the automation test architecture.
- Replace existing unit/service regressions.
- Add broad visual diff testing or generic layout snapshots.

## Recommended approach

Split the new browser regressions into three topic-aligned buckets:

1. Extend `specs/workspace/validation-regression.spec.mjs`
2. Extend `specs/workspace/validation-cleanup-regression.spec.mjs`
3. Add one new themed spec for export + shift definitions + viewer visibility

This keeps validation behavior with the existing validation suite while isolating the non-validation regressions into one additional spec.

## Alternatives considered

### Option A: Three topic-aligned specs (recommended)

- Pros: matches current suite structure, easier failure diagnosis, good reuse of existing helpers.
- Cons: requires a small amount of page-object/helper expansion across multiple files.

### Option B: One large "six regressions" spec

- Pros: single entry point.
- Cons: harder to debug, more brittle state chain, slower reruns after failures.

### Option C: One spec per bug

- Pros: strongest isolation.
- Cons: too much repeated login/seed/navigation boilerplate and too many tiny files for closely related behaviors.

## Test structure

### 1. Validation regression spec

File: `automationtest/specs/workspace/validation-regression.spec.mjs`

Add coverage for:

- multi-select including cleanup/remediation-capable issues in bulk action enablement
- "Open related area" jumping to:
  - staff directory target row
  - shift definitions target row
  - monthly roster target cell

Browser assertions:

- bulk action button becomes enabled after selecting visible issues
- target page URL keeps workspace query and adds focus query
- target row/cell is visible and highlighted
- related drawer/detail state opens when expected

### 2. Validation cleanup regression spec

File: `automationtest/specs/workspace/validation-cleanup-regression.spec.mjs`

Add coverage for:

- cleanup modal shows record title, subtitle, and description
- selecting multiple cleanup issues enables the bulk cleanup path
- bulk cleanup executes sequentially and clears the seeded issues

Browser assertions:

- remediation preview modal lists record detail content
- confirmation action is enabled for multiple cleanup issues
- success toast appears and validation list recomputes to the expected remaining count

### 3. Export / shift / viewer regression spec

New file: `automationtest/specs/workspace/export-shift-viewer-regression.spec.mjs`

Add coverage for:

- export workbook includes `name` header and row data
- shift definitions page renders a long code safely and still allows opening the detail drawer
- viewer includes a shift whose definition is `visible=true` and `primaryShift=false`

Browser assertions:

- downloaded workbook contains `staff_id`, `team`, `name`, and day columns in the expected order
- long shift code text is visible from the user perspective and the row remains operable
- viewer page shows the seeded non-primary visible shift

## Data setup design

### Preferred setup

- Use `workspaceApi` for team/staff/shift/roster creation whenever possible.
- Reuse existing seed contracts and extend their returned metadata rather than inventing a second seeding model.
- Keep all cleanup logic inside `CleanupRegistry`.

### Required DB seeding

Some cleanup regressions still require direct DB seeding because they represent corrupted historical states:

- orphan assignment
- invalid team scope

Those should continue to be created through the existing `seedValidationCleanupScenario` pattern and removed through registered cleanup steps.

### Export workbook inspection

Add a helper under `automationtest/helpers/` to parse the downloaded workbook and expose simple cell/header assertions so workbook parsing logic does not live inline inside a spec.

## Page object changes

Keep changes minimal and scenario-driven:

- `ValidationPage`
  - bulk cleanup selection + action helpers
  - remediation detail assertions
  - "open related area" helpers
- `RosterPage`
  - targeted cell visibility/highlight assertion
- `StaffDirectoryPage`
  - focused row visibility/highlight assertion
- `ShiftDefinitionsPage`
  - focused row visibility/highlight assertion
- Viewer page object
  - assertion for a visible non-primary shift row/card

Only add methods that are required by these regressions.

## Commands and regression entry points

- Existing validation-focused rerun path:
  - `cd automationtest && npm run test:validation:raw`
- New targeted rerun path:
  - `cd automationtest && npx playwright test specs/workspace/export-shift-viewer-regression.spec.mjs`
- Full smoke/combined verification can continue to use existing project commands once the new spec is included.

README updates should reflect the new spec under Coverage / Current Specs.

## Error handling and reliability

- Use `expect.poll` only where backend recomputation is asynchronous.
- Prefer stable semantic locators and existing page-object APIs over CSS-heavy selectors.
- Avoid depending on hand-prepared mutable local data.
- Ensure every seeded record has cleanup registration at creation time.

## Success criteria

- All six regressions are covered by browser tests.
- The suite remains organized around existing validation/workspace themes.
- New tests are runnable in isolation.
- When a test fails, the failing area is obvious: validation flow, cleanup flow, or export/shift/viewer flow.
