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
}
