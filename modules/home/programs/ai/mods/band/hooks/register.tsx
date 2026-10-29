import { atom, read, update } from 'claude-code'
import type { Register, SessionRateLimit } from 'claude-code'

// When the main loop last got a reply: the prompt cache's clock starts there
const lastReplyAt = atom({ plugin: 'band', key: 'lastReplyAt' } as const, null)
const now = atom({ plugin: 'band', key: 'now' } as const, 0)

const CHILLY_MIN = 50 // the cache TTL is 1h; warn 10 minutes before it lapses
const COLD_MIN = 60
const HANDOFF_PCT = 60 // the handoff skill's cue to start a new session
const DOTS = 8
const USAGE_MIN_COLUMNS = 80 // narrower than this, the usage windows are left out

const dots = (pct: number) => {
  const filled = Math.min(DOTS, Math.round((pct / 100) * DOTS))

  return '●'.repeat(filled) + '○'.repeat(DOTS - filled)
}

const tokens = (n: number) =>
  n >= 1000 ? `${Math.round(n / 1000)}k` : String(n)

const windowLabel: Record<string, string> = { five_hour: '5h', seven_day: '7d' }

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const tick = async () => {
      const t = await $.clock.now()
      await update($, now, () => t)
    }
    await tick()
    $.clock.every(30_000, tick)

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    if (!e.agentId) {
      const t = await $.clock.now()
      await update($, lastReplyAt, () => t)
      await update($, now, () => t)
    }

    return next(e)
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)
    const usage = await $.session.usage()
    const pct = usage.context.percent ?? 0
    const inCache = usage.context.tokens ?? 0
    const repliedAt = await read($, lastReplyAt)
    const idleMin = repliedAt === null
      ? null
      : Math.max(0, Math.floor(((await read($, now)) - repliedAt) / 60_000))

    const ctxColor = pct >= 80 ? 'error' : pct >= HANDOFF_PCT ? 'warning' : 'success'

    const cache = (() => {
      if (idleMin === null || inCache === 0) {
        return null
      }
      if (idleMin >= COLD_MIN) {
        return { color: 'suggestion', text: `cache cold · ${tokens(inCache)} to re-send` }
      }
      const left = COLD_MIN - idleMin
      if (idleMin >= CHILLY_MIN) {
        return { color: 'warning', text: `cache chilly ${left}m left · ${tokens(inCache)}` }
      }

      return { color: 'success', text: `cache warm ${left}m left · ${tokens(inCache)}` }
    })()

    const windows = e.props.bodyColumns < USAGE_MIN_COLUMNS
      ? []
      : usage.rateLimits.filter((w: SessionRateLimit) => windowLabel[w.kind])

    return (
      <Box flexDirection="row">
        <Text color={ctxColor}>{dots(pct)}</Text>
        <Text> ctx {pct}%</Text>
        {pct >= HANDOFF_PCT ? <Text color="warning" bold> hand off</Text> : null}
        {cache ? <Text dimColor> │ </Text> : null}
        {cache ? <Text color={cache.color}>{cache.text}</Text> : null}
        {windows.map((w: SessionRateLimit) => {
          const left = Math.max(0, Math.round(100 - w.percentUsed))

          return (
            <Text key={w.kind} color={left < 15 ? 'error' : undefined}>
              <Text dimColor> │ </Text>
              {windowLabel[w.kind]} {left}% left
            </Text>
          )
        })}
      </Box>
    )
  })
}
