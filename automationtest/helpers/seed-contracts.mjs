import { expect } from '@playwright/test'
import { env, requirePrimaryUser } from '../config/env.mjs'
import { escapeSqlLiteral, executeSql, queryOne } from './postgres-cli.mjs'
import { gotoApp } from './route-assertions.mjs'

const VALIDATION_SCENARIO_PREFIX = 'AUTOTEST-VALIDATION'
const ROSTER_SCENARIO_PREFIX = 'AUTOTEST-ROSTER'

export async function assertManualEnvironmentReady({ page }) {
  await gotoApp(page, '/login')
  await expect(page.locator('input[autocomplete="username"]')).toBeVisible()
}

export async function assertKnownTeamIfConfigured({ page }) {
  if (!env.expectedTeamName) {
    return
  }

  await expect(page.getByRole('heading', { name: env.expectedTeamName })).toBeVisible()
}

function buildRunId() {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
}

function buildSyntheticId(runId, suffix) {
  const digits = runId.replace(/\D/g, '').slice(-10).padStart(10, '0')
  return `29${digits}${String(suffix).padStart(2, '0')}`
}

function pickFutureMonth(offsetSeed = Date.now()) {
  const reference = new Date()
  const futureOffsetMonths = 18 + (Number(offsetSeed) % 12)
  const future = new Date(reference.getFullYear(), reference.getMonth() + futureOffsetMonths, 1)

  return {
    year: future.getFullYear(),
    month: future.getMonth() + 1,
    day: 11,
    timezone: 'UTC',
  }
}

function formatValidationDateLabel(year, month, day) {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: '2-digit',
    timeZone: 'UTC',
  }).format(new Date(Date.UTC(year, month - 1, day)))
}

function formatValidationDateApiLabel(year, month, day) {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    timeZone: 'UTC',
  }).format(new Date(Date.UTC(year, month - 1, day)))
}

function buildWorkspaceQuery({ year, month, timezone }) {
  const params = new URLSearchParams({
    wy: String(year),
    wm: String(month),
    wtz: timezone,
  })

  return `?${params.toString()}`
}

function withCleanupGuard(action) {
  return async () => {
    try {
      await action()
    } catch (error) {
      if (/failed \(404\)/i.test(error.message)) {
        return
      }
      throw error
    }
  }
}

export async function seedMissingPrimaryCoverageScenario({ cleanupRegistry, workspaceApi }) {
  if (!workspaceApi) {
    throw new Error('workspaceApi is required for validation seeding.')
  }

  const runId = buildRunId()
  const targetMonth = pickFutureMonth(runId.replace(/\D/g, '').slice(-6))
  const teamName = `${VALIDATION_SCENARIO_PREFIX} ${runId}`
  const staffId = `ATV${String(Date.now()).slice(-8)}${Math.floor(Math.random() * 10)}`
  const supportShiftCode = `AT-S-${runId.slice(-6).toUpperCase()}`
  const primaryShiftCode = `AT-P-${runId.slice(-6).toUpperCase()}`

  const team = await workspaceApi.createTeam({
    name: teamName,
    color: '#0f766e',
    displayOrder: 999,
    visible: true,
    description: 'Automation test seed for workspace validation regression.',
  })
  cleanupRegistry.add(`delete-team-${team.id}`, withCleanupGuard(() => workspaceApi.deleteTeam(team.id)))

  const staff = await workspaceApi.createStaff({
    staffId,
    name: `Validation Seed ${runId.slice(-4)}`,
    email: `${staffId.toLowerCase()}@example.test`,
    region: 'Automation',
    timezone: 'UTC',
    roleName: 'QA Seed',
    teamId: team.id,
    status: 'Active',
    notes: 'Created by automation validation regression.',
  })
  cleanupRegistry.add(`delete-staff-${staff.id}`, withCleanupGuard(() => workspaceApi.deleteStaff(staff.id)))

  const primaryShift = await workspaceApi.createShiftDefinition({
    teamIds: [team.id],
    code: primaryShiftCode,
    meaning: 'Primary automation coverage',
    startTime: '08:00:00',
    durationMinutes: 480,
    timezone: 'UTC',
    primaryShift: true,
    visible: true,
    colorHex: '#0f766e',
    remark: 'Automation validation seed primary shift.',
  })
  cleanupRegistry.add(
    `delete-shift-${primaryShift.id}`,
    withCleanupGuard(() => workspaceApi.deleteShiftDefinition(primaryShift.id)),
  )

  const supportShift = await workspaceApi.createShiftDefinition({
    teamIds: [team.id],
    code: supportShiftCode,
    meaning: 'Secondary automation coverage',
    startTime: '12:00:00',
    durationMinutes: 480,
    timezone: 'UTC',
    primaryShift: false,
    visible: true,
    colorHex: '#1d4ed8',
    remark: 'Automation validation seed non-primary shift.',
  })
  cleanupRegistry.add(
    `delete-shift-${supportShift.id}`,
    withCleanupGuard(() => workspaceApi.deleteShiftDefinition(supportShift.id)),
  )

  await workspaceApi.saveRoster({
    year: targetMonth.year,
    month: targetMonth.month,
    updates: [
      {
        staffId: staff.id,
        day: targetMonth.day,
        shiftCode: supportShift.code,
      },
    ],
  })

  return {
    runId,
    query: targetMonth,
    routeQuery: buildWorkspaceQuery(targetMonth),
    team,
    staff,
    primaryShift,
    supportShift,
    expectedIssue: {
      type: 'Missing Primary Coverage',
      ruleCode: 'roster.team-day.primary-coverage-missing',
      domain: 'roster',
      blocking: true,
      teamName: team.name,
      dateLabel: formatValidationDateLabel(targetMonth.year, targetMonth.month, targetMonth.day),
      description: `No primary shift is scheduled for team '${team.name}' on ${formatValidationDateLabel(targetMonth.year, targetMonth.month, targetMonth.day)}.`,
      targetPage: '/workspace/roster',
    },
  }
}

