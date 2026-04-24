import { expect, test } from '../../fixtures/test.fixture.mjs'
import { requirePrimaryUser } from '../../config/env.mjs'
import { loginByApi } from '../../helpers/api-auth.mjs'
import { gotoApp } from '../../helpers/route-assertions.mjs'
import {
  getWorkspaceAccessPolicy,
  toConfigurableWorkspaceAccessPolicyPayload,
  updateWorkspaceAccessPolicy,
} from '../../helpers/workspace-access-policy.mjs'

test.describe('linux password route guard', () => {
  test('anonymous user is redirected to login when linux-passwords requires auth', async ({ page, cleanupRegistry }) => {
    const session = await loginByApi(requirePrimaryUser())
    const originalPolicy = await getWorkspaceAccessPolicy(session.token)

    cleanupRegistry.add('restore-workspace-access-policy', async () => {
      await updateWorkspaceAccessPolicy(session.token, toConfigurableWorkspaceAccessPolicyPayload(originalPolicy.pages))
    })

    await updateWorkspaceAccessPolicy(session.token, [
      ...toConfigurableWorkspaceAccessPolicyPayload(originalPolicy.pages).filter((page) => page.pageCode !== 'linux-passwords'),
      { pageCode: 'linux-passwords', authRequired: true },
    ])

    await gotoApp(page, '/linux-passwords')

    await expect(page).toHaveURL(/\/login(?:\?|$)/)
    await expect
      .poll(() => {
        const currentUrl = new URL(page.url())
        return {
          pathname: currentUrl.pathname,
          redirect: currentUrl.searchParams.get('redirect'),
        }
      })
      .toEqual({
        pathname: '/login',
        redirect: '/linux-passwords',
      })
  })

  test('anonymous user can open linux-passwords when policy disables login', async ({ page, cleanupRegistry }) => {
    const session = await loginByApi(requirePrimaryUser())
    const originalPolicy = await getWorkspaceAccessPolicy(session.token)

    cleanupRegistry.add('restore-workspace-access-policy', async () => {
      await updateWorkspaceAccessPolicy(session.token, toConfigurableWorkspaceAccessPolicyPayload(originalPolicy.pages))
    })

    await updateWorkspaceAccessPolicy(session.token, [
      ...toConfigurableWorkspaceAccessPolicyPayload(originalPolicy.pages).filter((page) => page.pageCode !== 'linux-passwords'),
      { pageCode: 'linux-passwords', authRequired: false },
    ])

    await gotoApp(page, '/linux-passwords')

    await expect(page.getByRole('heading', { name: /Linux 密码库|Linux Password Vault/ })).toBeVisible()
  })
})
