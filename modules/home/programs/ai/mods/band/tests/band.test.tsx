import { expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'
import type { Engine } from 'claude-code/testing'

const BAND = {
  plugin: 'band',
  component: 'AbovePrompt',
  surface: 'terminal',
  props: {
    hasSurvey: false,
    isWorking: false,
    maxRows: 10,
    bodyColumns: 120,
    scroll: { offset: 0, bodyRows: 10 },
    view: {},
  },
} as const

const MIN = 60_000

// Stands in for the engine: the session's usage and the two stored values
const seed = (on: On, idleMin: number, percent: number) => {
  on('session.usage', () => ({
    value: {
      startedAt: 0,
      context: { tokens: 245_000, window: 1_000_000, percent },
      rateLimits: [
        { kind: 'five_hour', percentUsed: 28 },
        { kind: 'seven_day', percentUsed: 90 },
      ],
    },
  }))
  on('state.get', (_, e) => ({
    value: { value: e.key === 'lastReplyAt' ? 0 : idleMin * MIN, version: 1 },
  }))
}

const text = async ($: Engine) => {
  const ui = await $.ui.mount(BAND)
  const all = (await ui.findAll({ type: 'Text' })).map(t => t.text).join('')
  await ui.unmount()

  return all
}

test('warm under 50 minutes, with usage left', async ($, on) => {
  seed(on, 10, 30)
  const all = await text($)
  expect(all).toContain('cache warm 50m left · 245k')
  expect(all).toContain('5h 72% left')
  expect(all).toContain('7d 10% left')
  expect(all).not.toContain('hand off')
})

test('chilly from 50 minutes',async ($, on) => {
  seed(on, 52, 30)
  expect(await text($)).toContain('cache chilly 8m left')
})

test('cold past the hour', async ($, on) => {
  seed(on, 75, 30)
  expect(await text($)).toContain('cache cold · 245k to re-send')
})

test('hand off from 60% context', async ($, on) => {
  seed(on, 5, 63)
  expect(await text($)).toContain('ctx 63% hand off')
})
