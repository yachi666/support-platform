import { execFile } from 'node:child_process'
import { promisify } from 'node:util'
import { env } from '../config/env.mjs'

const execFileAsync = promisify(execFile)

function requireDbUrl() {
  const dbUrl = String(env.dbUrl || '').trim()

  if (!dbUrl) {
    throw new Error('AUTOTEST_DB_URL is required for DB-backed validation corruption seeds.')
  }

  return dbUrl
}

function buildPsqlArgs(sql) {
  return [
    '-v',
    'ON_ERROR_STOP=1',
    requireDbUrl(),
    '-F',
    '\t',
    '-Atc',
    sql,
  ]
}

async function runPsql(sql) {
  try {
    const { stdout } = await execFileAsync('psql', buildPsqlArgs(sql), {
      env: process.env,
      maxBuffer: 1024 * 1024 * 8,
    })

    return stdout.trim()
  } catch (error) {
    const detail = [error.stderr, error.stdout, error.message].filter(Boolean).join('\n').trim()
    throw new Error(`psql execution failed: ${detail}`)
  }
}

export function escapeSqlLiteral(value) {
  return String(value).replace(/'/g, "''")
}

export async function executeSql(sql) {
  await runPsql(sql)
}

export async function queryRows(sql, columns = []) {
  const output = await runPsql(sql)

  if (!output) {
    return []
  }

  const rows = output
    .split(/\r?\n/)
    .filter(Boolean)
    .map((line) => line.split('\t'))

  if (!columns.length) {
    return rows
  }

  return rows.map((fields) =>
    Object.fromEntries(columns.map((column, index) => [column, fields[index] ?? null])),
  )
}

export async function queryOne(sql, columns = []) {
  const [row] = await queryRows(sql, columns)
  return row ?? null
}
