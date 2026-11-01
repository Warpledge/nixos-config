"use strict";
//=====================================================================#
// OPENCODE USAGE BAR - DESKTOP BAR
//=====================================================================#
// Runs in every OpenCode Desktop window. The shell renders the
// window.bottom slot as a full-width strip, where the TUI draws bars in
// prompt.footer.status. Built with DOM nodes so the file stays plain CJS;
// colours come from the app's theme variables.
const {Plugin, Slot} = require("@opencode/plugin/gui");

// Go plan caps: 5-hour 20% and week 50% of the $60 monthly allowance
const FIVE_CAP = 12;
const WEEK_CAP = 30;
const REFRESH_MS = 60_000;

const ACCENT = "var(--color-v2-icon-icon-accent)";
const WARNING = "var(--color-v2-state-fg-warning)";
const DANGER = "var(--color-v2-state-fg-danger)";
const MUTED = "var(--color-v2-text-text-muted)";
const TRACK = "var(--color-v2-background-bg-layer-02)";

// Matches rpc.ts. The client only reads its id and method names.
const Usage = {
  id: "usage-bar",
  methods: {
    read: {
      input: {type: "object", properties: {}, additionalProperties: false},
      output: {type: "object", properties: {}, additionalProperties: true},
    },
  },
  events: {},
};

// DeepSeek's peak hours: 01:00-04:00 and 06:00-10:00 UTC, Monday to Friday
function peakHours(now) {
  const day = now.getUTCDay();
  const hour = now.getUTCHours() + now.getUTCMinutes() / 60;
  return day >= 1 && day <= 5 && ((hour >= 1 && hour < 4) || (hour >= 6 && hour < 10));
}

function tone(ratio) {
  return ratio >= 0.9 ? DANGER : ratio >= 0.7 ? WARNING : ACCENT;
}

function segment(label, cap) {
  const root = document.createElement("div");
  root.style.cssText = "display:flex;align-items:center;gap:6px;";

  const name = document.createElement("span");
  name.textContent = label;
  name.style.cssText = `font-weight:600;letter-spacing:.04em;color:${MUTED}`;

  const track = document.createElement("span");
  track.style.cssText = `display:inline-block;width:96px;height:6px;border-radius:3px;overflow:hidden;background:${TRACK}`;

  const fill = document.createElement("span");
  fill.style.cssText = "display:block;height:100%;width:0%;border-radius:3px;transition:width .3s ease";
  track.appendChild(fill);

  const percent = document.createElement("span");
  percent.style.cssText = "min-width:4ch;text-align:right;font-variant-numeric:tabular-nums";

  root.append(name, track, percent);

  const update = (spend) => {
    const ratio = Math.max(0, Math.min(1, spend / cap));
    fill.style.width = `${Math.round(ratio * 100)}%`;
    fill.style.background = tone(ratio);
    percent.textContent = `${Math.round(ratio * 100)}%`;
    percent.style.color = ratio >= 0.7 ? tone(ratio) : MUTED;
    root.title = `$${spend.toFixed(2)} of $${cap}`;
  };

  return {root, update};
}

const paints = new Set();
let state = {five: -1, week: -1, at: 0, error: ""};

function paint() {
  for (const item of [...paints]) {
    if (!item.root.isConnected) {
      paints.delete(item);
      continue;
    }
    item.update(state);
  }
}

function bar() {
  const root = document.createElement("div");
  root.style.cssText = [
    "display:flex",
    "align-items:center",
    "gap:14px",
    "width:100%",
    "padding:3px 12px",
    "font:11px/1.4 system-ui,-apple-system,sans-serif",
    `color:${MUTED}`,
    "border-top:1px solid var(--color-v2-border-border-muted)",
    "background:var(--color-v2-background-bg-base)",
  ].join(";");

  const five = segment("5H", FIVE_CAP);
  const week = segment("WK", WEEK_CAP);
  const note = document.createElement("span");
  note.style.cssText = "margin-left:auto";
  root.append(five.root, week.root, note);

  const update = (value) => {
    if (value.error) {
      five.root.style.display = "none";
      week.root.style.display = "none";
      note.textContent = "usage ?";
      note.style.color = WARNING;
      note.title = value.error;
      return;
    }
    five.root.style.display = "";
    week.root.style.display = "";
    if (value.at === 0) {
      note.textContent = "usage …";
      note.style.color = MUTED;
      note.title = "";
      return;
    }
    five.update(value.five);
    week.update(value.week);
    const peak = peakHours(new Date());
    note.textContent = peak ? "PEAK" : "OFF-PEAK";
    note.style.color = peak ? WARNING : MUTED;
    note.title = peak ? "DeepSeek peak rates apply" : "DeepSeek off-peak rates apply";
  };

  const item = {root, update};
  paints.add(item);
  update(state);
  return root;
}

module.exports = Plugin.define({
  setup(ctx) {
    let stopped = false;

    const refresh = async () => {
      try {
        const value = await ctx.client.rpc(Usage).read({});
        if (stopped) return;
        state = {five: value.fiveHourCost, week: value.weekCost, at: value.fetchedAt, error: ""};
      } catch (error) {
        if (stopped) return;
        state = {five: -1, week: -1, at: 0, error: String(error)};
      }
      paint();
    };

    void refresh();
    const timer = setInterval(() => void refresh(), REFRESH_MS);
    ctx.add(Slot, {at: "window.bottom", order: 10, render: () => bar()});

    return () => {
      stopped = true;
      clearInterval(timer);
    };
  },
});
