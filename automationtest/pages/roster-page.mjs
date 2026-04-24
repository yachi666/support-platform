import { expect } from '@playwright/test'
import { gotoApp } from '../helpers/route-assertions.mjs'

const ROSTER_HEADING = /^(Monthly Roster|月排班|排班表)$/

export class RosterPage {
  constructor(page) {
    this.page = page
  }

  async goto(query = '') {
    await gotoApp(this.page, `/workspace/roster${query}`)
  }

  async expectLoaded() {
    await expect(this.page.getByText(ROSTER_HEADING).first()).toBeVisible()
  }

  async expectValidationWarning(description) {
    await expect(this.page.getByText(description).first()).toBeVisible()
  }

  async fillTopbarSearch(value) {
    await this.page.locator('#workspace-topbar-search').fill(value)
  }

  async fillPageSearch(value) {
    await this.page.locator('#workspace-roster-search').fill(value)
  }

  async expectSearchInputsSynced(value) {
    await expect(this.page.locator('#workspace-topbar-search')).toHaveValue(value)
    await expect(this.page.locator('#workspace-roster-search')).toHaveValue(value)
  }

  async openTeamFilter() {
    await this.page.getByRole('button', { name: /^(Teams \(All\)|团队（全部）|Teams \(\d+\)|团队（\d+）)$/ }).click()
  }

  async expectTeamFilterOptionVisible(teamName) {
    const option = this.page.locator('label').filter({ hasText: teamName }).first()
    const isVisible = await option.isVisible().catch(() => false)
    if (!isVisible) {
      await this.openTeamFilter()
    }
    await expect(option).toBeVisible()
  }

  async toggleTeamFilter(teamName) {
    const option = this.page.locator('label').filter({ hasText: teamName }).first()
    const isVisible = await option.isVisible().catch(() => false)
    if (!isVisible) {
      await this.openTeamFilter()
    }
    await option.click()
  }

  async expectTeamVisible(teamName) {
    await expect(this.page.locator('tbody tr').filter({ hasText: teamName }).first()).toBeVisible()
  }

  async expectStaffVisible(name) {
    await expect(this.page.getByText(name, { exact: true }).first()).toBeVisible()
  }

  async expectStaffNotVisible(name) {
    await expect(this.page.getByText(name, { exact: true })).toHaveCount(0)
  }

  async expectEmptyFilteredResult() {
    await expect(this.page.locator('table')).toHaveCount(0)
  }

  async expectStaffNamesOrderedTopToBottom(expectedNames) {
    let previousY = null

    for (const name of expectedNames) {
      const locator = this.page.getByText(name, { exact: true }).first()
      await expect(locator).toBeVisible()
      const box = await locator.boundingBox()
      expect(box).not.toBeNull()

      if (previousY != null) {
        expect(box.y).toBeGreaterThan(previousY)
      }

      previousY = box.y
    }
  }
}
