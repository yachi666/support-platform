import { test } from '../../fixtures/test.fixture.mjs'
import { WorkspaceShellPage } from '../../pages/workspace-shell-page.mjs'
import { OverviewPage } from '../../pages/overview-page.mjs'
import { TeamsPage } from '../../pages/teams-page.mjs'
import { ValidationPage } from '../../pages/validation-page.mjs'
import { assertKnownTeamIfConfigured } from '../../helpers/seed-contracts.mjs'

test.describe('workspace smoke', () => {
  test('authenticated user can open workspace overview', async ({ authenticatedPage }) => {
    const shell = new WorkspaceShellPage(authenticatedPage)
    const overview = new OverviewPage(authenticatedPage)

    await shell.goto('/workspace/overview')
    await shell.expectShellLoaded()
    await overview.expectLoaded()
  })

  test('authenticated user can open validation page', async ({ authenticatedPage }) => {
    const validationPage = new ValidationPage(authenticatedPage)

    await validationPage.goto()
    await validationPage.expectLoaded()
  })

  test('authenticated user can open teams page', async ({ authenticatedPage }) => {
    const teamsPage = new TeamsPage(authenticatedPage)

    await teamsPage.goto()
    await teamsPage.expectLoaded()
    await assertKnownTeamIfConfigured({ page: authenticatedPage })
  })
})
