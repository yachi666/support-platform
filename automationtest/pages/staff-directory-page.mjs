import { expect } from '@playwright/test'

export class StaffDirectoryPage {
  constructor(page) {
    this.page = page
  }

  async expectFocusedStaff(name) {
    const row = this.page.locator('[data-workspace-staff-id].bg-amber-50').first()
    await expect(row).toBeVisible()
    await expect(row).toContainText(name)
  }
}
