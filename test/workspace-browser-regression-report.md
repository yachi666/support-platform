# Workspace Browser Test Report And Regression Checklist

## Summary

- Test date: 2026-03-12
- Scope: support-roster-ui workspace admin and public viewer
- Frontend URL: http://127.0.0.1:5173
- Backend URL: http://127.0.0.1:8080
- Database: PostgreSQL database `support`
- Test mode: real browser interaction against running frontend and backend

This document captures the browser-based test session that was executed against the current workspace build. It is intended to be reused both as a point-in-time report and as a manual regression checklist.

## Retest Summary After Service Restart

- Retest date: 2026-03-12
- Retest mode: real browser interaction after restarting frontend and backend services
- Frontend URL used during retest: http://127.0.0.1:5173
- Backend URL used during retest: http://127.0.0.1:8080

Result summary:

- Passed after fix: monthly roster save for newly created staff
- Passed after fix: validation selection count and bulk action enablement
- Passed after fix: CSV export encoding for Chinese content
- Passed after fix: import preview no longer returns 500
- No workspace form-label accessibility issue was reproduced during the retest console smoke check

Retest notes:

- Services were restarted before retest to ensure browser verification used the latest code rather than stale processes.
- The backend roster API now returns workspace IDs as strings, which removed the staff ID precision-loss path observed in the initial failure.
- A non-blocking Google Fonts network timeout was still observable in browser networking, but it did not affect workspace function verification and is unrelated to the original regressions.

## Focused Regression Rerun On 2026-03-13

- Retest date: 2026-03-13
- Scope: March validation, April validation, import preview upload, monthly roster export
- Startup method: repository script `./scripts/dev/restart-all.sh`
- Frontend URL: http://127.0.0.1:5173
- Backend URL: http://127.0.0.1:8080

Result summary:

- Passed: repository restart script brought frontend and backend back up and verified readiness automatically
- Passed: March validation page matched March 2026 issue dates and counts in both browser UI and API
- Passed: April validation page matched April 2026 issue dates and counts in both browser UI and API
- Passed: import preview upload on `/workspace/import-export` completed with backend `POST /api/workspace/import-export/preview` -> `200`
- Passed: roster export on `/workspace/roster` triggered backend `GET /api/workspace/import-export/export?year=2026&month=4` -> `200`
- Not reproduced: March page showing April validation data before month switch

Observed details:

- March validation UI showed `398` critical errors and `100` notices, with first visible issue dates `Mar 31` through `Mar 27`.
- April validation UI showed `330` critical errors and `100` notices, with first visible issue dates `Apr 30` through `Apr 26`.
- Import preview used `support-roster-server/src/main/resources/roster.xlsx` under April 2026 and reached `Validation Complete` with `19 records parsed` and `19 valid / 240 invalid`.
- April roster export returned response headers `content-disposition: attachment; filename=workspace-roster-2026-04.csv` and `content-type: text/csv;charset=UTF-8`.

## Environment And Startup Notes

Preferred repository scripts from the workspace root:

```bash
./scripts/dev/restart-all.sh
```

Optional foreground commands:

```bash
./scripts/dev/start-backend.sh
./scripts/dev/start-frontend.sh
```

### Frontend

Run from `support-roster-ui`:

```bash
npm run dev -- --host 127.0.0.1
```

Expected URL:

```text
http://127.0.0.1:5173
```

### Backend

Run from `support-roster-server`.

Use `127.0.0.1` for the database host in this environment. The default `localhost` setting failed here because JDBC hostname resolution for `localhost` did not work during startup.

```bash
DB_URL=jdbc:postgresql://127.0.0.1:5432/support \
DB_USERNAME=lzn \
DB_PASSWORD=123456 \
mvn spring-boot:run
```

Health check:

```bash
curl http://127.0.0.1:8080/actuator/health
```

Expected response:

```json
{"groups":["liveness","readiness"],"status":"UP"}
```

## Seed Data

### Existing seed data

The workspace already had usable data in PostgreSQL before browser testing:

- 3 role groups
- 3 teams
- 5 staff
- 4 shift definitions
- 16 roster assignments for March 2026

Optional seed import command:

```bash
psql -d support -f test-data.sql
```

Note: rerunning the SQL may produce duplicate primary key errors if the seed data already exists.

