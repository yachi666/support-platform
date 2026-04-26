import { test, expect } from '../../fixtures/test.fixture.mjs'
import { requirePrimaryUser } from '../../config/env.mjs'
import { escapeSqlLiteral, executeSql } from '../../helpers/postgres-cli.mjs'
import { gotoApp } from '../../helpers/route-assertions.mjs'

test.describe('contact information admin create', () => {
  test('admin can create a contact information record and find it on the list page', async ({ authenticatedPage, cleanupRegistry }) => {
    const primaryUser = requirePrimaryUser()
    const runId = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`
    const teamName = `AUTOTEST Contact ${runId}`
    const teamEmail = `autotest-contact-${runId}@example.test`
    const otherInfoUrl = `https://example.test/contact/${runId}`

    cleanupRegistry.add(`delete-contact-information-${runId}`, async () => {
      const escapedEmail = escapeSqlLiteral(teamEmail)
      await executeSql(`
        DELETE FROM support_team_contact_link
        WHERE contact_id IN (
          SELECT id
          FROM support_team_contact
          WHERE deleted = 0
            AND LOWER(BTRIM(team_email)) = LOWER(BTRIM('${escapedEmail}'))
        );
        DELETE FROM support_team_contact_staff
        WHERE contact_id IN (
          SELECT id
          FROM support_team_contact
          WHERE deleted = 0
            AND LOWER(BTRIM(team_email)) = LOWER(BTRIM('${escapedEmail}'))
        );
        DELETE FROM support_team_contact_tag
        WHERE contact_id IN (
          SELECT id
          FROM support_team_contact
          WHERE deleted = 0
            AND LOWER(BTRIM(team_email)) = LOWER(BTRIM('${escapedEmail}'))
        );
        DELETE FROM support_team_contact
        WHERE deleted = 0
          AND LOWER(BTRIM(team_email)) = LOWER(BTRIM('${escapedEmail}'));
      `)
    })

    await gotoApp(authenticatedPage, '/contact-information/add')

    await authenticatedPage.getByLabel('Team Name').fill(teamName)
    await authenticatedPage.getByLabel('Team Email').fill(teamEmail)
    await authenticatedPage.getByLabel('xMatter Group').fill(`XM-${runId.slice(-6).toUpperCase()}`)
    await authenticatedPage.getByLabel('GSD Group').fill(`GSD-${runId.slice(-6).toUpperCase()}`)
    await authenticatedPage.getByLabel('EIM ID').fill(`EIM-${runId.slice(-4)}`)
    await authenticatedPage.getByLabel('Tag').fill('Upstream')
    await authenticatedPage.keyboard.press('Enter')
    await authenticatedPage.getByLabel('Staff IDs', { exact: true }).fill(primaryUser.staffId)
    await authenticatedPage.getByLabel('Other Information').fill(otherInfoUrl)
    await authenticatedPage.getByRole('button', { name: 'Save Team' }).click()

    await expect(authenticatedPage).toHaveURL(/\/contact-information(?:\?|$)/)
    await expect(authenticatedPage.getByText('Team saved successfully.')).toBeVisible()

    await authenticatedPage.getByLabel('Search teams, staff IDs, or links').fill(teamName)
    const createdRow = authenticatedPage.locator('tbody tr', {
      has: authenticatedPage.getByRole('cell', { name: teamName }),
    })
    await expect(createdRow.getByRole('cell', { name: teamName })).toBeVisible()
    await expect(createdRow.getByRole('link', { name: 'Other' })).toHaveAttribute('href', otherInfoUrl)
  })
})
