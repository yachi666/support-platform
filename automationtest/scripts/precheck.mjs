import { env, requirePrimaryUser } from '../config/env.mjs'

async function check(url, label) {
  try {
    const response = await fetch(url)
    return { label, ok: response.ok, status: response.status }
  } catch (error) {
    return { label, ok: false, status: 'unreachable', error: error.message }
  }
}

async function postJson(url, payload) {
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    })

    const rawBody = await response.text()
    let parsedBody = null
    try {
      parsedBody = rawBody ? JSON.parse(rawBody) : null
    } catch {
      parsedBody = null
    }

    return {
      ok: response.ok,
      status: response.status,
      body: parsedBody,
      rawBody,
    }
  } catch (error) {
    return {
      ok: false,
      status: 'unreachable',
      error: error.message,
      body: null,
      rawBody: '',
    }
  }
}

function extractMessage(result) {
  if (result?.body?.message) {
    return result.body.message
  }

  return result?.rawBody || result?.error || ''
}

function buildInitAdminHint(primaryUser) {
  if (primaryUser.staffId === 'admin') {
    return 'Detected a first-run local database. Run ../scripts/dev/init-admin.sh to create and activate admin/admin before browser tests.'
  }

  return `If this is a fresh local database, run ../scripts/dev/init-admin.sh or override ADMIN_STAFF_ID/ADMIN_PASSWORD to bootstrap ${primaryUser.staffId}.`
}

async function checkPrimaryUser(primaryUser) {
  const loginResult = await postJson(`${env.apiBaseUrl}/auth/login`, {
    staffId: primaryUser.staffId,
    password: primaryUser.password,
  })

  if (loginResult.ok) {
    return {
      label: 'auth-login',
      ok: true,
      status: loginResult.status,
    }
  }

  const message = extractMessage(loginResult)
  const shouldSuggestInitAdmin = [
    'Account does not exist for the provided staff ID.',
    'Account password has not been initialized. Please use first-time activation.',
  ].includes(message)

  return {
    label: 'auth-login',
    ok: false,
    status: loginResult.status,
    error: message || 'Login probe failed.',
    hint: shouldSuggestInitAdmin ? buildInitAdminHint(primaryUser) : null,
  }
}

async function main() {
  const primaryUser = requirePrimaryUser()

  const checks = await Promise.all([
    check(env.baseUrl, 'frontend'),
    check(`${env.apiBaseUrl}/workspace/access-policy`, 'backend-public-api'),
    checkPrimaryUser(primaryUser),
  ])

  let hasFailure = false
  for (const item of checks) {
    const suffix = item.error ? ` (${item.error})` : ''
    console.log(`[precheck] ${item.label}: ${item.status}${suffix}`)
    if (item.hint) {
      console.log(`[precheck] hint: ${item.hint}`)
    }
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
