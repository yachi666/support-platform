import { config as loadDotenv } from 'dotenv'

loadDotenv()

function readEnv(name, fallback = '') {
  const value = process.env[name]
  return value == null ? fallback : String(value).trim()
}

function readInt(name, fallback) {
  const value = Number.parseInt(readEnv(name, String(fallback)), 10)
  return Number.isFinite(value) ? value : fallback
}

function buildRoleCredential(prefix) {
  return {
    staffId: readEnv(`${prefix}_STAFF_ID`),
    password: readEnv(`${prefix}_PASSWORD`),
  }
}

export const env = {
  baseUrl: readEnv('AUTOTEST_BASE_URL', 'http://127.0.0.1:5173'),
  apiBaseUrl: readEnv('AUTOTEST_API_BASE_URL', 'http://127.0.0.1:8080/api'),
  dbUrl: readEnv('AUTOTEST_DB_URL', 'postgresql://localhost:5432/support'),
  defaultTimeoutMs: readInt('AUTOTEST_DEFAULT_TIMEOUT_MS', 15000),
  trace: readEnv('AUTOTEST_TRACE', 'retain-on-failure'),
  workers: readInt('AUTOTEST_WORKERS', 1),
  expectedTeamName: readEnv('AUTOTEST_EXPECTED_TEAM_NAME'),
  expectedWorkspaceTitle: readEnv('AUTOTEST_EXPECTED_WORKSPACE_TITLE', '排班工作台'),
  primaryUser: {
    staffId: readEnv('AUTOTEST_STAFF_ID'),
    password: readEnv('AUTOTEST_PASSWORD'),
  },
  roles: {
    admin: buildRoleCredential('AUTOTEST_ADMIN'),
    editor: buildRoleCredential('AUTOTEST_EDITOR'),
    readonly: buildRoleCredential('AUTOTEST_READONLY'),
  },
}

export function requirePrimaryUser() {
  if (!env.primaryUser.staffId || !env.primaryUser.password) {
    throw new Error(
      'AUTOTEST_STAFF_ID and AUTOTEST_PASSWORD are required for authenticated smoke tests.',
    )
  }

  return env.primaryUser
}

export function hasRoleCredential(roleName) {
  const role = env.roles[roleName]
  return Boolean(role?.staffId && role?.password)
}
