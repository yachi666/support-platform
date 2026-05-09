import { test, expect } from '../../fixtures/test.fixture.mjs'
import { readWorkbookFromDownload } from '../../helpers/workbook-download.mjs'
import { seedExportShiftViewerScenario } from '../../helpers/seed-contracts.mjs'
import { ShiftDefinitionsPage } from '../../pages/shift-definitions-page.mjs'
import { ViewerPage } from '../../pages/viewer-page.mjs'
import { WorkspaceShellPage } from '../../pages/workspace-shell-page.mjs'

test.describe('workspace export / shift / viewer regression', () => {
  test('export contains name column, long shift codes stay operable, and viewer shows visible non-primary shifts', async ({
    authenticatedPage,
    cleanupRegistry,
    workspaceApi,
  }) => {
    const shell = new WorkspaceShellPage(authenticatedPage)
    const shiftsPage = new ShiftDefinitionsPage(authenticatedPage)
    const viewerPage = new ViewerPage(authenticatedPage)
    const scenario = await seedExportShiftViewerScenario({
      cleanupRegistry,
      workspaceApi,
    })

    await shell.goto(`/workspace/roster${scenario.routeQuery}`)
    await shell.expectShellLoaded()

    const downloadPromise = authenticatedPage.waitForEvent('download')
    await authenticatedPage.getByRole('button', { name: /^(Export|导出)$/ }).click()
    const workbook = await readWorkbookFromDownload(await downloadPromise)
    expect(workbook.getCell('Monthly Roster', 'A1')).toBe('staff_id')
    expect(workbook.getCell('Monthly Roster', 'B1')).toBe('team')
    expect(workbook.getCell('Monthly Roster', 'C1')).toBe('name')
    expect(workbook.getCell('Monthly Roster', 'C2')).toBe(scenario.staff.name)

    await shiftsPage.gotoWithQuery(scenario.routeQueryWithShiftFocus)
    await shiftsPage.expectFocusedShift(scenario.longShift.code)
    await shiftsPage.expectShiftDrawerVisible(scenario.longShift.code)

    await viewerPage.gotoDate(scenario.viewerDate)
    await viewerPage.expectVisibleNonPrimaryShift({
      teamName: scenario.team.name,
      staffName: scenario.staff.name,
      shiftLabel: scenario.visibleNonPrimaryShift.meaning,
    })
  })
})
