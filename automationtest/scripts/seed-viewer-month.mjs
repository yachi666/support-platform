import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

import { createWorkspaceApiClient } from '../helpers/workspace-api.mjs'
import { seedCurrentMonthViewerScenario } from '../helpers/seed-contracts.mjs'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const projectRoot = path.resolve(__dirname, '..')
const manifestDir = path.join(projectRoot, 'artifacts', 'manual-seeds')
const latestManifestPath = path.join(manifestDir, 'viewer-current-month-latest.json')

async function main() {
  const workspaceApi = await createWorkspaceApiClient()
  const scenario = await seedCurrentMonthViewerScenario({ workspaceApi })

  await mkdir(manifestDir, { recursive: true })

  const manifest = {
    seedType: 'viewer-current-month',
    createdAt: new Date().toISOString(),
    runId: scenario.runId,
    year: scenario.viewerDate.year,
    month: scenario.viewerDate.month,
    previewDate: `${scenario.viewerDate.year}-${String(scenario.viewerDate.month).padStart(2, '0')}-${String(scenario.viewerDate.day).padStart(2, '0')}`,
    previewTimezone: scenario.viewerDate.timezone,
    summary: scenario.summary,
    teams: scenario.teams.map((team) => ({
      id: team.id,
      name: team.name,
      color: team.color,
    })),
    cleanupManifest: scenario.cleanupManifest,
  }

  const runManifestPath = path.join(manifestDir, `viewer-current-month-${scenario.runId}.json`)
  const serializedManifest = `${JSON.stringify(manifest, null, 2)}\n`

  await Promise.all([
    writeFile(latestManifestPath, serializedManifest, 'utf8'),
    writeFile(runManifestPath, serializedManifest, 'utf8'),
  ])

  console.log(`[seed-viewer-month] Created ${scenario.summary.assignmentCount} assignments across ${scenario.summary.daysInMonth} day(s).`)
  console.log(`[seed-viewer-month] Teams: ${scenario.summary.teamCount}, staff: ${scenario.summary.staffCount}, shift definitions: ${scenario.summary.shiftDefinitionCount}`)
  console.log(`[seed-viewer-month] Open /viewer and select ${manifest.previewDate} in timezone ${manifest.previewTimezone}.`)
  console.log(`[seed-viewer-month] Latest manifest: ${latestManifestPath}`)
}

main().catch((error) => {
  console.error('[seed-viewer-month] failed:', error)
  process.exit(1)
})
