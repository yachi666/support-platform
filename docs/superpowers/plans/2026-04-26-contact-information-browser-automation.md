# Contact Information Browser Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the existing Playwright automation project so `contact-information` has durable browser coverage for public list/search and admin create plus post-create retrieval.

**Architecture:** Keep all work inside the existing `automationtest/specs/contact-information/` feature slice. Reuse the current shared fixtures, authenticated browser context, route helpers, and PostgreSQL cleanup helper instead of introducing new framework layers. Document the resulting feature coverage in `automationtest/README.md`.

**Tech Stack:** Playwright, Node.js, existing `automationtest` fixtures/helpers, PostgreSQL cleanup via `psql`

---

## File Structure

**Files to modify**

- `automationtest/specs/contact-information/public-list.spec.mjs` — expand the public smoke test into a stable public list + search regression
- `automationtest/specs/contact-information/admin-create.spec.mjs` — keep the admin create flow stable and verify created-record retrieval
- `automationtest/README.md` — document the exact contact-information browser coverage now provided

**Files to verify during implementation**

- `automationtest/fixtures/test.fixture.mjs` — confirm `authenticatedPage` remains sufficient
- `automationtest/helpers/route-assertions.mjs` — reuse `gotoApp`
- `automationtest/helpers/postgres-cli.mjs` — reuse cleanup helpers
- `automationtest/package.json` — use existing `precheck` and Playwright commands

### Task 1: Expand the public list spec to cover search

**Files:**
- Modify: `automationtest/specs/contact-information/public-list.spec.mjs`
- Test: `automationtest/specs/contact-information/public-list.spec.mjs`

- [ ] **Step 1: Write the failing test assertion for public search behavior**

```javascript
import { test, expect } from '../../fixtures/test.fixture.mjs'
import { gotoApp } from '../../helpers/route-assertions.mjs'

test.describe('contact information public list', () => {
  test('public contact information list loads without login and supports search', async ({ page }) => {
    await gotoApp(page, '/contact-information')

    await expect(page.getByRole('heading', { name: 'System Teams' })).toBeVisible()
    await expect(page.getByLabel('Search teams, staff IDs, or links')).toBeVisible()
    await expect(page.getByText(/Showing \d+ to \d+ of \d+ entries/)).toBeVisible()

    await page.getByLabel('Search teams, staff IDs, or links').fill('Payments Core')
    await expect(page.getByRole('cell', { name: 'Payments Core' })).toBeVisible()
  })
})
```

- [ ] **Step 2: Run the single public-list spec to verify it fails**

Run:

```bash
cd automationtest
npx playwright test specs/contact-information/public-list.spec.mjs
```

Expected:

- FAIL because the current spec only checks initial page load and does not yet include the search step/assertion

- [ ] **Step 3: Implement the minimal public-search coverage**

```javascript
import { test, expect } from '../../fixtures/test.fixture.mjs'
import { gotoApp } from '../../helpers/route-assertions.mjs'

test.describe('contact information public list', () => {
  test('public contact information list loads without login and supports search', async ({ page }) => {
    await gotoApp(page, '/contact-information')

    await expect(page.getByRole('heading', { name: 'System Teams' })).toBeVisible()
    const searchInput = page.getByLabel('Search teams, staff IDs, or links')
    await expect(searchInput).toBeVisible()
    await expect(page.getByText(/Showing \d+ to \d+ of \d+ entries/)).toBeVisible()

    await searchInput.fill('Payments Core')
    await expect(page.getByRole('cell', { name: 'Payments Core' })).toBeVisible()
  })
})
```

- [ ] **Step 4: Run the spec again to verify it passes**

Run:

```bash
cd automationtest
npx playwright test specs/contact-information/public-list.spec.mjs
```

Expected:

- PASS for the public list + search scenario

- [ ] **Step 5: Commit the public-search browser coverage**

```bash
git add automationtest/specs/contact-information/public-list.spec.mjs
git commit -m "test: cover public contact information search"
```

### Task 2: Harden the admin create spec around created-record retrieval

**Files:**
- Modify: `automationtest/specs/contact-information/admin-create.spec.mjs`
- Test: `automationtest/specs/contact-information/admin-create.spec.mjs`

- [ ] **Step 1: Write the failing assertion for created-record retrieval after redirect**