### Test data created during this browser session

The following records were created successfully through the UI and confirmed in the database:

1. Staff
   - `staff-qa-001`
   - Name: `测试人员A`
   - Role group: `技术支持组`
2. Shift definition
   - Code: `QA-NIGHT`
   - Meaning: `质量夜班`
   - Role group: `技术支持组`
3. Team
   - `team-qa-001`
   - Name: `QA 支援组`

DB verification command:

```bash
psql -d support -c "SELECT staff_code, name, role_group_id FROM workspace_staff WHERE staff_code='staff-qa-001'; SELECT code, meaning, role_group_id FROM workspace_shift_definition WHERE code='QA-NIGHT'; SELECT team_code, name FROM workspace_team WHERE team_code='team-qa-001';"
```

## Files Used During Testing

- UI app: `support-roster-ui`
- API app: `support-roster-server`
- Sample import file: `support-roster-server/src/main/resources/roster.xlsx`
- Seed SQL: `test-data.sql`

## Executed Test Cases

### 1. Workspace Overview loads

Steps:

1. Open `/workspace`
2. Confirm overview cards render
3. Confirm validation count and overview API requests return successfully

Actual result:

- Passed

Notes:

- Overview page loaded successfully.
- Validation count was high and changed after creating additional test data.

### 2. Staff creation via Staff Directory

Steps:

1. Open `/workspace/staff`
2. Click `Add Staff`
3. Fill in a new valid staff record
4. Submit the form
5. Confirm the new record appears in the list and persists in PostgreSQL

Actual result:

- Passed

Created record:

- `staff-qa-001 / 测试人员A`

### 3. Shift definition creation via Shift Definitions

Steps:

1. Open `/workspace/shifts`
2. Click `New Shift Code`
3. Create a new shift using role group `技术支持组`
4. Submit the form
5. Confirm the new shift appears in the table

Actual result:

- Passed

Created record:

- `QA-NIGHT / 质量夜班`

### 4. Team creation via Team Mapping

Steps:

1. Open `/workspace/teams`
2. Click `Create Team Group`
3. Create a new team and bind `技术支持组`
4. Submit the form
5. Confirm the team appears in both team list and dashboard preview

Actual result:

- Passed

Created record:

- `team-qa-001 / QA 支援组`

### 5. Monthly roster load

Steps:

1. Open `/workspace/roster`
2. Confirm March 2026 grid loads
3. Confirm existing seeded assignments are visible
4. Confirm new team and new staff appear in the roster grid

Actual result:

- Passed

Notes:

- Existing March data rendered correctly.
- New team `QA 支援组` appeared.
- New staff `测试人员A` appeared under `Alpha 团队`.

### 6. Monthly roster save for newly created staff

Steps:

1. Open `/workspace/roster`
2. Click `测试人员A`
3. Assign shift `QA-NIGHT` on March 1
4. Click `Apply`
5. Click `Save Changes`

Actual result:

- Failed

Observed behavior:

- UI showed `You have unsaved changes`
- Save request failed
- Backend returned 404 with message:

```text
Staff not found with id: '2032003096349692000'
```

Captured failing API call:

- `POST /api/workspace/roster/save`

Request body:

```json
{"year":2026,"month":3,"updates":[{"staffId":2032003096349692000,"day":1,"shiftCode":"QA-NIGHT"}]}
```

Response:

```json
{"status":404,"error":"Not Found","message":"Staff not found with id: '2032003096349692000'","path":"/api/workspace/roster/save"}
```

Assessment:

- New staff creation works
- New staff participation in roster save flow is broken
- Likely a staff ID mapping or serialization problem between staff creation result and roster save payload

### 7. Validation Center load

Steps:

1. Open `/workspace/validation`
2. Confirm issues load for current month
3. Confirm rows render with severity, description, team, and date

Actual result:

- Passed

Notes:

- Validation Center loaded 111 issues during this session.
- Most visible items were `Missing Primary Coverage` warnings for `Alpha 团队`.

### 8. Validation selection and resolve action

Steps:

1. Open `/workspace/validation`
2. Tick a single row checkbox
3. Observe the `Resolve Selected` button state and count

Actual result:

- Failed

Observed behavior:

- Row checkbox became checked
- Top action button still showed `Resolve Selected (0)`
- Button remained disabled

