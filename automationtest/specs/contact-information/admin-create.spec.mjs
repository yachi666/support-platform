import { test, expect } from '../../fixtures/test.fixture.mjs'
import { escapeSqlLiteral, executeSql } from '../../helpers/postgres-cli.mjs'
import { gotoApp } from '../../helpers/route-assertions.mjs'

test.describe('contact information admin create', () => {
  test('admin can create a contact information record with only team name and find it on the list page', async ({ authenticatedPage, cleanupRegistry }) => {
    const runId = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`
    const teamName = `AUTOTEST Contact ${runId}`
    const escapedTeamName = escapeSqlLiteral(teamName)

    cleanupRegistry.add(`delete-contact-information-${runId}`, async () => {
      await executeSql(`
        DELETE FROM support_team_contact_link
        WHERE contact_id IN (
          SELECT id
          FROM support_team_contact
          WHERE deleted = 0
            AND team_name = '${escapedTeamName}'
        );
        DELETE FROM support_team_contact_staff
        WHERE contact_id IN (
          SELECT id
          FROM support_team_contact
          WHERE deleted = 0
            AND team_name = '${escapedTeamName}'
        );
        DELETE FROM support_team_contact_tag
        WHERE contact_id IN (
          SELECT id
          FROM support_team_contact
          WHERE deleted = 0
            AND team_name = '${escapedTeamName}'
        );
        DELETE FROM support_team_contact
        WHERE deleted = 0
          AND team_name = '${escapedTeamName}';
      `)
    })

    await gotoApp(authenticatedPage, '/contact-information/add')

    await authenticatedPage.getByLabel('Team Name').fill(teamName)
    await authenticatedPage.getByRole('button', { name: 'Save Team' }).click()

    await expect(authenticatedPage).toHaveURL(/\/contact-information(?:\?|$)/)
    await expect(authenticatedPage.getByText('Team saved successfully.')).toBeVisible()

    await authenticatedPage.getByLabel('Search teams, staff IDs, or links').fill(teamName)
    const createdRow = authenticatedPage.locator('tbody tr', {
      has: authenticatedPage.getByRole('cell', { name: teamName }),
    })
    await expect(createdRow.getByRole('cell', { name: teamName })).toBeVisible()
    await expect(createdRow.getByRole('link', { name: 'Other' })).toHaveCount(0)
  })
})
