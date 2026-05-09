import { expect } from '@playwright/test'
import { gotoApp } from '../helpers/route-assertions.mjs'

export class ShiftDefinitionsPage {
  constructor(page) {
    this.page = page
  }

  async gotoWithQuery(query = '') {
    await gotoApp(this.page, `/workspace/shifts${query}`)
  }

  async expectFocusedShiftRoute(shiftId) {
    await expect.poll(() => {
      const url = new URL(this.page.url())
      return url.searchParams.get('focusShiftId')
    }).toBe(String(shiftId))
  }

  async expectShiftDrawerVisible(code) {
    const dialog = this.page.getByRole('dialog')
    await expect(dialog).toBeVisible()
    await expect(dialog.getByRole('textbox', { name: 'Shift Code' })).toHaveValue(code)
  }

  async expectLoadError(messagePattern = /Shift duration must be between 1 and 1440 minutes\./) {
    await expect(this.page.getByRole('heading', { name: /^(Shift Definitions|班次定义)$/ })).toBeVisible()
    await expect(this.page.getByText(messagePattern)).toBeVisible()
  }
}
