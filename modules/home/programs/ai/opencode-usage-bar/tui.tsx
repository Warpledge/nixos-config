//=====================================================================#
// OPENCODE USAGE BAR - STATUS SLOT
//=====================================================================#
import {Plugin} from "@opencode/plugin/tui";
import {UsageRpc} from "./rpc";

// Nix fills these in from the switches under Omni Settings' AI, OpenCode
const TUI = "__TUI__" === "1";

// Percentages come from the server, against each model's own Go limit
const WIDTH = 8;
const REFRESH_MS = 60_000;

// DeepSeek's peak hours: 01:00-04:00 and 06:00-10:00 UTC, Monday to Friday
function peakHours(now: Date) {
  const day = now.getUTCDay();
  const hour = now.getUTCHours() + now.getUTCMinutes() / 60;
  return day >= 1 && day <= 5 && ((hour >= 1 && hour < 4) || (hour >= 6 && hour < 10));
}

function isPeakModel(model?: {providerID: string; modelID: string}) {
  return (
    model?.providerID === "opencode-go" &&
    (model.modelID === "deepseek-v4.1-flash" || model.modelID === "deepseek-v4-pro")
  );
}

function bar(ratio: number) {
  const filled = Math.max(0, Math.min(WIDTH, Math.round(ratio * WIDTH)));
  return {filled: "█".repeat(filled), empty: "░".repeat(WIDTH - filled)};
}

export default Plugin.define({
  id: "usage-bar-tui",
  async setup(context) {
    //--- Off under AI, OpenCode: no slot, so the footer stays as it was
    if (!TUI) return () => {};

    const [state, setState] = context.storage.memory("usage-bar", {
      initial: {five: -1, week: -1, at: 0, error: ""},
    });

    let stopped = false;
    const refresh = async () => {
      try {
        const reading = await context.client.rpc(UsageRpc).read({});
        if (stopped) return;
        setState((draft) => {
          draft.five = reading.fivePercent;
          draft.week = reading.weekPercent;
          draft.at = reading.fetchedAt;
          draft.error = "";
        });
      } catch (error) {
        if (stopped) return;
        setState((draft) => {
          draft.error = String(error);
        });
      }
    };

    await refresh();
    const timer = setInterval(() => void refresh(), REFRESH_MS);
    const unsubscribe = context.data.on("session.execution.succeeded", () => {
      setTimeout(() => void refresh(), 2000);
    });

    const tone = (ratio: number) =>
      ratio >= 0.9 ? context.theme.text.error : ratio >= 0.7 ? context.theme.text.base : context.theme.text.muted;

    const segment = (label: string, percent: number) => {
      const ratio = Math.max(0, Math.min(1, percent / 100));
      const {filled, empty} = bar(ratio);
      return (
        <box flexDirection="row" gap={1}>
          <text fg={context.theme.text.muted}>{label}</text>
          <text fg={tone(ratio)}>{filled}</text>
          <text fg={context.theme.text.muted}>{empty}</text>
          <text fg={tone(ratio)}>{`${Math.round(percent)}%`}</text>
        </box>
      );
    };

    const render = () => {
      const reading = state();
      if (reading.error) return <text fg={context.theme.text.muted}>usage ?</text>;
      if (reading.at === 0) return <text fg={context.theme.text.muted}>usage …</text>;
      const model = context.ui.model.current();
      const peak = peakHours(new Date());
      return (
        <box flexDirection="row" gap={2}>
          {segment("5H", reading.five)}
          {segment("WK", reading.week)}
          {isPeakModel(model) ? (
            <text fg={peak ? context.theme.text.error : context.theme.text.muted}>{peak ? "PEAK" : "OFF-PEAK"}</text>
          ) : null}
        </box>
      );
    };

    const promptSlot = context.ui.slot({append: "prompt.footer.status", render});
    const homeSlot = context.ui.slot({append: "home.footer.status", render});

    return () => {
      stopped = true;
      clearInterval(timer);
      unsubscribe();
      promptSlot();
      homeSlot();
    };
  },
});
