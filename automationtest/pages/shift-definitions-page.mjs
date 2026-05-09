import { expect } from '@playwright/test'

export class ShiftDefinitionsPage {
  constructor(page) {
    this.page = page
  }

  async expectFocusedShift(code) {
    const row = this.page.locator('[data-workspace-shift-id].bg-amber-50').first()
    await expect(row).toBeVisible()
    await expect(row).toContainText(code)
  }
}
