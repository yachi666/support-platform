import { expect } from '@playwright/test'
import { gotoApp } from '../helpers/route-assertions.mjs'

const WORKSPACE_BRAND = /(排班工作台|Roster Workspace|Support Roster Workspace)/
const LOGOUT_BUTTON = /^(退出登录|Logout)$/

export class WorkspaceShellPage {
  constructor(page) {
    this.page = page
  }

  async goto(path = '/workspace') {
    await gotoApp(this.page, path)
  }

  async expectShellLoaded() {
    await expect(this.page.getByText(WORKSPACE_BRAND).first()).toBeVisible()
    await expect(this.page.getByRole('button', { name: LOGOUT_BUTTON })).toBeVisible()
  }

  async expectNavItem(name) {
    await expect(this.page.getByRole('link', { name })).toBeVisible()
  }

  async expectNavItemCount(name, count) {
    const link = this.page.getByRole('link', { name })
    await expect(link).toBeVisible()
    await expect(link.getByText(String(count), { exact: true })).toBeVisible()
  }
}
