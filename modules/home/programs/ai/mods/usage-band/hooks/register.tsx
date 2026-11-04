import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { CacheFacts, Fold, Palette, RepoState, Window } from '../types'
import {
  BAR_BOX_H, ROBO_SIZE, TTL_MIN, TTL_MS, WORD,
  bandPx, barSvg, cardSvg, chipSvg, costOf, familyOf, fmtIdle, hueOf, kindOf, mineModel, roboSvg, usd,
} from './cache-art'
import type { CacheView } from './cache-art'
import { parsePalette } from './palette'
import { snapshot } from './repo-state'

// A band above the prompt, on Ribbon's layout (see LICENSE): how much of each usage
// window is used, the prompt cache's warm or cold state with Robo and the cost card,
// and buttons when the running build is behind the repo. Colours come from matugen.

// Nix fills these in from the repo's settings (claude.nix)
const flake: string = '__FLAKE_PATH__'
const promptFlag: string = '__REBUILD_PROMPT__'
const PROMPTS = promptFlag === '1'

const CELLS = 10
const HIGH_AT = 90
const TIGHT_CELLS = 6
/** The bar's width where it's drawn (px), and on a tight band. */
const BAR_W = 110
const TIGHT_BAR_W = 64
/** How often the band redraws, so the countdown and the warm-to-cold flip stay current. */
const TICK_MS = 30_000
const REPO_MS = 60_000
const RESTART_MS = 15_000

const windows = atom({ plugin: 'usage-band', key: 'windows' } as const, [] as Window[])
const cache = atom({ plugin: 'usage-band', key: 'cache' } as const, null as CacheFacts | null)
const fold = atom({ plugin: 'usage-band', key: 'fold' } as const, null as Fold | null)
const palette = atom({ plugin: 'usage-band', key: 'palette' } as const, null as Palette | null)
const repo = atom({ plugin: 'usage-band', key: 'repo' } as const, null as RepoState | null)

const NAMES: Record<string, string> = { five_hour: '5H', seven_day: '7D', spend_limit: 'SPEND', context: 'CTX' }
/** How long each timed window runs; the pace tick marks how much of it has passed. */
const WINDOW_MS: Record<string, number> = { five_hour: 5 * 3600_000, seven_day: 7 * 24 * 3600_000 }
/** A terminal needs this many columns to fit all three bars on one row. */
const TERMINAL_WIDE_AT = 84
const ORDER: Record<string, number> = { five_hour: 0, seven_day: 1 }

const clean = (list: readonly Window[]): Window[] =>
  list
    .map(w => ({ kind: w.kind, percentUsed: w.percentUsed, resetsAt: w.resetsAt }))
    .sort((a, b) => (ORDER[a.kind] ?? 9) - (ORDER[b.kind] ?? 9))

/** How far through its window this is, 0 to 100, or null for one with no timed window. */
const paceOf = (w: Window, now: number): number | null => {
  const span = WINDOW_MS[w.kind]
  const end = w.resetsAt ? Date.parse(w.resetsAt) : NaN
  if (!span || Number.isNaN(end)) return null
  return Math.max(0, Math.min(100, (1 - (end - now) / span) * 100))
}

const fmtReset = (iso: string | undefined, now: number): string => {
  if (!iso) return ''
  const ms = Date.parse(iso) - now
  if (Number.isNaN(ms)) return ''
  if (ms <= 0) return 'resetting'
  const mins = Math.round(ms / 60000)
  if (mins < 60) return `${mins}m`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `${hours}h ${mins % 60}m`
  return `${Math.floor(hours / 24)}d ${hours % 24}h`
}

/** What the cache drawings read, or null until a request and its context size are known. */
export const viewOf = (c: CacheFacts | null, now: number): CacheView | null => {
  if (!c || c.lastAt <= 0 || c.tokens <= 0) return null
  const idleMs = Math.max(0, now - c.lastAt)
  return {
    mode: idleMs >= TTL_MS ? 'cold' : 'warm',
    idle: fmtIdle(idleMs),
    idleMin: Math.floor(idleMs / 60000),
    tokens: c.tokens,
    window: c.window,
    mine: familyOf(c.model),
  }
}

const pull = async ($: EngineInterface): Promise<void> => {
  const u = await $.session.usage()
  await update($, windows, () => clean(u.rateLimits))
}

/** Null until matugen has rendered the file; the band then draws in theme keys, without art. */
const readPalette = async ($: EngineInterface): Promise<Palette | null> => {
  try {
    const dir = (await $.env.get('XDG_CONFIG_HOME')) || `${await $.env.get('HOME')}/.config`
    return parsePalette(String(await $.fs.read(`${dir}/claude-usage-band/matugen.json`)))
  } catch {
    return null
  }
}

