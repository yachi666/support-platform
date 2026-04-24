import { test, expect } from '../../fixtures/test.fixture.mjs'
import { env, requirePrimaryUser } from '../../config/env.mjs'
import { LoginPage } from '../../pages/login-page.mjs'
import { WorkspaceShellPage } from '../../pages/workspace-shell-page.mjs'
import { OverviewPage } from '../../pages/overview-page.mjs'
import { gotoApp } from '../../helpers/route-assertions.mjs'
import { assertManualEnvironmentReady } from '../../helpers/seed-contracts.mjs'

test.describe('auth smoke', () => {
  test('user can log in from the UI and reach workspace overview', async ({ page }) => {
    requirePrimaryUser()

    const loginPage = new LoginPage(page)
    const workspaceShell = new WorkspaceShellPage(page)
    const overviewPage = new OverviewPage(page)

    await assertManualEnvironmentReady({ page })
    await loginPage.goto()
    await loginPage.expectLoaded()
    await loginPage.login(env.primaryUser)

    await workspaceShell.expectShellLoaded()
    await overviewPage.expectLoaded()
    await expect(page).toHaveURL(/\/workspace\/overview(?:\?|$)/)
  })

  test('login keeps workspace entry redirect query parameters', async ({ page }) => {
    requirePrimaryUser()

    const loginPage = new LoginPage(page)
    const workspaceShell = new WorkspaceShellPage(page)
    const overviewPage = new OverviewPage(page)

    await assertManualEnvironmentReady({ page })
    await gotoApp(page, '/login?redirect=%2Fworkspace%3Fwy%3D2028%26wm%3D7%26wtz%3DUTC')
    await loginPage.expectLoaded()
    await loginPage.login(env.primaryUser)

    await workspaceShell.expectShellLoaded()
    await overviewPage.expectLoaded()
    await expect
      .poll(() => {
        const currentUrl = new URL(page.url())
        return {
          pathname: currentUrl.pathname,
          wy: currentUrl.searchParams.get('wy'),
          wm: currentUrl.searchParams.get('wm'),
          wtz: currentUrl.searchParams.get('wtz'),
        }
      })
      .toEqual({
        pathname: '/workspace/overview',
        wy: '2028',
        wm: '7',
        wtz: 'UTC',
      })
  })
})