```javascript
import { test, expect } from '../../fixtures/test.fixture.mjs'
import { requirePrimaryUser } from '../../config/env.mjs'
import { escapeSqlLiteral, executeSql } from '../../helpers/postgres-cli.mjs'
import { gotoApp } from '../../helpers/route-assertions.mjs'

test.describe('contact information admin create', () => {
  test('admin can create a contact information record and find it on the list page', async ({ authenticatedPage, cleanupRegistry }) => {
    const primaryUser = requirePrimaryUser()
    const runId = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`
    const teamName = `AUTOTEST Contact ${runId}`
    const teamEmail = `autotest-contact-${runId}@example.test`
    const otherInfoUrl = `https://example.test/contact/${runId}`

    cleanupRegistry.add(`delete-contact-information-${runId}`, async () => {
      const escapedEmail = escapeSqlLiteral(teamEmail)
      await executeSql(`
        DELETE FROM support_team_contact_link
        WHERE contact_id IN (
          SELECT id
          FROM support_team_contact
          WHERE deleted = 0
            AND LOWER(BTRIM(team_email)) = LOWER(BTRIM('${escapedEmail}'))
        );
        DELETE FROM support_team_contact_staff
        WHERE contact_id IN (
          SELECT id
          FROM support_team_contact
          WHERE deleted = 0
            AND LOWER(BTRIM(team_email)) = LOWER(BTRIM('${escapedEmail}'))
        );
        DELETE FROM support_team_contact_tag
        WHERE contact_id IN (
          SELECT id
          FROM support_team_contact
          WHERE deleted = 0
            AND LOWER(BTRIM(team_email)) = LOWER(BTRIM('${escapedEmail}'))
        );
        DELETE FROM support_team_contact
        WHERE deleted = 0
          AND LOWER(BTRIM(team_email)) = LOWER(BTRIM('${escapedEmail}'));
      `)
    })

    await gotoApp(authenticatedPage, '/contact-information/add')

    await authenticatedPage.getByLabel('Team Name').fill(teamName)
    await authenticatedPage.getByLabel('Team Email').fill(teamEmail)
    await authenticatedPage.getByLabel('xMatter Group').fill(`XM-${runId.slice(-6).toUpperCase()}`)
    await authenticatedPage.getByLabel('GSD Group').fill(`GSD-${runId.slice(-6).toUpperCase()}`)
    await authenticatedPage.getByLabel('EIM ID').fill(`EIM-${runId.slice(-4)}`)
    await authenticatedPage.getByLabel('Tag').fill('Upstream')
    await authenticatedPage.keyboard.press('Enter')
    await authenticatedPage.getByLabel('Staff IDs', { exact: true }).fill(primaryUser.staffId)
    await authenticatedPage.getByLabel('Other Information').fill(otherInfoUrl)
    await authenticatedPage.getByRole('button', { name: 'Save Team' }).click()

    await expect(authenticatedPage).toHaveURL(/\/contact-information(?:\?|$)/)
    await expect(authenticatedPage.getByText('Team saved successfully.')).toBeVisible()

    await authenticatedPage.getByLabel('Search teams, staff IDs, or links').fill(teamName)
    await expect(authenticatedPage.getByRole('cell', { name: teamName })).toBeVisible()
    await expect(authenticatedPage.getByRole('link', { name: 'Other' })).toBeVisible()
  })
})
```

- [ ] **Step 2: Run the single admin-create spec to verify it fails if retrieval coverage is missing**

Run:

```bash
cd automationtest
npx playwright test specs/contact-information/admin-create.spec.mjs
```

Expected:

- FAIL if the spec still stops at submit success without asserting list retrieval

- [ ] **Step 3: Implement the minimal retrieval-focused version of the spec**

```javascript
import { test, expect } from '../../fixtures/test.fixture.mjs'
import { requirePrimaryUser } from '../../config/env.mjs'
import { escapeSqlLiteral, executeSql } from '../../helpers/postgres-cli.mjs'
import { gotoApp } from '../../helpers/route-assertions.mjs'

