import { test, expect } from '../../fixtures/test.fixture.mjs'
import {
  seedMissingPrimaryCoverageScenario,
  seedValidationImportIssueScenario,
} from '../../helpers/seed-contracts.mjs'
import { OverviewPage } from '../../pages/overview-page.mjs'
import { RosterPage } from '../../pages/roster-page.mjs'
import { ValidationPage } from '../../pages/validation-page.mjs'
import { WorkspaceShellPage } from '../../pages/workspace-shell-page.mjs'

test.describe('workspace validation regression', () => {
  test('missing primary coverage is promoted as a blocking roster risk', async ({
    authenticatedPage,
    cleanupRegistry,
    workspaceApi,
  }) => {
    const shell = new WorkspaceShellPage(authenticatedPage)
    const overviewPage = new OverviewPage(authenticatedPage)
    const validationPage = new ValidationPage(authenticatedPage)
    const rosterPage = new RosterPage(authenticatedPage)
    const scenario = await seedMissingPrimaryCoverageScenario({
      cleanupRegistry,
      workspaceApi,
    })

    await expect.poll(async () => {
      const response = await workspaceApi.getValidation(scenario.query.year, scenario.query.month, { summaryOnly: true })
      return {
        blocking: response?.summary?.blocking ?? 0,
        topRuleCode: response?.topIssue?.ruleCode ?? null,
        topType: response?.topIssue?.type ?? null,
        topTeam: response?.topIssue?.team ?? null,
      }
    }).toEqual({
      blocking: 1,
      topRuleCode: scenario.expectedIssue.ruleCode,
      topType: scenario.expectedIssue.type,
      topTeam: scenario.expectedIssue.teamName,
    })

    await expect.poll(async () => {
      const response = await workspaceApi.getValidation(scenario.query.year, scenario.query.month)
      return response?.issues?.some((issue) =>
        issue.ruleCode === scenario.expectedIssue.ruleCode
        && issue.blocking === true
        && issue.team === scenario.expectedIssue.teamName
        && issue.date === scenario.expectedIssue.dateLabel
      ) ?? false
    }).toBe(true)

    await shell.goto(`/workspace/overview${scenario.routeQuery}`)
    await shell.expectShellLoaded()
    await overviewPage.expectLoaded()
    await shell.expectNavItemCount(/^(校验|Validation)$/, 1)
    await expect(authenticatedPage.getByText(/1 blocking roster issue\(s\) remain open|1 个阻塞排班问题仍未解决/)).toBeVisible()

    await validationPage.gotoWithQuery(scenario.routeQuery)
    await validationPage.expectLoaded()
    await validationPage.expectBlockingIssue(scenario.expectedIssue)
    await expect(authenticatedPage.getByText(scenario.expectedIssue.description).first()).toBeVisible()

    await rosterPage.goto(scenario.routeQuery)
    await rosterPage.expectLoaded()
    await rosterPage.expectValidationWarning(scenario.expectedIssue.description)
  })

  test('validation page supports multi-select and bulk resolve for small import-issue queues', async ({
    authenticatedPage,
    cleanupRegistry,
    workspaceApi,
  }) => {
    const validationPage = new ValidationPage(authenticatedPage)
    const scenario = await seedValidationImportIssueScenario({
      cleanupRegistry,
      workspaceApi,
    })

    await expect.poll(async () => {
      const response = await workspaceApi.getValidation(scenario.query.year, scenario.query.month)
      return {
        total: response?.summary?.total ?? 0,
        unresolvedIds: (response?.issues ?? []).map((issue) => String(issue.id)).sort(),
      }
    }).toEqual({
      total: scenario.issues.length,
      unresolvedIds: scenario.issues.map((issue) => String(issue.id)).sort(),
    })

    await validationPage.gotoWithQuery(scenario.routeQuery)
    await validationPage.expectLoaded()
    await validationPage.expectIssueVisible(scenario.issues[0])
    await validationPage.expectIssueVisible(scenario.issues[1])
    await validationPage.expectSelectionControlsAvailable()
    await validationPage.selectVisibleIssues()
    await validationPage.expectSelectedCount(scenario.issues.length)
    await validationPage.resolveSelectedIssues()

    await expect.poll(async () => {
      const response = await workspaceApi.getValidation(scenario.query.year, scenario.query.month)
      return response?.summary?.total ?? 0
    }).toBe(0)

    await validationPage.expectIssueCount(0)
    await validationPage.expectEmptyInbox()
  })
})
