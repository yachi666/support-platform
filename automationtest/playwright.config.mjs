import { defineConfig, devices } from '@playwright/test'
import { env } from './config/env.mjs'
import { browserProjects } from './config/projects.mjs'

export default defineConfig({
  testDir: './specs',
  fullyParallel: false,
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 1 : 0,
  workers: env.workers,
  timeout: env.defaultTimeoutMs * 3,
  reporter: [['list'], ['html', { open: 'never', outputFolder: 'artifacts/report' }]],
  outputDir: 'artifacts/test-results',
  use: {
    baseURL: env.baseUrl,
    trace: env.trace,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: env.defaultTimeoutMs,
    navigationTimeout: env.defaultTimeoutMs,
  },
  projects: browserProjects.length
    ? browserProjects
    : [
        {
          name: 'chromium',
          use: {
            ...devices['Desktop Chrome'],
          },
        },
      ],
})
