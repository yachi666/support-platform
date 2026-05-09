import { expect } from '@playwright/test'
import { gotoApp } from '../helpers/route-assertions.mjs'

const VALIDATION_HEADING = /^(校验中心|Validation Center)$/

export class ValidationPage {
  constructor(page) {
    this.page = page
  }

  issueCard(issueOrType) {
    const issue = typeof issueOrType === 'string' ? { type: issueOrType } : issueOrType
    let card = this.page.locator('article').filter({
      has: this.page.getByRole('heading', { name: issue.type, exact: true }),
    })

    const teamName = issue.teamName ?? issue.team
    if (teamName && teamName !== '-') {
      card = card.filter({ hasText: teamName })
    }

    const dateLabel = issue.dateLabel ?? issue.date
    if (dateLabel && dateLabel !== '-') {
      card = card.filter({ hasText: dateLabel })
    }

    if (issue.description) {
      card = card.filter({ hasText: issue.description })
    }

    return card.first()
  }

  async goto() {
    await gotoApp(this.page, '/workspace/validation')
  }

  async expectLoaded() {
    await expect(this.page.getByRole('heading', { name: VALIDATION_HEADING })).toBeVisible()
  }

  async gotoWithQuery(query = '') {
    await gotoApp(this.page, `/workspace/validation${query}`)
  }

  async expectBlockingIssue(issue) {
    await expect(this.page.getByText(issue.type, { exact: true }).first()).toBeVisible()
    await expect(this.page.getByText(issue.teamName, { exact: true }).first()).toBeVisible()
    await expect(this.page.getByText(/^(Blocking|阻塞)$/).first()).toBeVisible()
  }

  async expectIssueVisible(issue) {
    const card = this.issueCard(issue)

    await expect(card).toBeVisible()
    await expect(card.getByText(issue.type, { exact: true })).toBeVisible()

    if (issue.teamName && issue.teamName !== '-') {
      await expect(card).toContainText(issue.teamName)
    }
  }

  async expectIssueNotVisible(issueType) {
    await expect(this.issueCard(issueType)).toHaveCount(0)
  }

  async expectSelectionControlsAvailable() {
    await expect(this.page.locator('#workspace-validation-search')).toBeVisible()
    await expect.poll(async () => this.page.locator('article input[type="checkbox"]').count()).toBeGreaterThan(0)
    await expect(this.page.getByRole('button', { name: /^(Resolve Selected|解决所选)/ })).toBeVisible()
    await expect(this.page.getByText(/^(Open issues|待处理问题)$/)).toBeVisible()
  }

  async selectVisibleIssues() {
    await this.page.getByRole('button', { name: /^(Select visible|选择当前可见项|Clear visible selection|清除当前可见选择)$/ }).click()
  }

  async resolveSelectedIssues() {
    await this.page.getByRole('button', { name: /^(Resolve Selected|解决所选)/ }).click()
  }

  async expectSelectedCount(count) {
    await expect(this.page.getByText(new RegExp(`(^${count} selected$|^${count} 条已选$)`))).toBeVisible()
  }

  async openFixNow(issueOrType) {
    await this.issueCard(issueOrType).getByRole('button', { name: /^(Fix now|立即修复)$/ }).click()
  }

  async expectIssueCount(count) {
    await expect(this.page.locator('article')).toHaveCount(count)
  }

  async expectRemediationPreview(issue) {
    const dialog = this.page.getByRole('dialog', { name: /^(确认清理动作|Review cleanup action)$/ })

    await expect(dialog).toBeVisible()
    await expect(dialog).toContainText(issue.type)
    await expect(dialog.getByText(String(issue.remediation.recordCount), { exact: true })).toBeVisible()
    await expect(dialog.getByText(new RegExp(String(issue.remediation.recordId)))).toBeVisible()
  }

  async confirmRemediation() {
    await this.page.getByRole('button', { name: /^(delete records?|删除记录)$/i }).click()
  }

  async expectCleanupSuccessToast() {
    await expect(this.page.getByText(/removed 1 invalid record|已通过校验清理删除 1 条无效记录/i)).toBeVisible()
  }

  async expectEmptyInbox() {
    await expect(this.page.getByText(/^(当前校验队列为空|Validation queue is currently clear)$/)).toBeVisible()
    await expect(this.page.getByText(/^(当前筛选条件下没有匹配的校验问题。|No validation issues matched the current filter\.)$/)).toBeVisible()
  }

  async expectBulkFixEnabled() {
    await expect(this.page.getByRole('button', { name: /^(Resolve Selected|解决所选)/ })).toBeEnabled()
  }

  async openRelatedArea(issueOrType) {
    await this.issueCard(issueOrType).getByRole('link', { name: /^(Open related area|打开相关区域)$/ }).click()
  }
}
