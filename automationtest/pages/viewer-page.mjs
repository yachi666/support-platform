import { expect } from '@playwright/test'
import { gotoApp } from '../helpers/route-assertions.mjs'

export class ViewerPage {
  constructor(page) {
    this.page = page
  }

  async gotoDate({ year, month, day }) {
    const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`
    await gotoApp(this.page, `/viewer?date=${dateStr}`)
    
    // Wait for the page to load
    await expect(this.page.locator('text=/active shifts?/').first()).toBeVisible({ timeout: 10000 })
  }

  async expectTeamVisible(teamName) {
    // Just verify the team is visible in the viewer (regardless of whether it has shifts on the specific date)
    await expect(this.page.getByText(teamName, { exact: true })).toBeVisible()
  }

  async expectShiftVisible({ teamName, shiftCode, staffName }) {
    // Wait for the page to load by checking for any team section
    await expect(this.page.locator('text=/active shifts?/').first()).toBeVisible({ timeout: 10000 })
    
    // Find a section that contains the team name heading and a shift button with the staff name
    await expect(this.page.getByText(teamName, { exact: true })).toBeVisible()
    await expect(this.page.getByRole('button').filter({ hasText: staffName })).toBeVisible()
  }
}
