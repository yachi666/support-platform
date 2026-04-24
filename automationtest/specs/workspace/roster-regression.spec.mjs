import { test } from '../../fixtures/test.fixture.mjs'
import { seedRosterSearchScenario } from '../../helpers/seed-contracts.mjs'
import { RosterPage } from '../../pages/roster-page.mjs'

test.describe('workspace roster regression', () => {
  test('topbar search syncs with roster search, searches by name substring only, and keeps hidden teams visible in workspace', async ({
    authenticatedPage,
    cleanupRegistry,
    workspaceApi,
  }) => {
    const rosterPage = new RosterPage(authenticatedPage)
    const scenario = await seedRosterSearchScenario({
      cleanupRegistry,
      workspaceApi,
    })

    await rosterPage.goto(scenario.routeQuery)
    await rosterPage.expectLoaded()
    await rosterPage.expectTeamFilterOptionVisible(scenario.hiddenTeam.name)
    await rosterPage.toggleTeamFilter(scenario.hiddenTeam.name)
    await rosterPage.expectTeamVisible(scenario.hiddenTeam.name)
    await rosterPage.expectStaffNamesOrderedTopToBottom(scenario.hiddenTeamStaffOrder)

    await rosterPage.fillTopbarSearch(scenario.searchTerms.byName)
    await rosterPage.expectSearchInputsSynced(scenario.searchTerms.byName)
    await rosterPage.expectStaffVisible(scenario.hiddenTeamStaffOrder[1])
    await rosterPage.expectStaffNotVisible(scenario.hiddenTeamStaffOrder[0])
    await rosterPage.expectStaffNotVisible(scenario.hiddenTeamStaffOrder[2])

    await rosterPage.fillTopbarSearch(scenario.searchTerms.byRoleOnly)
    await rosterPage.expectSearchInputsSynced(scenario.searchTerms.byRoleOnly)
    await rosterPage.expectEmptyFilteredResult()

    await rosterPage.fillTopbarSearch(scenario.searchTerms.byTeamOnly)
    await rosterPage.expectSearchInputsSynced(scenario.searchTerms.byTeamOnly)
    await rosterPage.expectEmptyFilteredResult()

    await rosterPage.toggleTeamFilter(scenario.hiddenTeam.name)
    await rosterPage.fillPageSearch(scenario.searchTerms.pageSearchName)
    await rosterPage.expectSearchInputsSynced(scenario.searchTerms.pageSearchName)
    await rosterPage.expectStaffVisible(`Bella Visible ${scenario.runId.slice(-4)}`)
    await rosterPage.expectStaffNotVisible(scenario.hiddenTeamStaffOrder[0])
  })
})
