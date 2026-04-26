# Contact Information Optional Create Fields Design

## Overview

This design changes the `contact-information` create flow so that **only `Team Name` is required**. All other fields become optional across both the UI form and the backend create API.

The goal is to align the product behavior with a lightweight data-entry workflow:

- users can create a team record with only a name
- optional metadata can be filled later or omitted entirely
- the frontend and backend keep the same validation contract
- `staffId` enrichment remains best-effort and does not require `workspace_staff` records

## Goals

- Make `Team Name` the only required field in the create form
- Allow empty `Team Email`, `Tag`, `Staff IDs`, `xMatter Group`, `GSD Group`, `EIM ID`, and `Other Information`
- Keep frontend validation and backend validation consistent
- Preserve the existing response shape and list rendering for records with partial data
- Keep browser automation coverage valid after the contract change

## Non-Goals

- Adding edit or delete support
- Redesigning the create page layout
- Introducing new placeholder defaults for missing optional data
- Backfilling existing records
- Changing public list/search behavior beyond supporting partially populated records

## Current State

### Frontend

`SupportTeamContactForm.vue` currently treats these fields as required:

- `Team Name`
- `Team Email`
- at least one `Tag`
- at least one `Staff ID`

The submit payload always includes:

- trimmed `email`
- non-empty `roles`
- non-empty `staffIds`

### Backend

`ContactInformationCreateRequest` and `ContactInformationService#createContact()` currently require:

- `name`
- `email`
- non-empty `roles`
- non-empty `staffIds`

The create service also runs email uniqueness checks unconditionally.

## Recommended Approach

Use a **contract-aligned relaxation** across both frontend and backend:

1. keep `Team Name` required everywhere
2. make all other create fields optional in both the form and API contract
3. normalize missing optional collections to empty lists
4. skip email uniqueness checks when email is blank or absent
5. keep enrichment and persistence logic tolerant of empty `staffIds`

This is preferred over frontend-only validation changes because:

- it avoids submit-time backend rejections
- it keeps API behavior explicit and predictable
- it preserves a single source of truth for create rules

## Alternatives Considered

### Option A — Relax frontend and backend together (recommended)

Pros:

- consistent UX and API behavior
- smallest long-term maintenance cost
- easiest to explain and test

Cons:

- touches both repos and the parent automation workspace

### Option B — Relax only frontend validation

Pros:

- smaller UI-only change

Cons:

- backend would still reject submissions
- creates a broken user flow
- contradicts the requested behavior

### Option C — Keep backend validation but auto-fill missing values

Pros:

- preserves current persistence assumptions

Cons:

- invents fake data users did not provide
- adds avoidable business rules
- does not match the requested “can be empty” behavior

## Design

### Frontend behavior

The create form should only block submission when `Team Name` is blank.

Field rules:

- `Team Name`: required
- `Team Email`: optional; if provided, it may remain free text or continue using the email input type, but it must not be treated as required
- `Tag`: optional
- `Staff IDs`: optional
- `xMatter Group`: optional
- `GSD Group`: optional
- `EIM ID`: optional
- `Other Information`: optional

Payload shape:

- send `email` as an empty string when omitted, or omit it only if the existing API client already strips empty strings during serialization
- send `roles` as an empty array when no tags were entered
- send `staffIds` as an empty array when no staff IDs were entered
- keep `links` empty when `Other Information` is blank

The form should continue to expose accessible validation messaging, but only for `Team Name`.

### Backend behavior

The create API should accept records with only a name and store all other fields as nullable or empty child collections.

Rules:

- `name` remains required
- `email` becomes optional
- `roles` becomes optional
- `staffIds` becomes optional
- `links` remains optional

Normalization:

- blank optional strings normalize to `null`
- missing or blank `roles` normalize to `[]`
- missing or blank `staffIds` normalize to `[]`
- missing or blank `links` normalize to `[]`

Service behavior:

- only run `ensureEmailUnique()` when a normalized email is present
- only resolve staff enrichment when `staffIds` is non-empty
- only insert tag rows when `roles` is non-empty
- only insert staff binding rows when `staffIds` is non-empty
- continue inserting the parent contact record even when all child collections are empty

### Data and rendering implications

The list page and response DTOs already tolerate sparse values reasonably well, so the change should preserve the current response shape:

- `roles` may be `[]`
- `staff` may be `[]`
- `links` may be `[]`
- `email`, `xMatter`, `gsd`, `eim` may be `null` or blank depending on current serializer behavior

No schema change is required because the parent optional fields are already nullable and the child tables are only populated when rows are inserted.

## Testing Design

### Frontend tests

Update focused form source-level tests so they assert:

- only `teamName` remains required
- `teamEmail` is no longer treated as required
- `selectedTags` and `selectedStaff` are no longer required for submit

### Backend tests

Add or update service tests so they assert:

- create succeeds when only `name` is present
- create succeeds with empty `roles` and empty `staffIds`
- create skips email uniqueness checks when email is absent

### Browser automation

Update the admin create browser spec so it exercises the relaxed contract:

- create a record with only `Team Name`
- verify save succeeds
- verify the created record is searchable from the list page

## Acceptance Criteria

- users can create a contact-information record by filling only `Team Name`
- frontend does not show required-field errors for the other inputs
- backend `POST /api/contact-information` accepts requests with empty or absent email, roles, and staffIds
- created records with sparse fields render correctly on the list page
- focused frontend tests, backend tests, and the contact-information Playwright suite all pass

## Validation Commands

```bash
cd support-roster-ui
node --test
npm run build

cd ../support-roster-server
mvn test

cd ../automationtest
npm run precheck
npx playwright test specs/contact-information
```