Assessment:

- UI selection state is not wired correctly into the batch action count or enablement state

### 9. Export current roster

Steps:

1. Open `/workspace/import-export`
2. Click `Export CSV`
3. Inspect response headers and returned CSV content

Actual result:

- Partially passed

Observed behavior:

- Export request returned 200
- Attachment filename was `workspace-roster-2026-03.csv`
- CSV content downloaded successfully
- Chinese characters in names and notes were garbled

Observed response header:

```text
content-type: text/csv
```

Assessment:

- Export endpoint works
- CSV encoding is incorrect or charset metadata is missing

### 10. Import preview using sample Excel

Steps:

1. Open `/workspace/import-export`
2. Upload `support-roster-server/src/main/resources/roster.xlsx`
3. Wait for preview / validation stage

Actual result:

- Failed

Observed behavior:

- `POST /api/workspace/import-export/preview` returned 500

Server error summary:

```text
column "payload_json" is of type jsonb but expression is of type character varying
```

Error context from response:

```text
The error may exist in com/support/server/supportrosterserver/mapper/ImportRecordMapper.java
The error may involve ImportRecordMapper.insert-Inline
```

Assessment:

- Import preview flow is blocked by incorrect JSONB persistence handling in the backend mapper

### 11. Public viewer reflects team data

Steps:

1. Open `/viewer`
2. Confirm teams and active shifts render
3. Confirm newly created team appears

Actual result:

- Passed

Notes:

- Existing teams rendered correctly.
- `QA 支援组` appeared in the viewer with `0 active shifts`.

## Restarted Retest Results

This section records the second end-to-end verification run that was executed after restarting both services and reloading the browser against the latest backend and frontend code.

### A. Monthly roster save for newly created staff

Retest steps:

1. Restart backend and frontend services
2. Open `/workspace/roster`
3. Click `测试人员A`
4. Assign shift `QA-NIGHT` on March 1
5. Click `Apply`
6. Click `Save Changes`

Retest result:

- Passed

Verified behavior:

- `POST /api/workspace/roster/save` returned `200`
- Request completed with string-form workspace IDs instead of precision-losing numeric IDs
- The unsaved state banner disappeared after save
- Database verification confirmed the saved assignment

DB verification result:

```text
assignment_date | shift_code |  staff_code  |   name
-----------------+------------+--------------+-----------
2026-03-01      | QA-NIGHT   | staff-qa-001 | 测试人员A
```

### B. Validation selection and resolve button state

Retest steps:

1. Open `/workspace/validation`
2. Tick a single visible row checkbox
3. Observe the selected count and action button state

Retest result:

- Passed

Verified behavior:

- Row checkbox became checked
- Top action button changed from `Resolve Selected (0)` to `Resolve Selected (1)`
- Button became enabled

### C. CSV export encoding

Retest steps:

1. Open `/workspace/import-export`
2. Click `Export CSV`
3. Verify export request succeeds
4. Inspect exported file encoding

Retest result:

- Passed

Verified behavior:

- Frontend export request returned `200`
- Exported file started with UTF-8 BOM bytes `EF BB BF`
- Exported file MIME was reported as `text/csv; charset=utf-8`
- Chinese content encoding path is now correct for spreadsheet consumers

Encoding verification output:

```text
00000000: efbb bf6e 616d 652c 7374 6166 665f 6964  ...name,staff_id
/tmp/workspace-roster.csv: text/csv; charset=utf-8
```

### D. Import preview using sample Excel

Retest steps:

1. Open `/workspace/import-export`
2. Upload `support-roster-server/src/main/resources/roster.xlsx`
3. Wait for preview validation response

Retest result:

- Passed

Verified behavior:

- `POST /api/workspace/import-export/preview` returned `200`
- Page rendered `Validation Complete`
- A preview batch ID was returned successfully
- Validation issues were rendered in the UI instead of a backend 500 error

Observed response summary:

```text
batchId: 2032034253434912769
status: INVALID
totalRecords: 61
validRecords: 51
invalidRecords: 353
```

### E. Console and accessibility smoke check

Retest scope:

1. Review browser console during the restarted retest flow
2. Revisit workspace pages touched by the original regressions

Retest result:

- Passed with minor external-network noise

Verified behavior:

