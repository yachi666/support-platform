import { test, expect } from '../../fixtures/test.fixture.mjs'
import { seedValidationCleanupScenario } from '../../helpers/seed-contracts.mjs'
import { ValidationPage } from '../../pages/validation-page.mjs'

function summarizeCleanupIssues(response, scenario) {
  const issues = response?.issues ?? []

  return {
    total: response?.summary?.total ?? 0,
    blocking: response?.summary?.blocking ?? 0,
    orphanVisible: issues.some((issue) =>
      issue.type === scenario.expectedIssues.orphanAssignment.type
      && issue.remediation?.actionKey === scenario.expectedIssues.orphanAssignment.remediation.actionKey
      && issue.team === scenario.expectedIssues.orphanAssignment.teamName
    ),
    invalidTeamScopeVisible: issues.some((issue) =>
      issue.type === scenario.expectedIssues.invalidTeamScope.type
      && issue.remediation?.actionKey === scenario.expectedIssues.invalidTeamScope.remediation.actionKey
    ),
  }
}

test.describe('workspace validation cleanup regression', () => {
  test('system cleanup issues can be previewed and resolved from validation center', async ({
    authenticatedPage,
    cleanupRegistry,
    workspaceApi,
  }) => {
    const validationPage = new ValidationPage(authenticatedPage)
    const scenario = await seedValidationCleanupScenario({
      cleanupRegistry,
      workspaceApi,
    })

    await expect.poll(async () => {
      const response = await workspaceApi.getValidation(scenario.query.year, scenario.query.month)
      return summarizeCleanupIssues(response, scenario)
    }).toEqual({
      total: 2,
      blocking: 1,
      orphanVisible: true,
      invalidTeamScopeVisible: true,
    })

    await validationPage.gotoWithQuery(scenario.routeQuery)
    await validationPage.expectLoaded()
    await validationPage.expectIssueVisible(scenario.expectedIssues.orphanAssignment)
    await validationPage.expectIssueVisible(scenario.expectedIssues.invalidTeamScope)

    await validationPage.openFixNow(scenario.expectedIssues.orphanAssignment.type)
    await validationPage.expectRemediationPreview(scenario.expectedIssues.orphanAssignment)
    await validationPage.confirmRemediation()
    await validationPage.expectCleanupSuccessToast()

    await expect.poll(async () => {
      const response = await workspaceApi.getValidation(scenario.query.year, scenario.query.month)
      return summarizeCleanupIssues(response, scenario)
    }).toEqual({
      total: 1,
      blocking: 0,
      orphanVisible: false,
      invalidTeamScopeVisible: true,
    })

    await validationPage.expectIssueNotVisible(scenario.expectedIssues.orphanAssignment.type)
    await validationPage.expectIssueVisible(scenario.expectedIssues.invalidTeamScope)

    await validationPage.openFixNow(scenario.expectedIssues.invalidTeamScope.type)
    await validationPage.expectRemediationPreview(scenario.expectedIssues.invalidTeamScope)
    await validationPage.confirmRemediation()
    await validationPage.expectCleanupSuccessToast()

    await expect.poll(async () => {
      const response = await workspaceApi.getValidation(scenario.query.year, scenario.query.month)
      return summarizeCleanupIssues(response, scenario)
    }).toEqual({
      total: 0,
      blocking: 0,
      orphanVisible: false,
      invalidTeamScopeVisible: false,
    })

    await validationPage.expectEmptyInbox()
  })
})