export async function seedValidationCleanupScenario({ cleanupRegistry, workspaceApi }) {
  if (!workspaceApi) {
    throw new Error('workspaceApi is required for validation cleanup seeding.')
  }

  const primaryUser = requirePrimaryUser()
  const runId = buildRunId()
  const targetMonth = pickFutureMonth(runId.replace(/\D/g, '').slice(-6))
  const teamName = `${VALIDATION_SCENARIO_PREFIX} CLEANUP ${runId}`
  const primaryShiftCode = `AT-C-${runId.slice(-6).toUpperCase()}`
  const invalidScopeId = buildSyntheticId(runId, 1)
  const invalidTeamId = buildSyntheticId(runId, 2)
  const orphanAssignmentId = buildSyntheticId(runId, 3)
  const orphanStaffId = buildSyntheticId(runId, 4)

  const account = await queryOne(
    `select id from workspace_account where deleted = 0 and staff_id = '${escapeSqlLiteral(primaryUser.staffId)}' limit 1`,
    ['id'],
  )

  if (!account?.id) {
    throw new Error(`Unable to find workspace account for AUTOTEST_STAFF_ID=${primaryUser.staffId}.`)
  }

  const team = await workspaceApi.createTeam({
    name: teamName,
    color: '#9f1239',
    displayOrder: 1001,
    visible: true,
    description: 'Automation corruption seed for validation cleanup regression.',
  })
  cleanupRegistry.add(`delete-team-${team.id}`, withCleanupGuard(() => workspaceApi.deleteTeam(team.id)))

  const primaryShift = await workspaceApi.createShiftDefinition({
    teamIds: [team.id],
    code: primaryShiftCode,
    meaning: 'Automation cleanup seed primary shift',
    startTime: '09:00:00',
    durationMinutes: 480,
    timezone: 'UTC',
    primaryShift: true,
    visible: true,
    colorHex: '#9f1239',
    remark: 'Automation validation cleanup seed shift.',
  })
  cleanupRegistry.add(
    `delete-shift-${primaryShift.id}`,
    withCleanupGuard(() => workspaceApi.deleteShiftDefinition(primaryShift.id)),
  )

  cleanupRegistry.add(
    `delete-orphan-assignment-${orphanAssignmentId}`,
    () => executeSql(`delete from workspace_roster_assignment where id = ${orphanAssignmentId};`),
  )
  cleanupRegistry.add(
    `delete-invalid-team-scope-${invalidScopeId}`,
    () => executeSql(`delete from workspace_account_team_scope where id = ${invalidScopeId};`),
  )

  await executeSql(`
    begin;
    set local session_replication_role = replica;
    insert into workspace_account_team_scope (id, account_id, team_id)
    values (${invalidScopeId}, ${account.id}, ${invalidTeamId})
    on conflict (account_id, team_id) do nothing;
    insert into workspace_roster_assignment (
      id,
      staff_id,
      role_group_id,
      team_id,
      shift_definition_id,
      assignment_date,
      shift_code,
      source_type,
      notes,
      deleted
    ) values (
      ${orphanAssignmentId},
      ${orphanStaffId},
      null,
      ${team.id},
      ${primaryShift.id},
      date '${targetMonth.year}-${String(targetMonth.month).padStart(2, '0')}-${String(targetMonth.day).padStart(2, '0')}',
      '${escapeSqlLiteral(primaryShift.code)}',
      'MANUAL',
      'Automation validation cleanup corruption seed.',
      0
    )
    on conflict do nothing;
    commit;
  `)

  return {
    runId,
    query: targetMonth,
    routeQuery: buildWorkspaceQuery(targetMonth),
    team,
    primaryShift,
    dirtyRecords: {
      invalidTeamScopeId: invalidScopeId,
      orphanAssignmentId,
    },
    expectedIssues: {
      orphanAssignment: {
        type: 'Orphan Assignment',
        ruleCode: 'roster.assignment.orphaned',
        domain: 'roster',
        blocking: true,
        teamName: team.name,
        dateLabel: formatValidationDateApiLabel(targetMonth.year, targetMonth.month, targetMonth.day),
        targetPage: '/workspace/roster',
        remediation: {
          actionKey: 'delete_orphan_assignment',
          recordCount: 1,
          recordId: orphanAssignmentId,
        },
      },
      invalidTeamScope: {
        type: 'Invalid Team Scope',
        ruleCode: 'config.account.team-scope-invalid',
        domain: 'configuration',
        blocking: false,
        teamName: '-',
        dateLabel: '-',
        targetPage: '/workspace/accounts',
        remediation: {
          actionKey: 'delete_invalid_team_scope',
          recordCount: 1,
          recordId: invalidScopeId,
        },
      },
    },
  }
}

