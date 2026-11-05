import type { SessionRateLimit } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'

const NOW = Date.parse('2098-12-31T22:00:00Z')
const WINDOWS = [
  { kind: 'seven_day', percentUsed: 12.5 },
  { kind: 'five_hour', percentUsed: 58, resetsAt: '2099-01-01T00:00:00Z' },
]
const PROPS = {
  hasSurvey: false,
  isWorking: false,
  maxRows: 6,
  bodyColumns: 100,
  scroll: { offset: 0, bodyRows: 6 },
  view: {},
} as const
// Hex values stand for what matugen renders; none of them ships in the mod.
const PALETTE = JSON.stringify({
  bg: '#101010', text: '#f0f0f0', muted: '#808080', empty: '#404040', line: '#303030', five: '#a0a0ff',
  seven: '#a0ffa0', warm: '#ffa0a0', cold: '#a0ffff', ink: '#000001', err: '#ff0001', ok: '#00ff01',
})

type Facts = { windows?: SessionRateLimit[]; palette?: string; status?: string; committed?: string; built?: string; exe?: string; path?: string }

// Answers the mod's file and process reads from `facts`, and records each argv run.
const world = (on: Parameters<typeof mock.store>[0], facts: Facts, runs: string[][] = []) => {
  mock.store(on)
  mock.clock(on, { now: NOW })
  mock.env(on, { HOME: '/home/t' })
  on('session.start', ($, e) => ({ cwd: e.cwd }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { window: 1000000 }, rateLimits: facts.windows ?? WINDOWS } }))
  on('classic.SessionStart', () => ({}))
  on('turn.complete', () => ({ text: '' }))
  on('fs.read', ($, e) => {
    if (facts.palette === undefined) throw new Error('no such file')
    expect(e.path).toBe('/home/t/.config/claude-usage-band/matugen.json')
    return { value: facts.palette }
  })
  on('process.run', ($, e) => {
    const argv = [...e.argv]
    runs.push(argv)
    const ok = (stdout: string) => ({ value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } })
    if (argv.includes('status')) return ok(facts.status ?? '')
    if (argv.includes('log')) return ok(facts.committed ?? '100')
    if (argv[0] === 'stat') return ok(facts.built ?? '200')
    if (argv[0] === 'systemctl' && argv.includes('show')) return ok('42')
    if (argv[0] === 'readlink' && argv[1] === '/proc/42/exe') return ok(facts.exe ?? '/nix/store/a-dms/bin/.dms-wrapped')
    if (argv[0] === 'which') return ok('/run/bin/dms')
    if (argv[0] === 'readlink') return ok(facts.path ?? '/nix/store/a-dms/bin/dms')
    return ok('')
  })
}

const SURFACES = ['terminal', 'desktop'] as const

test('5H comes first and both windows show percent used', async ($, on) => {
  world(on, { palette: PALETTE })
  await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' })
  for (const surface of SURFACES) {
    const band = await $.ui.mount({ plugin: 'usage-band', surface, component: 'AbovePrompt', props: PROPS })
    expect(await band.find({ text: ' 58%' })).toBeDefined()
    expect(await band.find({ text: ' 12.5%' })).toBeDefined()
    const all = JSON.stringify(await band.find({ type: 'Box' }))
    expect(all.indexOf('5H')).toBeLessThan(all.indexOf('7D'))
    expect(all).not.toContain('left')
    await band.unmount()
  }
})

test('the desktop draws the art in matugen colours; the terminal draws a chip', async ($, on) => {
  world(on, { palette: PALETTE })
  await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' })
  await $.classic.SessionStart({ source: 'resume', seconds_since_last_response: 18 * 60, context_tokens: 770000, model: 'claude-opus-5-5' })

  const desk = await $.ui.mount({ plugin: 'usage-band', surface: 'desktop', component: 'AbovePrompt', props: PROPS })
  const art = JSON.stringify(await desk.findAll({ type: 'Svg' }))
  expect(art).toContain('#ffa0a0')
  expect(art).not.toContain('#cc6363')
  expect(await desk.find({ text: ' 42m left' })).toBeDefined()
  await desk.unmount()

  const term = await $.ui.mount({ plugin: 'usage-band', surface: 'terminal', component: 'AbovePrompt', props: PROPS })
  expect(await term.find({ text: ' WARM ' })).toBeDefined()
  expect(await term.findAll({ type: 'Svg' })).toEqual([])
  await term.unmount()
})

test('with no palette file the band stays text on every surface', async ($, on) => {
  world(on, {})
  await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' })
  await $.classic.SessionStart({ source: 'resume', seconds_since_last_response: 2 * 3600, context_tokens: 770000, model: 'claude-opus-5-5' })
  for (const surface of SURFACES) {
    const band = await $.ui.mount({ plugin: 'usage-band', surface, component: 'AbovePrompt', props: PROPS })
    expect(await band.find({ text: ' COLD ' })).toBeDefined()
    expect(await band.find({ text: '$6.16' })).toBeDefined()
    expect(await band.findAll({ type: 'Svg' })).toEqual([])
    await band.unmount()
  }
})

