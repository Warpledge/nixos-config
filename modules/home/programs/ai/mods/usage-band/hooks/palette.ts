// The band's colours, from the file matugen renders (theme/matugen/claude-usage-band.json).
import type { Palette } from '../types'

const KEYS = ['bg', 'text', 'muted', 'empty', 'line', 'five', 'seven', 'warm', 'cold', 'ink', 'err', 'ok'] as const
const HEX = /^#[0-9a-fA-F]{6}$/

export const parsePalette = (raw: string): Palette | null => {
  try {
    const data: unknown = JSON.parse(raw)
    if (typeof data !== 'object' || data === null) return null
    const found = data as Record<string, unknown>
    return KEYS.every(k => typeof found[k] === 'string' && HEX.test(found[k] as string)) ? (found as Palette) : null
  } catch {
    return null
  }
}
