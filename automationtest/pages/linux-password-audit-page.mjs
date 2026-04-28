import { expect } from '@playwright/test'
import { gotoApp } from '../helpers/route-assertions.mjs'

const AUDIT_HEADING = /^(Linux Password Access Audit|Linux 密码访问审计)$/

export class LinuxPasswordAuditPage {
  constructor(page) {
    this.page = page
  }

  async goto() {
    await gotoApp(this.page, '/linux-passwords/audits')
  }

  async expectLoaded() {
    await expect(this.page.getByRole('heading', { name: AUDIT_HEADING })).toBeVisible()
  }

  async expectAuditRecordForHost(hostname) {
    await expect(
      this.page.locator('table tbody tr').filter({ hasText: hostname }).first(),
    ).toBeVisible()
  }

  async expectAuditRecordWithAction(hostname, action) {
    const row = this.page.locator('table tbody tr').filter({ hasText: hostname }).first()
    await expect(row).toBeVisible()
    await expect(row).toContainText(action)
  }

  async expectSidebarLinkVisible(page) {
    await expect(
      page.getByRole('link', { name: /^(Audit Records|审计记录)$/ }),
    ).toBeVisible()
  }
}
