import { test, expect } from '../../fixtures/test.fixture.mjs'
import { gotoApp } from '../../helpers/route-assertions.mjs'

test.describe('contact information public list', () => {
  test('public contact information list loads without login', async ({ page }) => {
    await gotoApp(page, '/contact-information')

    await expect(page.getByRole('heading', { name: 'System Teams' })).toBeVisible()
    await expect(page.getByLabel('Search teams, staff IDs, or links')).toBeVisible()
    await expect(page.getByText(/Showing \d+ to \d+ of \d+ entries/)).toBeVisible()
  })
})
