# Contact Information Browser Automation Design

## Overview

This design defines the browser automation scope for the `contact-information` feature inside the existing `automationtest` Playwright project.

The goal is to validate the highest-value user flows with stable end-to-end coverage while keeping the suite lightweight and aligned with current project patterns.

This phase covers:

1. public list page availability
2. public search behavior
3. admin create flow
4. post-create list retrieval of the created record

This phase does not expand into pagination-specific E2E, role-matrix coverage, or visual regression.

## Goals

- Verify that `/contact-information` loads successfully for unauthenticated users
- Verify that public search can retrieve an expected record from the live backend
- Verify that an authenticated admin can create a new contact-information record through the browser
- Verify that the newly created record can be searched and found on the list page
- Record these scenarios clearly in the automation project documentation

## Non-Goals

- Dedicated browser coverage for pagination navigation
- Non-admin or unauthenticated negative submission scenarios
- Screenshot regression or visual diff testing
- Refactoring the Playwright fixture architecture
- Creating a new automation sub-framework for this feature

## Current Project Context

The automation project already contains:

- shared Playwright fixtures in `automationtest/fixtures/test.fixture.mjs`
- authenticated browser setup through `authenticatedPage`
- direct PostgreSQL cleanup helpers in `automationtest/helpers/postgres-cli.mjs`
- feature-based spec directories under `automationtest/specs/**`

The application currently exposes:

- public list route: `/contact-information`
- create route: `/contact-information/add`
- real backend integration for list and create

Existing contact-information browser coverage already includes:

- a public list smoke test
- an admin create smoke test

The requested work is to execute browser automation against the feature and solidify the relevant cases in the automation project as durable test coverage.

## Recommended Approach

Use the existing `automationtest/specs/contact-information/` directory and expand the current feature-focused specs rather than introducing a new top-level test style.

Why this approach is preferred:

- it matches the current automation project organization
- it keeps the feature coverage easy to discover
- it reuses proven fixtures, login flows, and cleanup helpers
- it avoids mixing contact-information behavior into unrelated smoke suites

## Alternatives Considered

### Option A — Extend feature-local specs in `specs/contact-information/` (recommended)

- keep `public-list.spec.mjs`
- keep `admin-create.spec.mjs`
- expand them to cover the approved regression scope

Pros:

- easiest to maintain
- closest to current repo patterns
- high signal when failures occur

Cons:

- pagination remains outside browser coverage for now

### Option B — Collapse all feature flows into one long smoke test

Pros:

- fewer files

Cons:

- harder to diagnose failures
- couples public-read and admin-write paths too tightly
- more fragile when one step flakes

### Option C — Build a dedicated page-object layer first

Pros:

- stronger long-term abstraction if the feature grows significantly

Cons:

- unnecessary for the current two-flow scope
- adds framework overhead before there is evidence it is needed

## Test Design

### Scenario 1: Public list and search

File:

- `automationtest/specs/contact-information/public-list.spec.mjs`

Behavior:

- open `/contact-information` without login
- confirm the page heading and search control are visible
- enter a stable keyword for an existing record
- verify the matching record appears in the list

Design notes:

- this scenario remains read-only
- it should not create or mutate data
- assertions should focus on user-visible behavior, not internal counts or implementation details

### Scenario 2: Admin create and post-create retrieval

File:

- `automationtest/specs/contact-information/admin-create.spec.mjs`

Behavior:

- open `/contact-information/add` with `authenticatedPage`
- submit a unique record using a generated `runId`
- verify redirect back to `/contact-information`
- verify success feedback is shown
- search for the created record on the list page
- verify the created record is visible

Design notes:

- test data must be unique per run
- cleanup must remove parent and child rows after the test completes
- cleanup must succeed even if a prior assertion fails

## Data Strategy

### Public list/search

- do not seed new data
- rely on an existing stable record already present in the environment
- use a search term that is expected to resolve consistently

### Admin create

- generate unique `teamName` and `teamEmail` values from a run-scoped id
- reuse the authenticated primary user as the staff id input
- clean up all inserted contact-information rows plus related tag, staff, and link rows

## Stability Rules

- prefer `getByRole`, `getByLabel`, and explicit text assertions
- use `{ exact: true }` where label ambiguity is possible
- avoid assertions based on CSS classes or DOM nesting
- avoid brittle assumptions such as exact result counts unless the test itself created the data
- keep each spec focused on one primary behavior chain

## Documentation Updates

Update `automationtest/README.md` so the documented first-batch cases clearly include contact-information coverage and reflect the current feature scope.

The README should make it obvious that browser automation now covers:

- public list load
- public search
- admin create
- created-record retrieval from the list

## Acceptance Criteria

- contact-information browser specs run successfully in the existing Playwright project
- the public-read path is covered by at least one stable spec
- the admin create path is covered by at least one stable spec
- created records are cleaned up after the admin scenario
- the automation README reflects the contact-information coverage

## Validation Commands

```bash
cd automationtest
npm run precheck
npx playwright test specs/contact-information
```