export async function seedValidationImportIssueScenario({
  cleanupRegistry,
  workspaceApi,
  issueCount = 2,
}) {
  if (!workspaceApi) {
    throw new Error('workspaceApi is required for validation import issue seeding.')
  }

  const runId = buildRunId()
  const targetMonth = pickFutureMonth(runId.replace(/\D/g, '').slice(-6))
  const teamName = `${VALIDATION_SCENARIO_PREFIX} IMPORT ${runId}`
  const batchId = Number(buildSyntheticId(runId, 10))
  const issueIds = Array.from({ length: issueCount }, (_, index) => Number(buildSyntheticId(runId, 20 + index)))

  const team = await workspaceApi.createTeam({
    name: teamName,
    color: '#7c3aed',
    displayOrder: 1002,
    visible: true,
    description: 'Automation import issue seed for validation bulk resolution regression.',
  })
  cleanupRegistry.add(`delete-team-${team.id}`, withCleanupGuard(() => workspaceApi.deleteTeam(team.id)))
  cleanupRegistry.add(
    `delete-import-batch-${batchId}`,
    () => executeSql(`delete from workspace_import_batch where id = ${batchId};`),
  )
  cleanupRegistry.add(
    `delete-import-issues-${batchId}`,
    () => executeSql(`delete from workspace_import_issue where batch_id = ${batchId};`),
  )

  const issues = issueIds.map((issueId, index) => {
    const ordinal = index + 1
    return {
      id: issueId,
      type: `Automation Import Issue ${ordinal}`,
      description: `Automation import issue ${ordinal} for ${team.name}.`,
      teamName: team.name,
      dateLabel: formatValidationDateApiLabel(targetMonth.year, targetMonth.month, targetMonth.day),
      severity: ordinal % 2 === 0 ? 'medium' : 'low',
    }
  })

  await executeSql(`
    begin;
    insert into workspace_import_batch (
      id,
      roster_year,
      roster_month,
      file_name,
      status,
      total_records,
      valid_records,
      invalid_records,
      operator_name
    ) values (
      ${batchId},
      ${targetMonth.year},
      ${targetMonth.month},
      '${escapeSqlLiteral(`automation-import-${runId}.xlsx`)}',
      'COMPLETED',
      ${issueCount},
      0,
      ${issueCount},
      'automation'
    );
    ${issues.map((issue) => `
    insert into workspace_import_issue (
      id,
      batch_id,
      import_record_id,
      severity,
      issue_type,
      description,
      team_name,
      staff_name,
      issue_date,
      resolved
    ) values (
      ${issue.id},
      ${batchId},
      null,
      '${escapeSqlLiteral(issue.severity)}',
      '${escapeSqlLiteral(issue.type)}',
      '${escapeSqlLiteral(issue.description)}',
      '${escapeSqlLiteral(issue.teamName)}',
      '${escapeSqlLiteral(`Seed Staff ${issue.id}`)}',
      date '${targetMonth.year}-${String(targetMonth.month).padStart(2, '0')}-${String(targetMonth.day).padStart(2, '0')}',
      false
    );`).join('\n')}
    commit;
  `)

  return {
    runId,
    query: targetMonth,
    routeQuery: buildWorkspaceQuery(targetMonth),
    team,
    issues,
  }
}

