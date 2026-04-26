import { test, expect } from '../../fixtures/test.fixture.mjs'
import { escapeSqlLiteral, executeSql } from '../../helpers/postgres-cli.mjs'
import { gotoApp } from '../../helpers/route-assertions.mjs'

test.describe('contact information public list', () => {
  test('public contact information list loads without login and supports search', async ({ page, cleanupRegistry }) => {
    const runId = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`
    const contactId = Date.now() * 1000 + Math.floor(Math.random() * 1000)
    const teamName = `AUTOTEST Public ${runId}`
    const teamEmail = `autotest-public-${runId}@example.test`
    const escapedTeamName = escapeSqlLiteral(teamName)
    const escapedTeamEmail = escapeSqlLiteral(teamEmail)

    cleanupRegistry.add(`delete-public-contact-information-${runId}`, async () => {
      await executeSql(`
        DELETE FROM support_team_contact
        WHERE deleted = 0
          AND LOWER(BTRIM(team_email)) = LOWER(BTRIM('${escapedTeamEmail}'));
      `)
    })

    await executeSql(`
      INSERT INTO support_team_contact (
        id,
        team_name,
        team_email,
        deleted
      ) VALUES (
        ${contactId},
        '${escapedTeamName}',
        '${escapedTeamEmail}',
        0
      );
    `)

    await gotoApp(page, '/contact-information')

    await expect(page.getByRole('heading', { name: 'System Teams' })).toBeVisible()
    await expect(page.getByLabel('Search teams, staff IDs, or links')).toBeVisible()
    await expect(page.getByText(/Showing \d+ to \d+ of \d+ entries/)).toBeVisible()

    await page.getByLabel('Search teams, staff IDs, or links').fill(teamName)
    await expect(page.getByRole('cell', { name: teamName })).toBeVisible()
  })
})
