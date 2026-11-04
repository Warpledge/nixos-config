"use strict";
//=====================================================================#
// OPENCODE USAGE BAR - DESKTOP PARTS
//=====================================================================#
// Runs in every OpenCode Desktop window. The shell renders the
// window.bottom slot as a full-width strip, where the TUI draws bars in
// prompt.footer.status. Built with DOM nodes so the file stays plain CJS;
// colours come from the app's theme variables.
const {Plugin, SettingsPage, Slot, TitlebarItem} = require("@opencode/plugin/gui");
const {createSignal} = require("solid-js");
// Nix fills these in from the switches under Omni Settings' AI, OpenCode
const FEATURES = {desktopBar: "__DESKTOP_BAR__" === "1", rebuildBadge: "__REBUILD_BADGE__" === "1"};

const REFRESH_MS = 60_000;
const INTERVALS = [30_000, 60_000, 300_000];

const ACCENT = "var(--color-v2-icon-icon-accent)";
const WARNING = "var(--color-v2-state-fg-warning)";
const DANGER = "var(--color-v2-state-fg-danger)";
const MUTED = "var(--color-v2-text-text-muted)";
const TRACK = "var(--color-v2-background-bg-layer-02)";
const BORDER = "var(--color-v2-border-border-muted)";
const TEXT = "var(--color-v2-text-text-base)";

// Matches rpc.ts. The client only reads ids, method names and events.
const Usage = {
  id: "usage-bar",
  methods: {
    read: {
      input: {type: "object", properties: {}, additionalProperties: false},
      output: {type: "object", properties: {}, additionalProperties: true},
    },
    state: {
      input: {type: "object", properties: {}, additionalProperties: false},
      output: {type: "object", properties: {}, additionalProperties: true},
    },
    setPlan: {
      input: {
        type: "object",
        properties: {plan: {type: "string"}},
        required: ["plan"],
        additionalProperties: false,
      },
      output: {type: "object", properties: {}, additionalProperties: true},
    },
    restartDms: {
      input: {type: "object", properties: {}, additionalProperties: false},
      output: {type: "object", properties: {}, additionalProperties: true},
    },
    askRebuild: {
      input: {type: "object", properties: {}, additionalProperties: false},
      output: {type: "object", properties: {}, additionalProperties: true},
    },
  },
  events: {
    turn: {schema: {type: "object", properties: {}, additionalProperties: true}},
  },
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

function ageLabel(ms) {
  if (!ms || ms < 0) return "now";
  const hours = Math.floor(ms / 3_600_000);
  if (hours < 1) return `${Math.max(1, Math.floor(ms / 60_000))}m`;
  if (hours < 48) return `${hours}h`;
  return `${Math.floor(hours / 24)}d`;
}

function segment(label) {
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

  const update = (value, cost) => {
    const ratio = Math.max(0, Math.min(1, value / 100));
    fill.style.width = `${Math.round(ratio * 100)}%`;
    fill.style.background = tone(ratio);
    percent.textContent = `${Math.round(value)}%`;
    percent.style.color = ratio >= 0.7 ? tone(ratio) : MUTED;
    root.title = `${value.toFixed(1)}% of the ${label} limit · $${cost.toFixed(2)}`;
  };

  return {root, update};
}

const paints = new Set();
const syncers = new Set();
const badges = new Set();
let usageState = {five: -1, week: -1, fiveCost: 0, weekCost: 0, deepseek: false, at: 0, error: ""};

function paintSettings() {
  for (const item of [...syncers]) {
    if (!item.root.isConnected) {
      syncers.delete(item);
      continue;
    }
    item.sync();
  }
}

function paint() {
  for (const item of [...paints]) {
    if (!item.root.isConnected) {
      paints.delete(item);
      continue;
    }
    item.update(usageState);
  }
}

// Material's sync glyph, the one Omni Settings uses on its rebuild rows
const REBUILD_ICON =
  '<svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor" aria-hidden="true"><path d="M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6 0 1.01-.25 1.97-.7 2.8l1.46 1.46C19.54 15.03 20 13.57 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6 0-1.01.25-1.97.7-2.8L5.24 7.74C4.46 8.97 4 10.43 4 12c0 4.42 3.58 8 8 8v3l4-4-4-4v3z"/></svg>';

let repoState = {dirty: 0, unbuilt: false, generation: 0, age: 0, dmsStale: false, plan: "go"};

function paintBadges() {
  for (const item of [...badges]) {
    if (!item.root.isConnected) {
      badges.delete(item);
      continue;
    }
    item.update(repoState);
  }
}

function badge(onClick) {
  const root = document.createElement("button");
  root.type = "button";
  root.style.cssText = [
    "display:none",
    "align-items:center",
    "gap:8px",
    "padding:4px 12px",
    "border-radius:999px",
    "font:600 13px/1.2 system-ui,-apple-system,sans-serif",
    "color:var(--color-v2-state-fg-success)",
    "background:color-mix(in srgb, var(--color-v2-state-fg-success) 15%, transparent)",
    "border:1px solid color-mix(in srgb, var(--color-v2-state-fg-success) 35%, transparent)",
    "cursor:pointer",
  ].join(";");

  const icon = document.createElement("span");
  icon.style.cssText = "display:inline-flex;align-items:center";
  icon.innerHTML = REBUILD_ICON;

  const label = document.createElement("span");
  root.append(icon, label);
  root.onclick = onClick;

  const update = (value) => {
    if (!value.unbuilt) {
      root.style.display = "none";
      return;
    }
    root.style.display = "inline-flex";
    label.textContent =
      value.dirty > 0 ? `Rebuild ready · ${value.dirty} file${value.dirty === 1 ? "" : "s"}` : "Rebuild ready · new commits";
    root.title = `Choose how to rebuild in Omni Settings; the running build is ${ageLabel(value.age)} old`;
  };

  badges.add({root, update});
  update(repoState);
  return root;
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
    `border-top:1px solid ${BORDER}`,
    "background:var(--color-v2-background-bg-base)",
  ].join(";");

  const five = segment("5H");
  const week = segment("WK");
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
    five.update(value.five, value.fiveCost);
    week.update(value.week, value.weekCost);
    // The rates only matter with DeepSeek in the last 5 hours; the TUI goes by the picked model
    const peak = peakHours(new Date());
    note.textContent = !value.deepseek ? "" : peak ? "PEAK" : "OFF-PEAK";
    note.style.color = peak ? WARNING : MUTED;
    note.title = peak ? "DeepSeek peak rates apply" : "DeepSeek off-peak rates apply";
  };

  const item = {root, update};
  paints.add(item);
  update(usageState);
  return root;
}

