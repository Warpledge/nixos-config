declare module 'claude-code' {
  interface PluginState {
    band: { lastReplyAt: number | null; now: number }
  }
}
