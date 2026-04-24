import { test as base } from '@playwright/test'
import { CleanupRegistry } from '../helpers/cleanup-registry.mjs'
import { createWorkspaceApiClient } from '../helpers/workspace-api.mjs'
import { env } from '../config/env.mjs'

export const test = base.extend({
  cleanupRegistry: async ({}, use) => {
    const registry = new CleanupRegistry()
    await use(registry)
    await registry.runAll()
  },

  workspaceApi: async ({}, use) => {
    const apiClient = await createWorkspaceApiClient()
    await use(apiClient)
  },

  authenticatedPage: async ({ browser, cleanupRegistry, workspaceApi }, use) => {
    const token = workspaceApi.token

    const context = await browser.newContext({
      baseURL: env.baseUrl,
    })

    await context.addInitScript((value) => {
      window.localStorage.setItem('support-roster-auth-token', value)
    }, token)

    const page = await context.newPage()
    cleanupRegistry.add('close-authenticated-context', () => context.close())

    await use(page)
  },
})

export { expect } from '@playwright/test'
