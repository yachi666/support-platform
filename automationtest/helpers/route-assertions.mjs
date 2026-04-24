import { expect } from '@playwright/test'

export async function gotoApp(page, path) {
  await page.goto(path, { waitUntil: 'domcontentloaded' })
}

export async function expectRedirectToLogin(page) {
  await expect(page).toHaveURL(/\/login/)
}

export async function expectWorkspaceShell(page) {
  await expect(page.getByText('排班工作台').first()).toBeVisible()
  await expect(page.getByRole('button', { name: '退出登录' })).toBeVisible()
}
