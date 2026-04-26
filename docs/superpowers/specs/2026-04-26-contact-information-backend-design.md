# Contact Information Backend Integration Design

## Overview

This design adds a real backend module for `contact-information`, replaces the frontend's mock-backed runtime flow with live APIs, and preserves the product's current positioning:

- the list page remains publicly readable
- creation requires login and workspace admin permission
- the current UI shape remains largely intact
- this phase delivers only list + create, not edit/delete/detail

The implementation spans:

1. `support-roster-server` backend persistence, APIs, auth enforcement, and tests
2. `support-roster-ui` frontend API wiring, list/create integration, and tests
3. local integration validation across the parent workspace

## Goals

- Persist support team contact records in PostgreSQL instead of frontend-only mock data
- Expose a public list API with server-side search and pagination
- Expose an authenticated admin-only create API
- Replace frontend runtime mock usage with real API integration
- Validate end-to-end behavior in local development

## Non-Goals

- Editing contact records
- Deleting contact records
- Record detail endpoints
- Moving the feature under the workspace shell
- Public write access
- Reworking the existing page layout or form structure beyond integration needs

## Current State

### Frontend

`support-roster-ui` currently implements:

- `/contact-information` list page
- `/contact-information/add` create page
- local filtering over `contactInformationMock.js`
- mock success flow that does not persist records

### Backend

`support-roster-server` currently has:

- Spring Boot + MyBatis-Plus + Flyway + Sa-Token
- admin-gated workspace endpoints using `AuthContextService.requireAdmin()`
- no existing `contact-information` persistence model or API

## Recommended Approach

Adopt a dedicated `contact-information` backend module with a normalized persistence model:

1. one parent table for core team contact metadata
2. child tables for tags, staff bindings, and links
3. one public read endpoint with server-side search + pagination
4. one admin-only create endpoint

This is preferred over JSON-in-one-table storage or reusing the workspace team domain because:

- it matches the frontend feature boundaries
- it keeps public contact information independent from workspace editing concerns
- it makes search/pagination and future CRUD expansion more reliable

## Architecture

### Backend module boundaries

Create a focused backend feature under a dedicated package, for example:

- `controller.contactinformation`
- `service.contactinformation`
- `dto.contactinformation`
- `entity.contactinformation`
- `mapper.contactinformation`

Each unit has one purpose:

- **controller**: HTTP contract and request parsing
- **service**: validation, auth enforcement, orchestration, and aggregation
- **mapper/entity**: persistence and query access
- **dto**: frontend-facing and request payload contracts

### Frontend boundaries

Keep the existing route/layout/component split and add:

- a small API client for contact-information requests
- request-backed state in list/create pages
- removal of runtime dependence on `contactInformationMock.js` for live data

The route-level pages remain composition surfaces:

- `SupportTeamContactsPage` orchestrates list loading/search/pagination/notices
- `SupportTeamContactCreatePage` orchestrates create submission and post-submit navigation
- presentational components remain focused on rendering and local form interaction

## Data Model

## Primary table

### `support_team_contact`

Fields:

- `id` bigint primary key
- `team_name` varchar, required
- `team_email` varchar, required, unique
- `xmatter_group` varchar, nullable
- `gsd_group` varchar, nullable
- `eim_id` varchar, nullable
- `other_info` varchar/text, nullable
- `created_at`
- `updated_at`
- `created_by_account_id` bigint, nullable
- `updated_by_account_id` bigint, nullable

Purpose:

- stores the record-level fields already modeled by the current form and table

## Child tables

### `support_team_contact_tag`

- `id`
- `contact_id`
- `tag`
- `sort_order`

### `support_team_contact_staff`

- `id`
- `contact_id`
- `staff_code`
- optional denormalized display fields are intentionally out of scope for this phase

### `support_team_contact_link`

- `id`
- `contact_id`
- `label`
- `url`
- `sort_order`

## Data rules

- `team_name` is required
- `team_email` is required and unique
- at least one tag is required
- at least one `staff_code` is required
- all submitted `staff_code` values must resolve against existing staff master data
- `other_info` is stored as a single field and is mapped back to a synthetic `Other` link in the response shape when present

## API Design

### `GET /api/contact-information`

Access:

- public

Query params:

- `keyword` optional
- `page` required, 1-based in the HTTP contract
- `pageSize` required

Behavior:

- filters by team name, team email, tag, staff code, xMatter, GSD, EIM, and link text/url
- returns paginated records ordered by a stable default, preferably newest first or name ascending; use one explicit rule and document it in server specs during implementation

Response shape:

```json
{
  "items": [
    {
      "id": 1,
      "name": "Payments Core",
      "email": "payments-core@company.com",
      "xMatter": "XM-PAY-01",
      "gsd": "GSD-PAY-882",
      "eim": "EIM-9331",
      "roles": ["Upstream", "Downstream"],
      "staff": [
        {
          "id": "S-10492",
          "name": "Alex Chen",
          "email": "alex.c@company.com",
          "avatar": null
        }
      ],
      "links": [
        {
          "label": "Other",
          "url": "https://..."
        }
      ]
    }
  ],
  "page": 1,
  "pageSize": 20,
  "total": 57
}
```

Notes:

- `staff` should provide the same shape the current table/hover card expects
- if staff master data does not contain avatar data, return `null` and let the UI gracefully render without it

### `POST /api/contact-information`

Access:

- authenticated workspace admin only

Request body:

```json
{
  "name": "Payments Core",
  "email": "payments-core@company.com",
  "xMatter": "XM-PAY-01",
  "gsd": "GSD-PAY-882",
  "eim": "EIM-9331",
  "roles": ["Upstream", "Downstream"],
  "staffIds": ["S-10492", "S-94281"],
  "links": [
    {
      "label": "Other",
      "url": "https://example.com/wiki"
    }
  ]
}
```

Behavior:

- validate required fields
- validate email format
- enforce unique `team_email`
- validate that every `staffId` exists
- write parent + child rows transactionally
- return the created aggregated record in the same shape used by the list endpoint

## Auth and Access Control

### Public list

The list endpoint must not require login.

This preserves the current public route behavior and avoids coupling read access to workspace auth.

### Admin-only create

The create endpoint should reuse the existing backend auth pattern:

- require login
- require workspace admin via `AuthContextService.requireAdmin()`

This matches current workspace write-path enforcement and avoids introducing a parallel permission model.

### Frontend route behavior

- `/contact-information` stays public
- `/contact-information/add` remains a frontend route, but submission must fail cleanly for unauthenticated/non-admin users
- implementation may additionally hide the “Add Team” action for non-admin users once current-user auth state is available; this is acceptable UX polish, not a substitute for backend enforcement

## Backend Query Strategy

Use the parent table as the pagination anchor and apply keyword filtering through joined or correlated subqueries against:

- parent metadata columns
- tag table
- staff table
- link table

Recommended pattern:

1. query matching parent IDs + total count
2. load parent rows for the current page
3. batch-load tags/staff/links for those IDs
4. aggregate in service layer into DTOs

This avoids paginating over exploded join rows and keeps response assembly predictable.

## Frontend Integration Design

### API layer

Add a dedicated contact-information API client under the existing frontend API conventions.

Required methods:

- `listContactInformation({ keyword, page, pageSize })`
- `createContactInformation(payload)`

### List page

Replace runtime mock usage with request-backed state:

- read `keyword/page/pageSize` from route query
- request server data on initial load and query changes
- render real `items` and `total`
- keep the current search UX, but move filtering to the server
- replace pagination placeholders with real pagination controls

### Create page

Replace mock success flow with live submission:

- keep current form interaction and validation shape
- submit real payload to `POST /api/contact-information`
- on success, navigate back to list and show success notice
- list page reloads from API so the created record is visible immediately
- on failure, keep form state intact and render a clear error

### Data mapping

Frontend field mapping remains:

- `roles` ⇄ tag chips
- `staffIds` ⇄ comma-separated input split into array
- `otherInfo` ⇄ `links: [{ label: 'Other', url: value }]`

This avoids a UI redesign in this phase.

## Error Handling

### Backend

Expected failure classes:

- `400 Bad Request`
  - missing required fields
  - invalid email
  - duplicate email
  - unknown `staffId`
- `401/403`
  - unauthenticated or non-admin create attempt

Use the existing global exception handling conventions rather than introducing special-case response wrappers.

### Frontend

- list load failure: show explicit error state, do not silently fall back to mock data
- create failure: preserve all entered data and display server feedback
- auth failure on create: show a clear permission-oriented error message

## Testing Strategy

### Backend tests

Cover:

1. public list returns paginated data
2. keyword search filters across parent and child fields
3. create succeeds for admin
4. create fails for duplicate email
5. create fails for invalid staff IDs
6. create fails for unauthenticated/non-admin callers

### Frontend tests

Cover:

1. list page loads from API instead of runtime mock data
2. query-driven search and pagination behavior
3. create page submits real payload mapping
4. create success redirects back with notice
5. create failure preserves form state and shows error

### Integration validation

Run local end-to-end validation across the workspace:

1. start backend and frontend
2. verify public list page loads real API data
3. sign in as workspace admin
4. create a new contact-information record
5. return to list and confirm it is visible and searchable

### Browser automation

Use the existing `automationtest` project for reusable browser validation rather than adding one-off browser scripts in the UI repo.

Minimum browser coverage for this feature:

1. public list access
2. admin create success
3. non-admin create rejection or missing create access

## Spec Update Requirements During Implementation

Because this work changes both behavior and contracts, implementation must also update:

### `support-roster-server`

- `.specs` documents for API, data model, and feature behavior
- relevant `_index.md` navigation files

### `support-roster-ui`

- `.specs/contact-information.md`
- any affected development/integration documentation
- `.specs/spec.md` if new frontend spec files are introduced

## Risks and Mitigations

### Risk: pagination over joined rows becomes incorrect

Mitigation:

- paginate by parent IDs first, aggregate children second

### Risk: public route with authenticated write causes UX mismatch

Mitigation:

- enforce admin create on backend
- reflect auth state in frontend create affordances where practical

### Risk: current frontend shape expects richer staff data than backend can provide

Mitigation:

- define a stable response DTO
- return nullable avatar fields if unavailable instead of inventing fake values

## Delivery Scope for This Phase

In scope:

- persistent storage
- public list API with server-side search + pagination
- admin-only create API
- frontend replacement of runtime mock flow
- local integration validation

Out of scope:

- edit
- delete
- detail view
- bulk import/export
- restructuring the feature under workspace

## Implementation Readiness

This design is intentionally scoped so it can flow into one implementation plan covering:

1. database migration and backend domain scaffolding
2. backend API and auth enforcement
3. frontend API integration and pagination/search wiring
4. end-to-end local validation