const pullPalette = async ($: EngineInterface): Promise<void> => {
  const next = await readPalette($)
  const now = await read($, palette)
  if (JSON.stringify(next) !== JSON.stringify(now)) await update($, palette, () => next)
}

/** Reads the repo and DMS, and says once per build that DMS is behind. */
const pullRepo = async ($: EngineInterface): Promise<void> => {
  const state = await snapshot(async (argv, timeoutMs = 4000) => {
    try {
      const r = await $.process.run(argv, { timeoutMs })
      return r.exitCode === 0 ? r.stdout.trim() : undefined
    } catch {
      return undefined
    }
  }, flake)
  await update($, repo, () => state)
  if (state.staleDms && (await $.store.get('toldDms')) !== state.staleDms) {
    await $.store.set('toldDms', state.staleDms)
    $.ui.toast('DMS restart needed: the build changed it. Restart DMS is on the band.')
  }
}

const runButton = async ($: EngineInterface, argv: string[], timeoutMs: number): Promise<void> => {
  try {
    const r = await $.process.run(argv, { timeoutMs })
    if (r.exitCode !== 0) $.ui.toast(`${argv[0]} failed: ${r.stderr.trim() || `exit ${r.exitCode}`}`)
  } catch (error) {
    $.ui.toast(`${argv[0]} failed: ${error instanceof Error ? error.message : String(error)}`)
  }
}

