import { expect } from '@playwright/test'
import { gotoApp } from '../helpers/route-assertions.mjs'

const SIGN_IN_TAB = /^(登录|Sign in)$/
const SIGN_IN_BUTTON = /^(登录|Sign in)$/
const ACTIVATION_TAB = /^(首次激活|First-time activation)$/
const LOGIN_HEADING = /^(使用员工 ID 登录|Sign in with your staff ID)$/

export class LoginPage {
  constructor(page) {
    this.page = page
  }

  async goto() {
    await gotoApp(this.page, '/login')
  }

  async switchToActivation() {
    await this.page.getByRole('button', { name: ACTIVATION_TAB }).click()
  }

  async switchToLogin() {
    await this.page.getByRole('button', { name: SIGN_IN_TAB }).first().click()
  }

  async login({ staffId, password }) {
    await this.switchToLogin()
    await this.page.locator('input[autocomplete="username"]').fill(staffId)
    await this.page.locator('input[autocomplete="current-password"]').fill(password)
    await this.page.locator('form').getByRole('button', { name: SIGN_IN_BUTTON }).click()
  }

  async expectLoaded() {
    await expect(this.page.getByRole('heading', { name: LOGIN_HEADING })).toBeVisible()
  }
}
