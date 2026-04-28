import { expect, test } from '../../fixtures/test.fixture.mjs'
import { requirePrimaryUser } from '../../config/env.mjs'
import { loginByApi } from '../../helpers/api-auth.mjs'
import { expectRedirectToLogin, gotoApp } from '../../helpers/route-assertions.mjs'
import {
  getWorkspaceAccessPolicy,
  toConfigurableWorkspaceAccessPolicyPayload,
  updateWorkspaceAccessPolicy,
} from '../../helpers/workspace-access-policy.mjs'

function expectWorkspaceUrlState(page, { pathname, wy, wm, wtz }) {
  return expect
    .poll(() => {
      const currentUrl = new URL(page.url())
      return {
        pathname: currentUrl.pathname,
        wy: currentUrl.searchParams.get('wy'),
        wm: currentUrl.searchParams.get('wm'),
        wtz: currentUrl.searchParams.get('wtz'),
      }
    })
    .toEqual({ pathname, wy, wm, wtz })
}

test.describe('route guard', () => {
  test('anonymous user can open public workspace route and keep period query', async ({ page, cleanupRegistry }) => {
    const session = await loginByApi(requirePrimaryUser())
    const originalPolicy = await getWorkspaceAccessPolicy(session.token)

    cleanupRegistry.add('restore-workspace-access-policy', async () => {
      await updateWorkspaceAccessPolicy(session.token, toConfigurableWorkspaceAccessPolicyPayload(originalPolicy.pages))
    })

    await updateWorkspaceAccessPolicy(session.token, [
      { pageCode: 'overview', authRequired: false },
      { pageCode: 'roster', authRequired: false },
      { pageCode: 'staff', authRequired: false },
      { pageCode: 'shifts', authRequired: false },
      { pageCode: 'teams', authRequired: false },
      { pageCode: 'import-export', authRequired: false },
      { pageCode: 'validation', authRequired: false },
      { pageCode: 'linux-passwords', authRequired: false },
    ])

    await gotoApp(page, '/workspace?wy=2027&wm=5&wtz=UTC')

    await expect(page).toHaveURL(/\/workspace\/overview(?:\?|$)/)
    await expectWorkspaceUrlState(page, {
      pathname: '/workspace/overview',
      wy: '2027',
      wm: '5',
      wtz: 'UTC',
    })
    await expect(page.getByRole('button', { name: 'Sign in' })).toBeVisible()
    await expect(page.getByRole('link', { name: 'Overview', exact: true })).toBeVisible()
  })

  test('workspace entry falls through to next public page when overview requires login', async ({ page, cleanupRegistry }) => {
    const session = await loginByApi(requirePrimaryUser())
    const originalPolicy = await getWorkspaceAccessPolicy(session.token)

    cleanupRegistry.add('restore-workspace-access-policy', async () => {
      await updateWorkspaceAccessPolicy(session.token, toConfigurableWorkspaceAccessPolicyPayload(originalPolicy.pages))
    })

    await updateWorkspaceAccessPolicy(session.token, [
      { pageCode: 'overview', authRequired: true },
      { pageCode: 'roster', authRequired: false },
      { pageCode: 'staff', authRequired: false },
      { pageCode: 'shifts', authRequired: false },
      { pageCode: 'teams', authRequired: false },
      { pageCode: 'import-export', authRequired: false },
      { pageCode: 'validation', authRequired: false },
      { pageCode: 'linux-passwords', authRequired: true },
    ])

    await gotoApp(page, '/workspace?wy=2028&wm=7&wtz=UTC')

    await expect(page).toHaveURL(/\/workspace\/roster(?:\?|$)/)
    await expectWorkspaceUrlState(page, {
      pathname: '/workspace/roster',
      wy: '2028',
      wm: '7',
      wtz: 'UTC',
    })
    await expect(page.getByRole('button', { name: 'Sign in' })).toBeVisible()
  })

  test('anonymous user is redirected from protected workspace route', async ({ page }) => {
    await gotoApp(page, '/workspace/teams')
    await expectRedirectToLogin(page)
  })
})
