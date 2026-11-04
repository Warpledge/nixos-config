// What the band's Rebuild and Restart DMS buttons need; opencode-usage-bar/server.ts
// reads the same facts for its badge. The caller passes `run`: the engine doesn't let
// $ cross into another file.
import type { RepoState } from '../types'

/** Runs a command: its trimmed stdout, or undefined if it failed. */
export type Run = (argv: string[], timeoutMs?: number) => Promise<string | undefined>

const SYSTEM = '/nix/var/nix/profiles/system'

// /nix/store/<hash>-name/bin/... to /nix/store/<hash>-name
const storeRoot = (path: string): string => path.split('/').slice(0, 4).join('/')

/** The dms on PATH, when the running service came from another store path. */
const staleDms = async (run: Run): Promise<string | null> => {
  const pid = Number(await run(['systemctl', '--user', 'show', 'dms.service', '-p', 'MainPID', '--value'], 3000))
  if (!Number.isFinite(pid) || pid <= 0) return null
  const running = await run(['readlink', `/proc/${pid}/exe`])
  const which = await run(['which', 'dms'])
  const current = which && (await run(['readlink', '-f', which]))
  if (!running || !current) return null
  return storeRoot(running) === storeRoot(current) ? null : storeRoot(current)
}

export const snapshot = async (run: Run, flake: string): Promise<RepoState> => {
  const status = await run(['git', '-C', flake, 'status', '--porcelain'])
  const dirty = status ? status.split('\n').filter(Boolean).length : 0
  const committed = Number((await run(['git', '-C', flake, 'log', '-1', '--format=%ct'])) ?? 0)
  // No -L: the profile link's own time is when the build was activated.
  const built = Number((await run(['stat', '-c', '%Y', SYSTEM])) ?? 0)
  return { dirty, unbuilt: dirty > 0 || (built > 0 && committed > built), staleDms: await staleDms(run) }
}
