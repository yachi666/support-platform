import { env, requirePrimaryUser } from '../config/env.mjs'

async function check(url, label) {
  try {
    const response = await fetch(url)
    return { label, ok: response.ok, status: response.status }
  } catch (error) {
    return { label, ok: false, status: 'unreachable', error: error.message }
  }
}

async function main() {
  requirePrimaryUser()

  const checks = await Promise.all([
    check(env.baseUrl, 'frontend'),
    check(`${env.apiBaseUrl}/workspace/access-policy`, 'backend-public-api'),
  ])

  let hasFailure = false
  for (const item of checks) {
    const suffix = item.error ? ` (${item.error})` : ''
    console.log(`[precheck] ${item.label}: ${item.status}${suffix}`)
    if (!item.ok) {
      hasFailure = true
    }
  }

  if (hasFailure) {
    process.exitCode = 1
  }
}

main().catch((error) => {
  console.error('[precheck] unexpected failure:', error)
  process.exit(1)
})