- No workspace `No label associated with a form field` issue was reproduced during the restarted retest
- No blocking console errors were present on the final retest pages
- A Google Fonts request timeout remained visible in network activity, but it did not affect product behavior and is not a workspace form semantics defect

## Issues Found

### High priority

1. Roster save fails for newly created staff
   - Endpoint: `POST /api/workspace/roster/save`
   - Error: `Staff not found with id: '2032003096349692000'`
   - Impact: newly created staff cannot be scheduled
   - Current status after restarted retest: resolved

2. Import preview fails with 500
   - Endpoint: `POST /api/workspace/import-export/preview`
   - Error: JSONB column receives string instead of JSONB-compatible value
   - Impact: import flow is unusable
   - Current status after restarted retest: resolved

### Medium priority

3. Validation page selection state is broken
   - Row checkbox changes visually, but selected count remains 0
   - Impact: bulk resolve action cannot be exercised from the UI
   - Current status after restarted retest: resolved

4. Exported CSV contains garbled Chinese text
   - Endpoint: `GET /api/workspace/import-export/export?year=2026&month=3`
   - Impact: downloaded report is not readable for non-ASCII content
   - Current status after restarted retest: resolved

### Low priority

5. Accessibility and form semantics issues reported in browser console
   - Missing `id` or `name` on form fields
   - Missing label association on some inputs
   - Current status after restarted retest: not reproduced in workspace console smoke check

## Manual Regression Checklist

Use this section for repeat testing after code changes.

### Startup

- [ ] PostgreSQL `support` database is reachable
- [ ] `./scripts/dev/restart-all.sh` completes successfully
- [ ] Backend starts successfully with `127.0.0.1` DB host
- [ ] `GET /actuator/health` returns `UP`
- [ ] Frontend starts successfully on `http://127.0.0.1:5173`

### Seed and test data

- [ ] Base workspace seed data exists for role groups, teams, staff, shift definitions, and March assignments
- [ ] `staff-qa-001` can be created or already exists
- [ ] `QA-NIGHT` can be created or already exists
- [ ] `team-qa-001` can be created or already exists

### Workspace overview

- [ ] `/workspace` loads without API errors
- [ ] Overview cards render
- [ ] Validation summary loads

### Staff directory

- [ ] `/workspace/staff` loads list successfully
- [ ] Add staff drawer opens
- [ ] New staff creation succeeds
- [ ] New staff appears in list

### Shift definitions

- [ ] `/workspace/shifts` loads list successfully
- [ ] New shift drawer opens
- [ ] New shift creation succeeds
- [ ] New shift appears in list

### Team mapping

- [ ] `/workspace/teams` loads existing teams
- [ ] New team drawer opens
- [ ] Role group selection works
- [ ] Team creation succeeds
- [ ] New team appears in preview section

### Monthly roster

- [ ] `/workspace/roster` loads current month grid
- [ ] Existing seeded assignments render
- [ ] Newly created staff appears in grid
- [ ] Newly created shift appears in assignment drawer
- [ ] Saving assignment for newly created staff succeeds
- [ ] No 404 is returned from `/api/workspace/roster/save`

### Validation center

- [ ] `/workspace/validation` loads issues successfully
- [ ] Row selection updates selected count
- [ ] `Resolve Selected` enables when issues are selected
- [ ] Resolve request succeeds when applicable

### Import / export

- [ ] CSV export returns 200
- [ ] Exported CSV preserves Chinese characters correctly
- [ ] Uploading `support-roster-server/src/main/resources/roster.xlsx` succeeds
- [ ] Import preview completes without 500
- [ ] Apply import step becomes available when preview succeeds

### Public viewer

- [ ] `/viewer` loads successfully
- [ ] Team list renders
- [ ] Existing active shifts render
- [ ] Newly created visible team appears

### Console and a11y smoke checks

- [ ] No blocking console errors are present on workspace pages
- [ ] Form fields have valid `id` or `name`
- [ ] Inputs are associated with labels

## Recommended Fix Verification Order

1. Fix roster save for newly created staff and rerun monthly roster tests
2. Fix import preview JSONB persistence and rerun import flow
3. Fix validation selection state and rerun batch action checks
4. Fix CSV export encoding and recheck non-ASCII content
5. Clean up accessibility warnings and rerun console smoke checks