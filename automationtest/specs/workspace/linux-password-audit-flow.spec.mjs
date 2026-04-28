import { expect, test } from '../../fixtures/test.fixture.mjs'
import { env, hasRoleCredential } from '../../config/env.mjs'
import { loginByApi } from '../../helpers/api-auth.mjs'
import { gotoApp } from '../../helpers/route-assertions.mjs'
import { LinuxPasswordAuditPage } from '../../pages/linux-password-audit-page.mjs'

test.describe('linux password audit flow', () => {
  test('admin can open the audit page from the linux password sidebar', async ({ authenticatedPage }) => {
    await gotoApp(authenticatedPage, '/linux-passwords')

    const auditLink = authenticatedPage.getByRole('link', { name: /^(Audit Records|审计记录)$/ })
    await expect(auditLink).toBeVisible()

    await auditLink.click()

    await expect(authenticatedPage).toHaveURL(/\/linux-passwords\/audits$/)

    const auditPage = new LinuxPasswordAuditPage(authenticatedPage)
    await auditPage.expectLoaded()
  })

  test('non-admin authenticated user cannot access the audit route', async ({ browser, cleanupRegistry }) => {
    test.skip(!hasRoleCredential('editor'), 'requires AUTOTEST_EDITOR_STAFF_ID / AUTOTEST_EDITOR_PASSWORD to be configured')

    const session = await loginByApi({ staffId: env.roles.editor.staffId, password: env.roles.editor.password })
    const token = String(session?.token || '').replace(/^Bearer\s+/i, '')

    const context = await browser.newContext({ baseURL: env.baseUrl })
    await context.addInitScript((value) => {
      window.localStorage.setItem('support-roster-auth-token', value)
    }, token)
    cleanupRegistry.add('close-editor-context', () => context.close())

    const page = await context.newPage()
    await gotoApp(page, '/linux-passwords/audits')

    await expect(page).not.toHaveURL(/\/linux-passwords\/audits/)
  })

  test('revealing a password via the UI produces a visible audit record on the audit page', async ({
    authenticatedPage,
    workspaceApi,
  }) => {
    const passwordList = await workspaceApi.getLinuxPasswords()
    const server = passwordList?.items?.[0]
    const credential = server?.credentials?.[0]

    if (!server || !credential) {
      test.skip(true, 'no linux password entries available in the test environment')
      return
    }

    const auditsBefore = await workspaceApi.getLinuxPasswordAudits()
    const countBefore = auditsBefore?.total ?? 0

    await gotoApp(authenticatedPage, '/linux-passwords')
    await expect(
      authenticatedPage.getByRole('heading', { name: /Linux 密码库|Linux Password Vault/ }),
    ).toBeVisible()

    const revealButton = authenticatedPage
      .locator('table tbody tr')
      .filter({ hasText: server.hostname })
      .locator('button[title]')
      .first()
    await revealButton.click()

    await expect.poll(async () => {
      const audits = await workspaceApi.getLinuxPasswordAudits()
      return audits?.total ?? 0
    }).toBeGreaterThan(countBefore)

    const auditPage = new LinuxPasswordAuditPage(authenticatedPage)
    await auditPage.goto()
    await auditPage.expectLoaded()
    await auditPage.expectAuditRecordForHost(server.hostname)
  })
})
