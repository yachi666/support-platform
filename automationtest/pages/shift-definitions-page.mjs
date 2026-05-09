import { expect } from '@playwright/test'
import { gotoApp } from '../helpers/route-assertions.mjs'

export class ShiftDefinitionsPage {
  constructor(page) {
    this.page = page
  }

  shiftRow(code) {
    return this.page.locator('[data-workspace-shift-id]').filter({
      has: this.page.getByText(code, { exact: true }),
    }).first()
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

  async expectFocusedShift(code) {
    const row = this.shiftRow(code)
    await expect(row).toBeVisible()
    await expect(row).toHaveClass(/bg-amber-50/)
  }

  async openShift(code) {
    const row = this.shiftRow(code)
    const shiftCodeChip = row.getByText(code, { exact: true })
    const dialog = this.page.getByRole('dialog')

    if (await dialog.isVisible().catch(() => false)) {
      await this.page.getByRole('button', { name: /^(Close drawer|关闭抽屉)$/ }).click()
      await expect(dialog).toBeHidden()
    }

    await expect(shiftCodeChip).toBeVisible()
    await shiftCodeChip.click()
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
