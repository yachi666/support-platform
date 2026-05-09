import { expect } from '@playwright/test'
import { gotoApp } from '../helpers/route-assertions.mjs'

export class ViewerPage {
  constructor(page) {
    this.page = page
  }

  async gotoDate({ year, month, day, timezone }) {
    const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`
    await gotoApp(this.page, '/viewer')

    const dateInput = this.page.locator('input[type="date"]')
    const timezoneSelect = this.page.getByRole('combobox')

    await expect(dateInput).toBeVisible()

    if (timezone && (await timezoneSelect.inputValue()) !== timezone) {
      await Promise.all([
        this.page.waitForResponse(
          (response) => response.ok() && response.url().includes('/api/shifts?'),
        ),
        timezoneSelect.selectOption(timezone),
      ])
      await expect(timezoneSelect).toHaveValue(timezone)
    }

    await Promise.all([
      this.page.waitForResponse(
        (response) =>
          response.ok() &&
          response.url().includes('/api/shifts?') &&
          response.url().includes(`date=${dateStr}`),
      ),
      dateInput.fill(dateStr),
    ])

    await expect(dateInput).toHaveValue(dateStr)
  }

  async expectVisibleNonPrimaryShift({ teamName, staffName, shiftLabel }) {
    const shiftCard = this.page.getByRole('button', { name: `${staffName} ${shiftLabel}` })

    await expect(this.page.getByText(teamName, { exact: true })).toBeVisible()
    await expect(shiftCard).toBeVisible()
    await expect(shiftCard).toContainText(staffName)

    await shiftCard.hover()

    await expect(this.page.getByText(shiftLabel, { exact: true })).toBeVisible()
    await expect(this.page.getByText('Secondary Support', { exact: true })).toBeVisible()
  }
}
