import { env, requirePrimaryUser } from '../config/env.mjs'
import { loginByApi } from './api-auth.mjs'

function normalizePath(path) {
  return path.startsWith('/') ? path : `/${path}`
}

function buildUrl(path, query) {
  const url = new URL(`${env.apiBaseUrl}${normalizePath(path)}`)

  if (query && typeof query === 'object') {
    for (const [key, value] of Object.entries(query)) {
      if (value == null || value === '') {
        continue
      }

      url.searchParams.set(key, String(value))
    }
  }

  return url
}

function extractBearerToken(session) {
  const rawToken = String(session?.token || '').trim()
  const token = rawToken.replace(/^Bearer\s+/i, '')

  if (!token) {
    throw new Error('Login response did not contain a JWT token.')
  }

  return token
}

async function requestJson({ token, method = 'GET', path, query, body }) {
  const response = await fetch(buildUrl(path, query), {
    method,
    headers: {
      Accept: 'application/json',
      Authorization: `Bearer ${token}`,
      ...(body == null ? {} : { 'Content-Type': 'application/json' }),
    },
    body: body == null ? undefined : JSON.stringify(body),
  })

  const rawText = await response.text()
  const payload = rawText ? JSON.parse(rawText) : null

  if (!response.ok) {
    throw new Error(`${method} ${normalizePath(path)} failed (${response.status}): ${rawText || response.statusText}`)
  }

  return payload
}

export async function createWorkspaceApiClient(credentials = requirePrimaryUser()) {
  const session = await loginByApi(credentials)
  const token = extractBearerToken(session)

  return {
    token,
    session,
    request(method, path, options = {}) {
      return requestJson({
        token,
        method,
        path,
        query: options.query,
        body: options.body,
      })
    },
    getValidation(year, month, options = {}) {
      return requestJson({
        token,
        method: 'GET',
        path: '/workspace/validation',
        query: {
          year,
          month,
          summaryOnly: options.summaryOnly ? 'true' : undefined,
        },
      })
    },
    getOverview(year, month) {
      return requestJson({
        token,
        method: 'GET',
        path: '/workspace/overview',
        query: { year, month },
      })
    },
    createTeam(payload) {
      return requestJson({
        token,
        method: 'POST',
        path: '/workspace/teams',
        body: payload,
      })
    },
    deleteTeam(teamId) {
      return requestJson({
        token,
        method: 'DELETE',
        path: `/workspace/teams/${teamId}`,
      })
    },
    createStaff(payload) {
      return requestJson({
        token,
        method: 'POST',
        path: '/workspace/staff',
        body: payload,
      })
    },
    deleteStaff(staffId) {
      return requestJson({
        token,
        method: 'DELETE',
        path: `/workspace/staff/${staffId}`,
      })
    },
    createShiftDefinition(payload) {
      return requestJson({
        token,
        method: 'POST',
        path: '/workspace/shift-definitions',
        body: payload,
      })
    },
    deleteShiftDefinition(shiftDefinitionId) {
      return requestJson({
        token,
        method: 'DELETE',
        path: `/workspace/shift-definitions/${shiftDefinitionId}`,
      })
    },
    saveRoster(payload) {
      return requestJson({
        token,
        method: 'POST',
        path: '/workspace/roster/save',
        body: payload,
      })
    },
    getLinuxPasswords(options = {}) {
      return requestJson({
        token,
        method: 'GET',
        path: '/workspace/linux-passwords',
        query: {
          search: options.search || undefined,
          businessUnit: options.businessUnit || undefined,
        },
      })
    },
    getLinuxPasswordAudits(filters = {}) {
      return requestJson({
        token,
        method: 'GET',
        path: '/workspace/linux-passwords/access-audits',
        query: filters,
      })
    },
  }
}
