import { expect } from '@playwright/test'
import { gotoApp } from '../helpers/route-assertions.mjs'

const TEAMS_HEADING = /^(团队管理|Team Management)$/

export class TeamsPage {
  constructor(page) {
    this.page = page
  }

  async goto() {
    await gotoApp(this.page, '/workspace/teams')
  }

  async expectLoaded() {
    await expect(this.page.getByRole('heading', { name: TEAMS_HEADING })).toBeVisible()
  }
}
