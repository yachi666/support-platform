import { test } from '../../fixtures/test.fixture.mjs'
import { WorkspaceShellPage } from '../../pages/workspace-shell-page.mjs'

test.describe('admin route access', () => {
  test('primary authenticated user sees admin navigation entries', async ({ authenticatedPage }) => {
    const shell = new WorkspaceShellPage(authenticatedPage)

    await shell.goto('/workspace/overview')
    await shell.expectShellLoaded()
    await shell.expectNavItem(/^(团队|Teams)$/)
    await shell.expectNavItem(/^(账号|Accounts)$/)
    await shell.expectNavItem(/^(校验|Validation)$/)
  })
})