test('the desktop draws a bar in matugen colours; the terminal draws blocks', async ($, on) => {
  world(on, { palette: PALETTE })
  await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' })

  const desk = await $.ui.mount({ plugin: 'usage-band', surface: 'desktop', component: 'AbovePrompt', props: PROPS })
  const bars = await desk.findAll({ type: 'Svg' })
  expect(bars).toHaveLength(2)
  expect(JSON.stringify(bars)).toContain('#a0a0ff')
  await desk.unmount()

  const term = await $.ui.mount({ plugin: 'usage-band', surface: 'terminal', component: 'AbovePrompt', props: PROPS })
  expect(await term.find({ text: '██████' })).toBeDefined()
  expect(await term.findAll({ type: 'Svg' })).toEqual([])
  await term.unmount()
})

test('each timed window marks its pace, and context joins the bars after a reply', async ($, on) => {
  world(on, { palette: PALETTE })
  await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' })
  await $.classic.SessionStart({ source: 'resume', seconds_since_last_response: 60, context_tokens: 250000, model: 'claude-opus-5-5' })

  const desk = await $.ui.mount({ plugin: 'usage-band', surface: 'desktop', component: 'AbovePrompt', props: PROPS })
  // 2h left of 5h: the 5H tick sits 60% along the 110 px bar. 7D has no reset, so no tick.
  const bars = JSON.stringify(await desk.findAll({ type: 'Svg' }))
  expect(bars).toContain('x=\\"65\\"')
  expect(bars.split('class=\\"pace\\"').length - 1).toBe(1)
  expect(await desk.find({ text: ' 25%' })).toBeDefined()
  expect(await desk.find({ key: 'status' })).toBeDefined()
  await desk.unmount()

  const term = await $.ui.mount({ plugin: 'usage-band', surface: 'terminal', component: 'AbovePrompt', props: PROPS })
  expect(await term.find({ text: '│' })).toBeDefined()
  expect(await term.find({ text: ' WARM ' })).toBeDefined()
  await term.unmount()
})

test('a window at 90% or more turns the error colour', async ($, on) => {
  world(on, { palette: PALETTE, windows: [{ kind: 'five_hour', percentUsed: 95 }] })
  await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' })
  const band = await $.ui.mount({ plugin: 'usage-band', surface: 'desktop', component: 'AbovePrompt', props: PROPS })
  expect(JSON.stringify(await band.find({ type: 'Box' }))).toContain('#ff0001')
  await band.unmount()
})

test('a clean, built repo with current DMS shows no buttons', async ($, on) => {
  world(on, { palette: PALETTE })
  await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' })
  const band = await $.ui.mount({ plugin: 'usage-band', surface: 'desktop', component: 'AbovePrompt', props: PROPS })
  expect(await band.find({ key: 'rebuild' })).toBeUndefined()
  expect(await band.find({ key: 'restart-dms' })).toBeUndefined()
  await band.unmount()
})

test('Rebuild opens the Omni Settings dialog and never runs a rebuild itself', async ($, on) => {
  const runs: string[][] = []
  world(on, { palette: PALETTE, status: ' M a.nix\n M b.nix\n' }, runs)
  await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' })
  for (const surface of SURFACES) {
    const band = await $.ui.mount({ plugin: 'usage-band', surface, component: 'AbovePrompt', props: PROPS })
    expect(await band.find({ text: '2 uncommitted, not built ' })).toBeDefined()
    expect(await band.find({ key: 'rebuild' })).toBeDefined()
    expect(JSON.stringify(await band.find({ type: 'Box' }))).toContain('#00ff01')
    await band.press({ key: 'rebuild' })
    await band.unmount()
  }
  expect(runs).toContainEqual(['dms', 'ipc', 'call', 'omniSettings', 'rebuild'])
  expect(runs.flat()).not.toContain('nixos-rebuild')
})

test('a newer commit than the build also offers Rebuild', async ($, on) => {
  world(on, { palette: PALETTE, committed: '300', built: '200' })
  await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' })
  const band = await $.ui.mount({ plugin: 'usage-band', surface: 'terminal', component: 'AbovePrompt', props: PROPS })
  expect(await band.find({ text: 'Commits not built ' })).toBeDefined()
  await band.unmount()
})

test('a stale DMS offers a restart and toasts once per build', async ($, on) => {
  const runs: string[][] = []
  const toasts: string[] = []
  world(on, { palette: PALETTE, exe: '/nix/store/old-dms/bin/.dms-wrapped', path: '/nix/store/new-dms/bin/dms' }, runs)
  on('ui.toast', ($, e) => {
    toasts.push(e.text)
    return { value: undefined }
  })
  await $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' })
  await $.turn.complete({ answer: '', reason: 'answer', durationMs: 10, isAborted: false, turnId: 't' })
  await $.turn.complete({ answer: '', reason: 'answer', durationMs: 10, isAborted: false, turnId: 't' })
  expect(toasts.filter(t => t.startsWith('DMS restart needed'))).toHaveLength(1)

  const band = await $.ui.mount({ plugin: 'usage-band', surface: 'desktop', component: 'AbovePrompt', props: PROPS })
  await band.press({ key: 'restart-dms' })
  expect(runs).toContainEqual(['systemctl', '--user', 'restart', 'dms.service'])
  await band.unmount()
})
