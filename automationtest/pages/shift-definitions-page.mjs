import { expect } from '@playwright/test'

export class ShiftDefinitionsPage {
  constructor(page) {
    this.page = page
  }

  async expectFocusedShiftRoute(shiftId) {
    await expect.poll(() => {
      const url = new URL(this.page.url())
      return url.searchParams.get('focusShiftId')
    }).toBe(String(shiftId))
  }

  async expectLoadError(messagePattern = /Shift duration must be between 1 and 1440 minutes\./) {
    await expect(this.page.getByRole('heading', { name: /^(Shift Definitions|班次定义)$/ })).toBeVisible()
    await expect(this.page.getByText(messagePattern)).toBeVisible()
  }

  async expectFocusedShift(code) {
    const row = this.page.locator('[data-workspace-shift-id].bg-amber-50').first()
    await expect(row).toBeVisible()
    await expect(row).toContainText(code)
  }
}
