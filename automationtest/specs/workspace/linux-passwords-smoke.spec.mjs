import { expect, test } from '../../fixtures/test.fixture.mjs'
import { gotoApp } from '../../helpers/route-assertions.mjs'
import { WorkspaceShellPage } from '../../pages/workspace-shell-page.mjs'

test.describe('linux password smoke', () => {
  test('authenticated user can open linux password page from viewer and workspace top actions', async ({ authenticatedPage }) => {
    await gotoApp(authenticatedPage, '/viewer')
    await authenticatedPage.getByRole('link', { name: /Linux 密码库|Linux Password Vault/ }).click()
    await expect(authenticatedPage).toHaveURL(/\/linux-passwords$/)
    await expect(authenticatedPage.getByRole('heading', { name: /Linux 密码库|Linux Password Vault/ })).toBeVisible()

    const shell = new WorkspaceShellPage(authenticatedPage)
    await shell.goto('/workspace/overview')
    await authenticatedPage.getByRole('link', { name: /Linux 密码库|Linux Password Vault/ }).click()
    await expect(authenticatedPage).toHaveURL(/\/linux-passwords$/)
    await expect(authenticatedPage.getByPlaceholder(/Search host or IP|搜索主机或 IP/)).toBeVisible()
  })

  test('workspace top action stays visible after login on a narrower desktop width', async ({ authenticatedPage }) => {
    await authenticatedPage.setViewportSize({ width: 1000, height: 900 })

    const shell = new WorkspaceShellPage(authenticatedPage)
    await shell.goto('/workspace/overview')

    await expect(authenticatedPage.getByRole('link', { name: /Linux 密码库|Linux Password Vault/ })).toBeVisible()
  })
})
