import { env } from '../config/env.mjs'

export async function loginByApi(credentials) {
  const response = await fetch(`${env.apiBaseUrl}/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      staffId: credentials.staffId,
      password: credentials.password,
    }),
  })

  if (!response.ok) {
    const payload = await response.text()
    throw new Error(`API login failed (${response.status}): ${payload}`)
  }

  return response.json()
}

export async function activateByApi(payload) {
  const response = await fetch(`${env.apiBaseUrl}/auth/activate`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  })

  if (!response.ok) {
    const body = await response.text()
    throw new Error(`API activation failed (${response.status}): ${body}`)
  }

  return response.json()
}