/** Fresh context figures from the engine onto the cache facts, when it has them. */
const measure = async ($: EngineInterface, lastAt: number | null, model: string | null): Promise<void> => {
  const u = await $.session.usage()
  const m = model ?? (await $.session.model())
  await update($, cache, c => ({
    lastAt: lastAt ?? c?.lastAt ?? 0,
    tokens: u.context.tokens && u.context.tokens > 0 ? u.context.tokens : (c?.tokens ?? 0),
    window: u.context.window || c?.window || 0,
    model: m || c?.model || null,
  }))
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await pull($)
    await pullPalette($)
    $.clock.every(TICK_MS, () => {
      void pullPalette($).catch(() => undefined)
      $.ui.invalidate('ui.render')
    })
    if (PROMPTS) {
      // Off the start's path: slow shell calls must not hold the session up.
      void pullRepo($).catch(() => undefined)
      $.clock.every(REPO_MS, () => void pullRepo($).catch(() => undefined))
    }
    return next(e)
  })

  on('session.measure', async ($, e, next) => {
    if (e.changed.includes('rateLimits')) {
      await update($, windows, () => clean(e.rateLimits))
    }
    if (e.changed.includes('context') && e.context.tokens && e.context.tokens > 0) {
      const tokens = e.context.tokens
      await update($, cache, c => (c ? { ...c, tokens, window: e.context.window || c.window } : c))
    }
    return next(e)
  })

  // A resumed or forked session knows how long it was away and how big it is.
  on('classic.SessionStart', async ($, e, next) => {
    const r = await next(e)
    if (e.source === 'clear' || e.source === 'compact') {
      await update($, cache, () => null)
      await update($, fold, () => null)
    } else if ((e.source === 'resume' || e.source === 'fork') && typeof e.seconds_since_last_response === 'number') {
      const now = await $.clock.now()
      const lastAt = now - e.seconds_since_last_response * 1000
      const window = (await $.session.usage()).context.window
      const model = typeof e.model === 'string' ? e.model : await $.session.model()
      const tokens = typeof e.context_tokens === 'number' ? e.context_tokens : 0
      await update($, cache, () => ({ lastAt, tokens, window, model }))
    }
    return r
  }).catch(($, e, next) => next(e)) // a band that fails to seed never holds up the session

  // Each main-thread request reads or writes the cache, so its start resets the hour.
  on('turn.step', async function* ($, e, next) {
    if (!e.agentId) {
      const now = await $.clock.now()
      await update($, cache, c => ({ lastAt: now, tokens: c?.tokens ?? 0, window: c?.window ?? 0, model: c?.model ?? null }))
    }
    yield* next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const r = await next(e)
    if (e.agentId) return r
    const now = await $.clock.now()
    const c = await read($, cache)
    // turn.step stamps the exact request time; when no step of this turn did, the turn's end is the floor.
    const lastAt = !c || now - c.lastAt > e.durationMs ? now : c.lastAt
    await measure($, lastAt, e.usage?.model ?? null)
    if (PROMPTS) await pullRepo($)
    return r
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey) return next(e)

    const ui = $.ui.resolve(e)
    const { Box, Button, Text } = ui
    const p = await read($, palette)
    // Without a palette the art has no colours to draw in, so the band stays text.
    const Svg = p && e.surface !== 'terminal' && 'Svg' in ui ? ui.Svg : null
    const list = await read($, windows)
    const now = await $.clock.now()
    const view = viewOf(await read($, cache), now)
    const state = PROMPTS ? await read($, repo) : null

    // Theme keys until matugen has rendered the file
    const TEXT = p?.text ?? 'text'
    const MUTED = p?.muted ?? 'subtle'
    const EMPTY = p?.empty ?? 'inactive'
    const ERR = p?.err ?? 'error'
    const INK = p?.ink ?? 'inverseText'
    const OK = p?.ok ?? 'success'
    const barColor = (kind: string) =>
      kind === 'five_hour' ? (p?.five ?? 'suggestion') : kind === 'context' ? TEXT : (p?.seven ?? 'claude')
    const hue = (mode: 'warm' | 'cold') => (p ? hueOf(p, mode) : mode === 'warm' ? 'warning' : 'suggestion')
    const bg = p ? { backgroundColor: p.bg } : {}

    const prompts = state && (state.unbuilt || state.staleDms) ? (
      <Box key="prompts" flexDirection="row" alignItems="center">
        {state.unbuilt ? <Text key="why" color={OK}>{state.dirty > 0 ? `${state.dirty} uncommitted, not built ` : 'Commits not built '}</Text> : null}
        {state.unbuilt ? (
          <Box key="rebuild-gap" marginLeft={1}>
            <Button
              key="rebuild"
              label={e.surface === 'terminal' ? 'Rebuild' : '\u21BB'}
              onPress={() => runButton($, ['dms', 'ipc', 'call', 'omniSettings', 'rebuild'], 5000)}
            />
          </Box>
        ) : null}
        {state.unbuilt && state.staleDms ? <Text key="gap"> </Text> : null}
        {state.staleDms ? (
          <Button
            key="restart-dms"
            label="Restart DMS"
            onPress={async () => {
              await runButton($, ['systemctl', '--user', 'restart', 'dms.service'], RESTART_MS)
              await pullRepo($)
            }}
          />
        ) : null}
      </Box>
    ) : null

    if (list.length === 0 && !view) {
      return (
        <Box flexDirection="column" {...bg}>
          <Box key="wait" paddingX={1}>
            <Text color={MUTED}>USAGE · waiting for the first reply</Text>
          </Box>
          {prompts ? <Box key="status" flexDirection="row" paddingX={1} marginTop={1}>{prompts}</Box> : null}
        </Box>
      )
    }

    const columns = e.props.bodyColumns ?? e.viewport?.columns ?? 100
    const kind = kindOf(columns)
    const isWide = e.surface === 'terminal' ? columns >= TERMINAL_WIDE_AT : kind === 'wide'
    const cells = kind === 'tight' ? TIGHT_CELLS : CELLS

    const parts = (w: Window) => {
      const used = Math.max(0, Math.round(w.percentUsed * 10) / 10)
      return {
        used,
        pace: paceOf(w, now),
        col: used >= HIGH_AT ? ERR : barColor(w.kind),
        name: NAMES[w.kind] ?? w.kind.toUpperCase(),
        reset: fmtReset(w.resetsAt, now),
      }
    }

    // Drawn where the surface can; the terminal and a band with no palette get blocks,
    // with a │ at the pace.
    const meter = (b: ReturnType<typeof parts>) => {
      if (Svg && p) {
        const w = kind === 'tight' ? TIGHT_BAR_W : BAR_W
        const tick = b.pace === null ? undefined : { at: b.pace, fill: TEXT }
        const alt = `${b.used}% used${b.pace === null ? '' : `, ${Math.round(b.pace)}% of the window gone`}`
        return <Svg key={`bar-${b.name}`} source={barSvg(b.used, w, b.col, EMPTY, tick)} alt={alt} width={w} height={BAR_BOX_H} />
      }
      const n = Math.max(0, Math.min(cells, Math.round((b.used / 100) * cells)))
      const span = (from: number, to: number) => {
        const filled = Math.max(0, Math.min(to, n) - from)
        return [
          <Text key={`on-${from}`} color={b.col}>{'█'.repeat(filled)}</Text>,
          <Text key={`off-${from}`} color={EMPTY}>{'░'.repeat(to - from - filled)}</Text>,
        ]
      }
      if (b.pace === null) return span(0, cells)
      const at = Math.min(cells - 1, Math.floor((b.pace / 100) * cells))
      return [...span(0, at), <Text key="tick" color={TEXT}>│</Text>, ...span(at + 1, cells)]
    }

    // Wide: every window on one row. Narrow: each window is a block of three
    // lines (name and bar, percent used, reset time) so nothing wraps or clips.
    const wide = (w: Window, i: number) => {
      const b = parts(w)
      return (
        <Box key={`w-${i}`} flexDirection="row" flexShrink={0} marginRight={3} alignItems="center">
          <Text color={MUTED} bold>{b.name} </Text>
          {meter(b)}
          <Text color={b.col} bold> {b.used}%</Text>
          {b.reset ? <Text color={MUTED}> · {b.reset}</Text> : null}
        </Box>
      )
    }

    const stacked = (w: Window, i: number) => {
      const b = parts(w)
      return (
        <Box key={`w-${i}`} flexDirection="column" flexShrink={0} marginRight={3}>
          <Box flexDirection="row" alignItems="center">
            <Text color={MUTED} bold>{b.name} </Text>
            {meter(b)}
          </Box>
          <Text color={b.col} bold>{b.used}%</Text>
          {b.reset ? <Text color={MUTED}>resets {b.reset}</Text> : null}
        </Box>
      )
    }

    const label = (
      <Box key="label" flexShrink={0} marginRight={isWide ? 2 : 3}>
        <Text color={TEXT} bold>USAGE</Text>
      </Box>
    )
    // Context fills the same way a window does, and it's known once a reply has landed.
    const context: Window[] =
      view && view.window > 0 ? [{ kind: 'context', percentUsed: Math.round((view.tokens / view.window) * 100) }] : []
    const shown = [...list, ...context]
    const usage = shown.length > 0
      ? shown.map(isWide ? wide : stacked)
      : [<Box key="wait" flexShrink={0} marginRight={3}><Text color={MUTED}>waiting for the first reply</Text></Box>]

    // Before the first reply there is no cache to show.
    if (!view) {
      return (
        <Box flexDirection="column" {...bg}>
          <Box key="row" flexDirection="row" paddingX={1} flexWrap="wrap">
            {label}
            {usage}
          </Box>
          {prompts ? <Box key="status" flexDirection="row" paddingX={1} marginTop={1}>{prompts}</Box> : null}
        </Box>
      )
    }

    const mode = view.mode
    const cold = mode === 'cold'
    const tone = hue(mode)
    const mine = mineModel(view)
    const stored = await read($, fold)
    // Folding needs the card, and the card is a drawing: text bands stay folded.
    const open = Svg !== null && (stored && stored.mode === mode ? stored.open : cold)
    const toggle = () =>
      update($, fold, f => ({ mode, open: !(f && f.mode === mode ? f.open : mode === 'cold') }))

    const badge = Svg && p
      ? [
          <Svg key="robo" source={roboSvg(mode, p)} alt={cold ? 'Robo, frozen' : 'Robo, bobbing'} width={ROBO_SIZE} height={ROBO_SIZE} isInteractive />,
          <Text key="gap"> </Text>,
          (() => {
            const c = chipSvg(mode, p)
            return <Svg key="chip" source={c.source} alt={WORD[mode]} width={c.w} height={c.h} />
          })(),
        ]
      : [<Text key="chip" backgroundColor={tone} color={INK} bold>{` ${WORD[mode]} `}</Text>]

    const summary = cold
      ? [
          <Text key="idle" color={tone} bold>{` ${view.idle}`}</Text>,
          mine ? <Text key="dot" color={MUTED}> · </Text> : null,
          mine ? <Text key="cost" color={TEXT} bold>{usd(costOf(mine, mode, view.tokens))}</Text> : null,
        ]
      : [<Text key="left" color={tone} bold>{` ${Math.max(0, TTL_MIN - view.idleMin)}m left`}</Text>]

    const button = Svg ? (
      <Box key="fold" flexShrink={0} alignItems="flex-start">
        <Button key="cache-fold" label={open ? 'Hide' : 'Show'} onPress={toggle} />
      </Box>
    ) : null

    const rows = (
      <Box key="row" flexDirection="row" paddingX={1} alignItems={isWide ? 'center' : 'flex-start'}>
        <Box key="bars" flexDirection="row" flexGrow={1} flexWrap="wrap" alignItems={isWide ? 'center' : 'flex-start'}>
          {label}
          {usage}
        </Box>
        {button}
      </Box>
    )
    // The cache and the buttons share the row under the bars; the open card has the cache.
    const status = !open || prompts ? (
      <Box key="status" flexDirection="row" paddingX={1} marginTop={1} alignItems="center" flexWrap="wrap">
        {open ? null : (
          <Box key="cache" flexDirection="row" flexShrink={0} marginRight={3} alignItems="center">
            {badge}
            {summary}
          </Box>
        )}
        {prompts}
      </Box>
    ) : null

    let card = null
    if (open && Svg && p) {
      const c = cardSvg(view, kind, bandPx(columns), p)
      card = (
        <Box key="card" flexDirection="row">
          <Svg source={c.source} alt={c.alt} width={c.w} height={c.h} isInteractive={kind !== 'tight'} />
        </Box>
      )
    }

    return (
      <Box flexDirection="column" {...bg}>
        {rows}
        {status}
        {card}
      </Box>
    )
  })
}