module.exports = Plugin.define({
  setup(ctx) {
    const usage = ctx.client.rpc(Usage);
    const [repo, setRepo] = createSignal({dirty: 0, unbuilt: false, generation: 0, age: 0, dmsStale: false, plan: "go"});
    let stopped = false;
    let timer;
    let interval = REFRESH_MS;
    let warnedDms = false; // One toast per stale build, not one per turn

    const stored = Number(localStorage.getItem("usage-bar:interval"));
    if (INTERVALS.includes(stored)) interval = stored;

    const refreshUsage = async () => {
      try {
        const value = await usage.read({});
        if (stopped) return;
        usageState = {
          five: value.fivePercent,
          week: value.weekPercent,
          fiveCost: value.fiveCost,
          weekCost: value.weekCost,
          deepseek: value.deepseek,
          at: value.fetchedAt,
          error: "",
        };
      } catch (error) {
        if (stopped) return;
        usageState = {five: -1, week: -1, fiveCost: 0, weekCost: 0, deepseek: false, at: 0, error: String(error)};
      }
      paint();
    };

    const refreshState = async () => {
      try {
        const value = await usage.state({});
        if (stopped) return;
        repoState = {...value, plan: value.plan ?? "go"};
        setRepo(repoState);
        paintSettings();
        paintBadges();
      } catch {}
    };

    const refreshAll = () => {
      if (FEATURES.desktopBar) void refreshUsage();
      if (FEATURES.rebuildBadge) void refreshState();
    };

    const restartTimer = () => {
      clearInterval(timer);
      timer = setInterval(refreshAll, interval);
    };

    const restartDms = async () => {
      const notice = ctx.toast.show({variant: "loading", title: "Restarting DMS", persistent: true});
      try {
        const result = await usage.restartDms({});
        notice.dismiss();
        if (result.ok) {
          warnedDms = false;
          setRepo({...repo(), dmsStale: false});
          ctx.toast.show({variant: "success", title: "DMS restarted"});
        } else {
          ctx.toast.show({variant: "error", title: "DMS restart failed", description: result.error});
        }
      } catch (error) {
        notice.dismiss();
        ctx.toast.show({variant: "error", title: "DMS restart failed", description: String(error)});
      }
    };

    const rebuild = async () => {
      try {
        const result = await usage.askRebuild({});
        if (!result.ok) throw new Error(result.error);
      } catch (error) {
        ctx.toast.show({variant: "error", title: "Could not open Omni Settings", description: String(error)});
      }
    };

    if (FEATURES.desktopBar) void refreshUsage();
    void refreshState();
    restartTimer();

    const unsubscribe = usage.events.on("turn", (event) => {
      const value = event.data;
      repoState = {...repoState, ...value, plan: repo().plan};
      setRepo(repoState);
      paintBadges();
      if (!value.dmsStale) warnedDms = false;
      if (FEATURES.rebuildBadge && value.dmsStale && !warnedDms) {
        warnedDms = true;
        ctx.toast.show({
          variant: "default",
          title: "DMS restart needed",
          description: "DankMaterialShell is still on the previous build",
          duration: 12_000,
          actions: [{label: "Restart DMS", run: () => void restartDms()}],
        });
      }
      if (FEATURES.desktopBar) void refreshUsage();
    });

    if (FEATURES.desktopBar)
      ctx.add(Slot, {at: "window.bottom", order: 10, render: () => bar()});

    if (FEATURES.rebuildBadge) {
      ctx.add(Slot, {at: "session.header", order: 5, render: () => badge(() => void rebuild())});

      ctx.add(TitlebarItem, () => {
        const value = repo();
        if (!value.unbuilt) return undefined;
        return {
          id: "rebuild",
          label: "Rebuild ready",
          title: `${value.dirty} uncommitted file(s); running build is ${ageLabel(value.age)} old`,
          run: () => void rebuild(),
        };
      });

      ctx.add(TitlebarItem, () => {
        const value = repo();
        if (!value.dmsStale) return undefined;
        return {id: "restart-dms", label: "Restart DMS", title: "DMS is running the previous build", run: () => void restartDms()};
      });
    }

    ctx.add(SettingsPage, {
      id: "usage-bar",
      title: "Usage bar",
      render: () => {
        const root = document.createElement("div");
        root.style.cssText = "display:flex;flex-direction:column;gap:14px;padding:4px 0;font:13px system-ui,sans-serif;";

        const heading = document.createElement("div");
        heading.textContent = "Go plan";
        heading.style.cssText = "font-weight:600";

        const help = document.createElement("div");
        help.textContent =
          "The Console counts each model's cost against that model's own monthly limit. Pick the plan you subscribe to; Go Plus and Go Teams have larger limits.";
        help.style.cssText = `font-size:12px;line-height:1.5;color:${MUTED}`;

        const plans = document.createElement("div");
        plans.style.cssText = "display:flex;gap:8px;flex-wrap:wrap";

        const buttons = new Map();
        for (const [value, label] of [
          ["go", "Go"],
          ["go-plus", "Go Plus"],
          ["go-teams", "Go Teams"],
        ]) {
          const button = document.createElement("button");
          button.textContent = label;
          button.style.cssText = `font:12px system-ui,sans-serif;padding:6px 10px;border-radius:6px;border:1px solid ${BORDER};background:transparent;color:${TEXT};cursor:pointer`;
          button.onclick = async () => {
            try {
              const result = await usage.setPlan({plan: value});
              setRepo({...repo(), plan: result.plan});
              sync();
              void refreshUsage();
              ctx.toast.show({variant: "success", title: `Usage plan: ${label}`});
            } catch (error) {
              ctx.toast.show({variant: "error", title: "Could not save the plan", description: String(error)});
            }
          };
          buttons.set(value, button);
          plans.append(button);
        }

        const sync = () => {
          for (const [value, button] of buttons) {
            const active = repo().plan === value;
            button.style.borderColor = active ? ACCENT : BORDER;
            button.style.background = active ? TRACK : "transparent";
            button.setAttribute("aria-pressed", String(active));
          }
        };
        sync();
        syncers.add({root, sync});

        const intervalRow = document.createElement("label");
        intervalRow.textContent = "Refresh every ";
        intervalRow.style.cssText = `display:flex;align-items:center;gap:8px;color:${MUTED}`;
        const select = document.createElement("select");
        select.style.cssText = `font:12px system-ui,sans-serif;padding:4px 6px;border-radius:6px;border:1px solid ${BORDER};background:transparent;color:${TEXT}`;
        for (const [ms, label] of [
          [30_000, "30 seconds"],
          [60_000, "1 minute"],
          [300_000, "5 minutes"],
        ]) {
          const option = document.createElement("option");
          option.value = String(ms);
          option.textContent = label;
          select.append(option);
        }
        select.value = String(interval);
        select.onchange = () => {
          interval = Number(select.value);
          localStorage.setItem("usage-bar:interval", select.value);
          restartTimer();
        };
        intervalRow.append(select);

        root.append(heading, help, plans, intervalRow);
        return root;
      },
    });

    return () => {
      stopped = true;
      clearInterval(timer);
      unsubscribe();
    };
  },
});
