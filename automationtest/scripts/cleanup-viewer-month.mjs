import { readFile, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

import { createWorkspaceApiClient } from '../helpers/workspace-api.mjs'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const projectRoot = path.resolve(__dirname, '..')
const latestManifestPath = path.join(projectRoot, 'artifacts', 'manual-seeds', 'viewer-current-month-latest.json')

function resolveManifestPath() {
  const explicitPath = process.argv[2]
  return explicitPath ? path.resolve(process.cwd(), explicitPath) : latestManifestPath
}

function isNotFoundError(error) {
  return /failed \(404\)/i.test(error.message)
}

async function deleteIgnoringMissing(label, action) {
  try {
    await action()
  } catch (error) {
    if (isNotFoundError(error)) {
      console.log(`[cleanup-viewer-month] Skipped missing ${label}.`)
      return
    }
    throw error
  }
}

async function main() {
  const manifestPath = resolveManifestPath()
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'))

  if (manifest.cleanedAt) {
    console.log(`[cleanup-viewer-month] Manifest already cleaned at ${manifest.cleanedAt}.`)
    return
  }

  const workspaceApi = await createWorkspaceApiClient()
  const { cleanupManifest } = manifest

  for (const shiftDefinitionId of cleanupManifest.shiftDefinitionIds ?? []) {
    await deleteIgnoringMissing(`shift ${shiftDefinitionId}`, () => workspaceApi.deleteShiftDefinition(shiftDefinitionId))
  }

  for (const staffId of cleanupManifest.staffIds ?? []) {
    await deleteIgnoringMissing(`staff ${staffId}`, () => workspaceApi.deleteStaff(staffId))
  }

  for (const teamId of cleanupManifest.teamIds ?? []) {
    await deleteIgnoringMissing(`team ${teamId}`, () => workspaceApi.deleteTeam(teamId))
  }

  manifest.cleanedAt = new Date().toISOString()
  await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`, 'utf8')

  console.log(`[cleanup-viewer-month] Removed seed data recorded in ${manifestPath}.`)
}

main().catch((error) => {
  console.error('[cleanup-viewer-month] failed:', error)
  process.exit(1)
})
