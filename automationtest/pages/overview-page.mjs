import { expect } from '@playwright/test'

export class OverviewPage {
  constructor(page) {
    this.page = page
  }

  async expectLoaded() {
    await expect(this.page.getByRole('heading', { name: /Monthly Roster Overview|总览|排班总览/ })).toBeVisible()
  }
}
