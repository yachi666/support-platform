# Workspace E2E Interaction Test Report

## Test Date

- 2026-03-12

## Environment

- Frontend URL: http://localhost:5173
- Backend URL: http://localhost:8080
- Test mode: real browser interaction against running frontend and backend
- Active workspace period during test: switched from March 2026 to April 2026

## Coverage

- Roster page staff filter
- Roster page team filter
- Workspace month switch
- Roster export button
- Import / Export Center export button
- Import template download button
- Import preview flow using `support-roster-server/src/main/resources/roster.xlsx`

## 2026-03-13 Focused Rerun

Environment:

- Startup script: `./scripts/dev/restart-all.sh`
- Frontend URL: http://127.0.0.1:5173
- Backend URL: http://127.0.0.1:8080

Executed checks:

1. Validation page in March 2026
2. Validation page in April 2026
3. Import preview upload on `/workspace/import-export`
4. Roster export on `/workspace/roster`

Observed result:

- Passed: March validation UI stayed on March and first visible issue dates were `Mar 31` to `Mar 27`
- Passed: April validation UI stayed on April and first visible issue dates were `Apr 30` to `Apr 26`
- Passed: month switch triggered `GET /api/workspace/validation?year=2026&month=4` -> `200`
- Passed: import preview upload returned `POST /api/workspace/import-export/preview` -> `200`
- Passed: preview UI reached `Validation Complete` with `roster.xlsx • 19 records parsed` and `19 valid / 240 invalid`
- Passed: roster export returned `GET /api/workspace/import-export/export?year=2026&month=4` -> `200`
- Not reproduced: March page initially showing April validation data

Assessment:

- The validation month-binding issue that was suspicious on 2026-03-12 did not reproduce in the current rerun.
- The sample import file still produces a high invalid count, but the upload and preview flow itself is functioning.
- The roster export path is functioning for the active month selected in the workspace header.

## Executed Checks

### 1. Roster filter behavior

Steps:

1. Open `/workspace/roster`
2. Enter `John` into `Filter roster staff`
3. Open `Teams (All)` filter menu
4. Select team `L1`

Observed result:

- Passed
- Staff filter reduced visible roster rows to names containing `John`
- Team filter changed button state from `Teams (All)` to `Teams (1)`
- Combined filter left `John Doe / L1 China` as the visible match in the roster grid

### 2. Workspace month switch

Steps:

1. Change workspace month from `Mar` to `Apr`
2. Confirm top bar and roster title both update
3. Confirm backend requests are re-issued for the new month

Observed result:

- Passed
- UI updated from `March 2026` to `April 2026`
- Validation badge changed from `498` to `430`
- Roster grid changed from 31-day March layout to 30-day April layout
- Backend requests observed:
  - `GET /api/workspace/validation?year=2026&month=4` -> 200
  - `GET /api/workspace/roster?year=2026&month=4` -> 200

### 3. Roster page export button

Steps:

1. Click `Export` on `/workspace/roster`

Observed result:

- Passed
- Backend request observed:
  - `GET /api/workspace/import-export/export?year=2026&month=4` -> 200
- Response headers indicated a downloadable file:
  - `content-disposition: attachment; filename=workspace-roster-2026-04.csv`
  - `content-type: text/csv;charset=UTF-8`

### 4. Import / Export Center buttons

Steps:

1. Open `/workspace/import-export`
2. Click `Export CSV`
3. Click `Download Template`

Observed result:

- Passed
- Template download request observed:
  - `GET /api/workspace/import-export/template` -> 200
- Response headers indicated a downloadable file:
  - `content-disposition: attachment; filename=import-template.xlsx`
  - `content-type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`

### 5. Import preview flow

Steps:

1. On `/workspace/import-export`, upload `support-roster-server/src/main/resources/roster.xlsx`
2. Wait for validation preview to complete
3. Stop before applying changes

Observed result:

- Passed up to preview stage
- Backend request observed:
  - `POST /api/workspace/import-export/preview` -> 200
- UI entered `Validation Complete`
- Preview summary rendered:
  - `roster.xlsx • 19 records parsed`
  - `19 valid / 240 invalid`
- No apply action was executed during this test

## Console And Browser Findings

- No frontend runtime exception was observed during this test round
- Persistent browser issue remained:
  - `No label associated with a form field`

## Suspicious Points

### 1. Roster page `Import` button appears inert

On `/workspace/roster`, clicking `Import` did not produce visible UI feedback, file chooser behavior, route change, or new network request during this session. In contrast, the dedicated `/workspace/import-export` page contains a complete and working import flow. This suggests the roster page `Import` button may be unimplemented, visually misleading, or dependent on behavior not exposed in the current UI state.

### 2. Month context and validation dates were inconsistent earlier in browser testing

Before switching the workspace period to April, the workspace was displaying `March 2026` while the validation list already contained many `Apr xx` issue dates. After explicitly switching to April, the validation count changed from `498` to `430` and the April context became internally consistent. This may indicate a mismatch between the default workspace period and the validation dataset initially bound to the page.

### 3. Sample import file yields unusually high invalid count

The bundled sample file `support-roster-server/src/main/resources/roster.xlsx` was accepted by the preview endpoint and rendered successfully, but the result was `19 valid / 240 invalid`. Because this file is stored with the project and is a natural candidate for manual verification, the ratio suggests one of the following:

- the sample file is intentionally incomplete,
- the preview rules are stricter than the example implies,
- or the sample data no longer matches the current validation model.

This is not a hard failure, but it should be reviewed because it can confuse manual testers.

### 4. Accessibility issue remains reproducible

Browser diagnostics still reported `No label associated with a form field`. This did not block functional testing, but it is a real accessibility regression and should be traced to the affected workspace form control.

## Overall Assessment

- Filtering: passed
- Month switching: passed
- Export buttons: passed
- Template download: passed
- Import preview: passed up to validation stage
- Data apply step: intentionally not executed

The core interactive flows requested for this round are functional, but the suspicious points above should be tracked before treating the workspace UI as fully regression-safe.