export async function seedRosterSearchScenario({ cleanupRegistry, workspaceApi }) {
  if (!workspaceApi) {
    throw new Error('workspaceApi is required for roster regression seeding.')
  }

  const runId = buildRunId()
  const targetMonth = pickFutureMonth(runId.replace(/\D/g, '').slice(-6))
  const visibleTeam = await workspaceApi.createTeam({
    name: `${ROSTER_SCENARIO_PREFIX} VISIBLE ${runId}`,
    color: '#0f766e',
    displayOrder: 1003,
    visible: true,
    description: 'Automation visible team for roster regression.',
  })
  cleanupRegistry.add(`delete-team-${visibleTeam.id}`, withCleanupGuard(() => workspaceApi.deleteTeam(visibleTeam.id)))

  const hiddenTeam = await workspaceApi.createTeam({
    name: `${ROSTER_SCENARIO_PREFIX} NeedleTeam ${runId}`,
    color: '#be123c',
    displayOrder: 1004,
    visible: false,
    description: 'Automation hidden team for roster regression.',
  })
  cleanupRegistry.add(`delete-team-${hiddenTeam.id}`, withCleanupGuard(() => workspaceApi.deleteTeam(hiddenTeam.id)))

  const staffDefinitions = [
    {
      teamId: hiddenTeam.id,
      staffId: `ATRH${String(Date.now()).slice(-6)}1`,
      name: `Zed Hidden ${runId.slice(-4)}`,
      roleName: `NeedleRole ${runId.slice(-4)}`,
    },
    {
      teamId: hiddenTeam.id,
      staffId: `ATRH${String(Date.now()).slice(-6)}2`,
      name: `Aaron Hidden ${runId.slice(-4)}`,
      roleName: 'Roster Seed',
    },
    {
      teamId: hiddenTeam.id,
      staffId: `ATRH${String(Date.now()).slice(-6)}3`,
      name: `Joanna NeedleName ${runId.slice(-4)}`,
      roleName: 'Roster Seed',
    },
    {
      teamId: visibleTeam.id,
      staffId: `ATRV${String(Date.now()).slice(-6)}4`,
      name: `Bella Visible ${runId.slice(-4)}`,
      roleName: 'Visible Team Seed',
    },
  ]

  const createdStaff = []
  for (const definition of staffDefinitions) {
    const staff = await workspaceApi.createStaff({
      staffId: definition.staffId,
      name: definition.name,
      email: `${definition.staffId.toLowerCase()}@example.test`,
      region: 'Automation',
      timezone: 'UTC',
      roleName: definition.roleName,
      teamId: definition.teamId,
      status: 'Active',
      notes: 'Automation roster regression seed.',
    })
    createdStaff.push(staff)
    cleanupRegistry.add(`delete-staff-${staff.id}`, withCleanupGuard(() => workspaceApi.deleteStaff(staff.id)))
  }

  return {
    runId,
    query: targetMonth,
    routeQuery: buildWorkspaceQuery(targetMonth),
    visibleTeam,
    hiddenTeam,
    hiddenTeamStaffOrder: [
      `Aaron Hidden ${runId.slice(-4)}`,
      `Joanna NeedleName ${runId.slice(-4)}`,
      `Zed Hidden ${runId.slice(-4)}`,
    ],
    searchTerms: {
      byName: 'needlename',
      byRoleOnly: 'needlerole',
      byTeamOnly: 'needleteam',
      pageSearchName: 'bella',
    },
  }
}