test.describe('contact information admin create', () => {
  test('admin can create a contact information record and find it on the list page', async ({ authenticatedPage, cleanupRegistry }) => {
    const primaryUser = requirePrimaryUser()
    const runId = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`
    const teamName = `AUTOTEST Contact ${runId}`
    const teamEmail = `autotest-contact-${runId}@example.test`
    const otherInfoUrl = `https://example.test/contact/${runId}`

    cleanupRegistry.add(`delete-contact-information-${runId}`, async () => {
      const escapedEmail = escapeSqlLiteral(teamEmail)
      await executeSql(`
        DELETE FROM support_team_contact_link
        WHERE contact_id IN (
          SELECT id
          FROM support_team_contact
          WHERE deleted = 0
            AND LOWER(BTRIM(team_email)) = LOWER(BTRIM('${escapedEmail}'))
        );
        DELETE FROM support_team_contact_staff
        WHERE contact_id IN (
          SELECT id
          FROM support_team_contact
          WHERE deleted = 0
            AND LOWER(BTRIM(team_email)) = LOWER(BTRIM('${escapedEmail}'))
        );
        DELETE FROM support_team_contact_tag
        WHERE contact_id IN (
          SELECT id
          FROM support_team_contact
          WHERE deleted = 0
            AND LOWER(BTRIM(team_email)) = LOWER(BTRIM('${escapedEmail}'))
        );
        DELETE FROM support_team_contact
        WHERE deleted = 0
          AND LOWER(BTRIM(team_email)) = LOWER(BTRIM('${escapedEmail}'));
      `)
    })

    await gotoApp(authenticatedPage, '/contact-information/add')

    await authenticatedPage.getByLabel('Team Name').fill(teamName)
    await authenticatedPage.getByLabel('Team Email').fill(teamEmail)
    await authenticatedPage.getByLabel('xMatter Group').fill(`XM-${runId.slice(-6).toUpperCase()}`)
    await authenticatedPage.getByLabel('GSD Group').fill(`GSD-${runId.slice(-6).toUpperCase()}`)
    await authenticatedPage.getByLabel('EIM ID').fill(`EIM-${runId.slice(-4)}`)
    await authenticatedPage.getByLabel('Tag').fill('Upstream')
    await authenticatedPage.keyboard.press('Enter')
    await authenticatedPage.getByLabel('Staff IDs', { exact: true }).fill(primaryUser.staffId)
    await authenticatedPage.getByLabel('Other Information').fill(otherInfoUrl)
    await authenticatedPage.getByRole('button', { name: 'Save Team' }).click()

    await expect(authenticatedPage).toHaveURL(/\/contact-information(?:\?|$)/)
    await expect(authenticatedPage.getByText('Team saved successfully.')).toBeVisible()

    const searchInput = authenticatedPage.getByLabel('Search teams, staff IDs, or links')
    await searchInput.fill(teamName)
    await expect(authenticatedPage.getByRole('cell', { name: teamName })).toBeVisible()
    await expect(authenticatedPage.getByRole('link', { name: 'Other' })).toBeVisible()
  })
})
```

- [ ] **Step 4: Run the spec again to verify it passes**

Run:

```bash
cd automationtest
npx playwright test specs/contact-information/admin-create.spec.mjs
```

Expected:

- PASS for the admin create + retrieval scenario

- [ ] **Step 5: Commit the hardened admin-create browser coverage**

```bash
git add automationtest/specs/contact-information/admin-create.spec.mjs
git commit -m "test: verify created contact information retrieval"
```

### Task 3: Update automation documentation and run the feature suite

**Files:**
- Modify: `automationtest/README.md`
- Test: `automationtest/specs/contact-information/public-list.spec.mjs`
- Test: `automationtest/specs/contact-information/admin-create.spec.mjs`

- [ ] **Step 1: Write the failing README expectation by defining the exact coverage bullets**

```md
## 当前首批用例

- `specs/contact-information/public-list.spec.mjs`
  - 公开列表加载
  - 公开搜索
- `specs/contact-information/admin-create.spec.mjs`
  - 管理员创建
  - 创建后列表检索
```

- [ ] **Step 2: Confirm the current README does not yet describe that exact scope**

Run:

```bash
cd automationtest
rg -n "公开搜索|创建后列表检索|contact-information/public-list" README.md
```

Expected:

- either no matches for the new bullets or incomplete wording that does not yet describe the final contact-information coverage

- [ ] **Step 3: Implement the README update**

```md
## 当前首批用例

- `specs/auth/login-smoke.spec.mjs`
- `specs/auth/route-guard.spec.mjs`
- `specs/contact-information/public-list.spec.mjs`
  - 公开列表加载
  - 公开搜索
- `specs/contact-information/admin-create.spec.mjs`
  - 管理员创建
  - 创建后列表检索
- `specs/workspace/core-smoke.spec.mjs`
- `specs/workspace/validation-regression.spec.mjs`
- `specs/workspace/validation-cleanup-regression.spec.mjs`
- `specs/permissions/admin-route-access.spec.mjs`
```

- [ ] **Step 4: Run the full contact-information feature suite**

Run:

```bash
cd automationtest
npm run precheck
npx playwright test specs/contact-information
```

Expected:

- PASS for both contact-information browser specs

- [ ] **Step 5: Commit the docs update and feature-suite verification**

```bash
git add automationtest/README.md
git commit -m "docs: describe contact information browser coverage"
```

## Self-Review Notes

- **Spec coverage:** The plan maps directly to the approved scope: public list, public search, admin create, created-record retrieval, and README documentation.
- **Placeholder scan:** No `TODO`, `TBD`, or indirect “follow previous task” references remain.
- **Type consistency:** The plan consistently uses `gotoApp`, `authenticatedPage`, `cleanupRegistry`, `Search teams, staff IDs, or links`, `public-list.spec.mjs`, and `admin-create.spec.mjs`.

