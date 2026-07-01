import { test, expect } from '../../fixtures/test.fixture.mjs'
import { LoginPage } from '../../pages/login-page.mjs'
import { WorkspaceShellPage } from '../../pages/workspace-shell-page.mjs'
import { OverviewPage } from '../../pages/overview-page.mjs'
import { loginByApi, activateByApi } from '../../helpers/api-auth.mjs'
import { executeSql } from '../../helpers/postgres-cli.mjs'
import { assertManualEnvironmentReady } from '../../helpers/seed-contracts.mjs'

/**
 * Viewer-month seed staff records — these exist in the DB with no accounts.
 * Uses different IDs per test to avoid cross-test interference.
 */
const UI_TEST_STAFF_ID = 'ATVMOSY400'
const API_TEST_STAFF_ID = 'ATVMOSY401'
const DUPLICATE_TEST_STAFF_ID = 'ATVMOSY402'
const TEST_PASSWORD = 'testpass123'

/** Physically delete account + team scopes for a staffId */
async function hardDeleteAccount(staffId) {
  try {
    const adminToken = await loginByApi({ staffId: 'admin', password: 'admin' })
    const res = await fetch('http://127.0.0.1:8080/api/workspace/accounts', {
      method: 'GET',
      headers: { Authorization: adminToken.token, 'Content-Type': 'application/json' },
    })
    const accounts = await res.json()
    const list = Array.isArray(accounts) ? accounts : []
    const target = list.find((a) => a.staffId === staffId)
    if (target) {
      // Hard-delete via API soft-deletes (sets deleted=1). We need a physical
      // delete so the next test run can self-register the same staffId fresh.
      await executeSql(
        `DELETE FROM workspace_account_team_scope WHERE account_id = ${target.id};`
      )
      await executeSql(
        `DELETE FROM workspace_account WHERE id = ${target.id};`
      )
    }
  } catch (e) {
    console.warn(`Cleanup warning for ${staffId}: ${e.message}`)
  }
}

test.describe('self-registration', () => {

  test('employee can self-register via activation tab and reach workspace', async ({ page, cleanupRegistry }) => {
    const loginPage = new LoginPage(page)
    const workspaceShell = new WorkspaceShellPage(page)
    const overviewPage = new OverviewPage(page)

    await assertManualEnvironmentReady({ page })
    await hardDeleteAccount(UI_TEST_STAFF_ID)
    cleanupRegistry.add('self-reg-ui-cleanup', () => hardDeleteAccount(UI_TEST_STAFF_ID))

    await loginPage.goto()
    await loginPage.expectLoaded()
    await loginPage.activate({
      staffId: UI_TEST_STAFF_ID,
      newPassword: TEST_PASSWORD,
    })

    await workspaceShell.expectShellLoaded()
    await overviewPage.expectLoaded()
    await expect(page).toHaveURL(/\/workspace\/overview(?:\?|$)/)
  })

  test('self-registered user gets editor role with team scope via API', async ({ page, cleanupRegistry }) => {
    await hardDeleteAccount(API_TEST_STAFF_ID)
    cleanupRegistry.add('self-reg-api-cleanup', () => hardDeleteAccount(API_TEST_STAFF_ID))

    // 1. Self-register via API (use /auth/activate endpoint)
    const result = await activateByApi({
      staffId: API_TEST_STAFF_ID,
      newPassword: TEST_PASSWORD,
    })

    // 2. Verify the response contains the expected role and permissions
    expect(result.token).toBeTruthy()
    expect(result.currentUser).toBeTruthy()
    expect(result.currentUser.role).toBe('editor')
    expect(result.currentUser.permissions).toContain('workspace.read')
    expect(result.currentUser.permissions).toContain('workspace.write')

    // 3. Verify the user has at least one editable team
    expect(result.currentUser.editableTeamIds.length).toBeGreaterThanOrEqual(1)
    expect(result.currentUser.editableTeams.length).toBeGreaterThanOrEqual(1)

    // 4. Verify the user can call workspace roster (read permission)
    const rosterRes = await fetch('http://127.0.0.1:8080/api/workspace/roster', {
      method: 'GET',
      headers: { Authorization: result.token },
    })
    expect(rosterRes.ok).toBeTruthy()
  })

  test('existing active account cannot self-register again', async ({ page, cleanupRegistry }) => {
    const loginPage = new LoginPage(page)
    await assertManualEnvironmentReady({ page })

    // Ensure a clean account exists for this test
    await hardDeleteAccount(DUPLICATE_TEST_STAFF_ID)
    await activateByApi({ staffId: DUPLICATE_TEST_STAFF_ID, newPassword: TEST_PASSWORD })
    cleanupRegistry.add('self-reg-duplicate-cleanup', () => hardDeleteAccount(DUPLICATE_TEST_STAFF_ID))

    // Now try to activate again via UI — should fail
    await loginPage.goto()
    await loginPage.expectLoaded()
    await loginPage.activate({
      staffId: DUPLICATE_TEST_STAFF_ID,
      newPassword: 'anotherpass456',
    })

    // Should show error message about already initialized
    const errorEl = page.locator('text=/Password has already been initialized|密码已初始化/')
    await expect(errorEl).toBeVisible({ timeout: 10000 })
  })

  test('non-existent staffId gets rejected', async ({ page }) => {
    const loginPage = new LoginPage(page)

    await assertManualEnvironmentReady({ page })

    await loginPage.goto()
    await loginPage.expectLoaded()
    await loginPage.activate({
      staffId: 'NONEXISTENT999',
      newPassword: 'testpass123',
    })

    // Should show error about no staff record found
    const errorEl = page.locator('text=/No staff record found|无对应员工记录/')
    await expect(errorEl).toBeVisible({ timeout: 10000 })
  })
})
