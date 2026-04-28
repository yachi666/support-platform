import { expect, test } from '../../fixtures/test.fixture.mjs'
import { env, hasRoleCredential } from '../../config/env.mjs'
import { loginByApi } from '../../helpers/api-auth.mjs'
import { gotoApp } from '../../helpers/route-assertions.mjs'
import { LinuxPasswordAuditPage } from '../../pages/linux-password-audit-page.mjs'
import { escapeSqlLiteral, executeSql } from '../../helpers/postgres-cli.mjs'

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
    cleanupRegistry,
  }) => {
    const ts = String(Date.now())
    const rand = String(Math.floor(Math.random() * 1000)).padStart(3, '0')
    const serverId = `28${ts.slice(-9)}${rand}`
    const credentialId = `27${ts.slice(-9)}${rand}`
    const hostname = `autotest-lp-${ts.slice(-9)}-${rand}.example.test`
    const ip = `10.255.${Number(ts.slice(-3)) % 255}.${(Number(rand) % 254) + 1}`

    await executeSql(`
      INSERT INTO workspace_linux_password_server
        (id, hostname, ip, username, password, status, deleted)
      VALUES
        (${serverId},
         '${escapeSqlLiteral(hostname)}',
         '${escapeSqlLiteral(ip)}',
         '',
         '',
         'online',
         0);
    `)
    cleanupRegistry.add(
      `delete-linux-password-server-${serverId}`,
      () => executeSql(`DELETE FROM workspace_linux_password_server WHERE id = ${serverId};`),
    )

    await executeSql(`
      INSERT INTO workspace_linux_password_credential
        (id, server_id, username, password_ciphertext, password_iv, key_version, deleted)
      VALUES
        (${credentialId},
         ${serverId},
         'autotest',
         'YXV0b3Rlc3QtZHVtbXktY2lwaGVydGV4dA==',
         'YXV0b3Rlc3QtaXY=',
         'v2',
         0);
    `)
    cleanupRegistry.add(
      `delete-linux-password-credential-${credentialId}`,
      () => executeSql(`DELETE FROM workspace_linux_password_credential WHERE id = ${credentialId};`),
    )

    const auditsBefore = await workspaceApi.getLinuxPasswordAudits({ hostname })
    const countBefore = auditsBefore?.items?.length ?? 0

    await gotoApp(authenticatedPage, '/linux-passwords')
    await expect(
      authenticatedPage.getByRole('heading', { name: /Linux 密码库|Linux Password Vault/ }),
    ).toBeVisible()

    const revealButton = authenticatedPage
      .locator('table tbody tr')
      .filter({ hasText: hostname })
      .locator('button[title]')
      .first()

    await Promise.all([
      authenticatedPage.waitForResponse(
        (resp) => resp.url().includes('/credentials/') && resp.url().includes('/secret'),
      ),
      revealButton.click(),
    ])

    await expect.poll(async () => {
      const audits = await workspaceApi.getLinuxPasswordAudits({ hostname })
      return audits?.items?.length ?? 0
    }, { timeout: 15000 }).toBeGreaterThan(countBefore)

    const auditPage = new LinuxPasswordAuditPage(authenticatedPage)
    await auditPage.goto()
    await auditPage.expectLoaded()
    await auditPage.expectAuditRecordForHost(hostname)
  })
})
