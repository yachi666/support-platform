import { env } from '../config/env.mjs'

function getBearerToken(token) {
  const normalizedToken = String(token || '').trim().replace(/^Bearer\s+/i, '')

  if (!normalizedToken) {
    throw new Error('Workspace access policy request requires a token.')
  }

  return `Bearer ${normalizedToken}`
}

async function requestWorkspaceAccessPolicy(token, options = {}) {
  const { method = 'GET', body } = options
  const response = await fetch(`${env.apiBaseUrl}/workspace/access-policy`, {
    method,
    headers: {
      Authorization: getBearerToken(token),
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  })

  if (!response.ok) {
    const payload = await response.text()
    throw new Error(`Workspace access policy request failed (${response.status}): ${payload}`)
  }

  return response.json()
}

export function toConfigurableWorkspaceAccessPolicyPayload(pages = []) {
  return (Array.isArray(pages) ? pages : [])
    .filter((page) => page?.configurable)
    .map((page) => ({
      pageCode: page.pageCode,
      authRequired: Boolean(page.authRequired),
    }))
}

export async function getWorkspaceAccessPolicy(token) {
  return requestWorkspaceAccessPolicy(token)
}

export async function updateWorkspaceAccessPolicy(token, pages) {
  return requestWorkspaceAccessPolicy(token, {
    method: 'PUT',
    body: { pages },
  })
}
