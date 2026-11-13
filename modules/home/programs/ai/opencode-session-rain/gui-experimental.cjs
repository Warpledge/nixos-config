"use strict";
//=====================================================================#
// SESSION RAIN - DESKTOP PANEL
//=====================================================================#
// Runs in every OpenCode Desktop window. The panel shows what the routed
// session runs on and uses: its project, context split, connectors,
// changes and background tasks. DOM nodes keep the file plain CJS;
// colours and fonts come from the app's own theme variables.
const {Command, MenuItem, Panel, Plugin} = require("@opencode/plugin/gui");
const {Changes} = require("@opencode/plugin/gui/review");
const {lastAssistantWithUsage} = require("@opencode/client/solid");

const ID = "session-rain";
const TAB = "main";
const KEY = `${ID}:${TAB}`;
const REFRESH_MS = 2000;
const CHILDREN_MS = 20_000;
const FINISHED = 5;

const TEXT = "var(--color-v2-text-text-base)";
const MUTED = "var(--color-v2-text-text-muted)";
const BORDER = "var(--color-v2-border-border-muted)";
const TRACK = "var(--color-v2-background-bg-layer-02)";
const ACCENT = "var(--color-v2-icon-icon-accent)";
const SUCCESS = "var(--color-v2-state-fg-success)";
const WARNING = "var(--color-v2-state-fg-warning)";
const DANGER = "var(--color-v2-state-fg-danger)";

// Matches rpc.ts. The client only reads ids, method names and events.
const Rain = {
  id: "session-rain",
  methods: {
    context: {
      input: {
        type: "object",
        properties: {sessionID: {type: "string"}},
        required: ["sessionID"],
        additionalProperties: false,
      },
      output: {type: "object", properties: {}, additionalProperties: true},
    },
  },
  events: {
    changed: {schema: {type: "object", properties: {}, additionalProperties: true}},
  },
};

const GROUPS = [
  ["messages", "Messages"],
  ["tools", "Tools"],
  ["mcpTools", "MCP tools"],
  ["system", "System prompt"],
  ["memory", "Memory files"],
  ["skills", "Skills"],
  ["mcpInstructions", "MCP instructions"],
  ["agents", "Custom agents"],
  ["instructions", "Instructions"],
];

const SHADES = {
  messages: 100,
  tools: 78,
  mcpTools: 58,
  system: 42,
  memory: 32,
  skills: 26,
  mcpInstructions: 20,
  agents: 14,
  instructions: 8,
};

const STATUS = {
  connected: "connected",
  pending: "starting",
  disabled: "off",
  needs_auth: "sign in",
  failed: "failed",
  unknown: "?",
};

function node(tag, style, text) {
  const element = document.createElement(tag);
  if (style) element.style.cssText = style;
  if (text) element.textContent = text;
  return element;
}

function shade(id, percent) {
  return `color-mix(in srgb, ${ACCENT} ${percent ?? SHADES[id] ?? 20}%, transparent)`;
}

function section(title) {
  const root = node("section", `display:flex;flex-direction:column;gap:6px;padding:10px 0;border-top:1px solid ${BORDER};`);
  const head = node("div", "display:flex;align-items:center;gap:8px;");
  head.append(
    node(
      "div",
      `font-size:0.78em;font-weight:600;letter-spacing:.05em;text-transform:uppercase;color:${MUTED};`,
      title,
    ),
  );
  const body = node("div", "display:flex;flex-direction:column;gap:4px;");
  root.append(head, body);
  return {root, head, body};
}

function row(label, value) {
  const root = node("div", "display:flex;align-items:baseline;gap:8px;font-size:0.85em;");
  const name = node("span", `color:${MUTED};white-space:nowrap;`, label);
  const fill = node("span", `flex:1;border-bottom:1px dotted ${BORDER};transform:translateY(-2px);`);
  const last = node("span", `font-variant-numeric:tabular-nums;white-space:nowrap;`, value);
  root.append(name, fill, last);
  return {root, value: last};
}

function formatTokens(value) {
  const n = Math.max(0, Math.round(value));
  if (n >= 1e6) return `${(n / 1e6).toFixed(1).replace(/\.0$/, "")}M`;
  if (n >= 1e3) return `${(n / 1e3).toFixed(1).replace(/\.0$/, "")}k`;
  return String(n);
}

function formatPercent(value) {
  if (!Number.isFinite(value) || value <= 0) return "0%";
  return value < 10 ? `${value.toFixed(1)}%` : `${Math.round(value)}%`;
}

function formatDuration(ms) {
  const seconds = Math.max(0, Math.round(ms / 1000));
  if (seconds < 60) return `${seconds}s`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ${seconds % 60}s`;
  return `${Math.floor(minutes / 60)}h ${minutes % 60}m`;
}

function relative(at) {
  if (!at) return "not measured yet";
  const ms = Date.now() - at;
  if (ms < 30_000) return "just now";
  if (ms < 3_600_000) return `${Math.max(1, Math.round(ms / 60_000))}m ago`;
  if (ms < 86_400_000) return `${Math.round(ms / 3_600_000)}h ago`;
  return `${Math.round(ms / 86_400_000)}d ago`;
}

function shortPath(directory) {
  return String(directory ?? "").replace(/^\/home\/[^/]+/, "~");
}

function baseName(directory) {
  return String(directory ?? "").split("/").filter(Boolean).pop() ?? String(directory ?? "");
}

function sumTokens(tokens) {
  if (!tokens) return 0;
  return (
    (tokens.input ?? 0) +
    (tokens.output ?? 0) +
    (tokens.reasoning ?? 0) +
    (tokens.cache?.read ?? 0) +
    (tokens.cache?.write ?? 0)
  );
}

function empty() {
  return {updatedAt: 0, limit: 0, system: 0, tools: 0, mcp: 0, messages: 0, residual: 0, sources: []};
}

// The instruction sources carry keys such as core/codemode, project files
// or skills; anything unrecognised stays in Instructions.
function groups(reading) {
  const mapped = new Map();
  for (const source of reading.sources ?? []) {
    const key = String(source.key ?? "").toLowerCase();
    const core = key.startsWith("core/");
    const id = core
      ? key.includes("skill")
        ? "skills"
        : key.includes("agent")
          ? "agents"
          : "system"
      : key.includes("skill")
        ? "skills"
        : key.includes("mcp")
          ? "mcpInstructions"
          : key.includes("agents.md") || key.includes("claude") || key.includes("memory")
            ? "memory"
            : key.includes("agent")
              ? "agents"
              : "instructions";
    mapped.set(id, (mapped.get(id) ?? 0) + (source.tokens ?? 0));
  }
  if (reading.residual > 0) mapped.set("instructions", (mapped.get("instructions") ?? 0) + reading.residual);

  const values = {
    messages: reading.messages ?? 0,
    tools: Math.max(0, (reading.tools ?? 0) - (reading.mcp ?? 0)),
    mcpTools: reading.mcp ?? 0,
    system: (reading.system ?? 0) + (mapped.get("system") ?? 0),
    memory: mapped.get("memory") ?? 0,
    skills: mapped.get("skills") ?? 0,
    mcpInstructions: mapped.get("mcpInstructions") ?? 0,
    agents: mapped.get("agents") ?? 0,
    instructions: mapped.get("instructions") ?? 0,
  };

  return GROUPS.map(([id, label]) => ({id, label, tokens: values[id]})).filter((group) => group.tokens > 0);
}

function connectorDot(tone) {
  return node("span", `flex:none;width:7px;height:7px;border-radius:50%;background:${tone};`);
}

function panel(ctx, props, changes) {
  const root = node(
    "div",
    `display:flex;flex-direction:column;min-height:0;padding:2px 12px 12px;color:${TEXT};overflow-y:auto;`,
  );

  //--------------------------------------------------------------------#
  //-- Environment
  //--------------------------------------------------------------------#
  const environment = section("Environment");
  const project = node("div", "font-weight:600;overflow-wrap:anywhere;");
  const directory = node("div", `font-size:0.82em;color:${MUTED};overflow-wrap:anywhere;`);
  const branch = row("Branch", "—");
  const kind = node("div", `font-size:0.82em;color:${MUTED};`);
  environment.body.append(project, directory, branch.root, kind);

  //--------------------------------------------------------------------#
  //-- Context
  //--------------------------------------------------------------------#
  const context = section("Context");
  const contextHead = node("div", "display:flex;align-items:baseline;gap:8px;");
  const contextPercent = node("div", "font-size:1.35em;font-weight:600;font-variant-numeric:tabular-nums;");
  const contextTotal = node("div", `margin-left:auto;font-size:0.82em;color:${MUTED};font-variant-numeric:tabular-nums;`);
  contextHead.append(contextPercent, contextTotal);
  const contextBar = node("div", `display:flex;height:6px;border-radius:3px;overflow:hidden;background:${TRACK};`);
  const contextRows = node("div", "display:flex;flex-direction:column;gap:3px;");
  const contextUpdated = node("div", `font-size:0.78em;line-height:1.4;color:${MUTED};`);
  context.body.append(contextHead, contextBar, contextRows, contextUpdated);

  //--------------------------------------------------------------------#
  //-- Connectors
  //--------------------------------------------------------------------#
  const connectors = section("Connectors");
  const connectorCount = node("span", `margin-left:auto;font-size:0.78em;color:${MUTED};`);
  connectors.head.append(connectorCount);
  const connectorRows = node("div", "display:flex;flex-direction:column;gap:3px;");
  connectors.body.append(connectorRows);

  //--------------------------------------------------------------------#
  //-- Changes
  //--------------------------------------------------------------------#
  const changesSection = section("Changes");
  const changesHead = node("div", "display:flex;align-items:center;gap:10px;");
  const additions = node("span", `font-weight:600;color:${SUCCESS};font-variant-numeric:tabular-nums;`);
  const deletions = node("span", `font-weight:600;color:${DANGER};font-variant-numeric:tabular-nums;`);
  const changedFiles = node("span", `font-size:0.82em;color:${MUTED};`);
  const review = node(
    "button",
    `margin-left:auto;font:inherit;font-size:0.8em;padding:3px 10px;border-radius:6px;border:1px solid ${BORDER};background:${TRACK};color:${TEXT};cursor:pointer;`,
    "Review",
  );
  const changesNote = node("div", `font-size:0.78em;color:${MUTED};`);
  changesHead.append(additions, deletions, changedFiles, review);
  changesSection.body.append(changesHead, changesNote);

  //--------------------------------------------------------------------#
  //-- Background tasks
  //--------------------------------------------------------------------#
  const tasks = section("Background tasks");
  const taskCount = node("span", `margin-left:auto;font-size:0.78em;color:${MUTED};`);
  tasks.head.append(taskCount);
  const taskRows = node("div", "display:flex;flex-direction:column;gap:3px;");
  tasks.body.append(taskRows);

  root.append(environment.root, context.root, connectors.root, changesSection.root, tasks.root);

  let reading = empty();
  let sessionID = "";
  let children = {at: 0, session: "", data: []};
  let watch;
  let watched = false;
  let busy = false;
  let stopped = false;
  let timer;

  const store = () => {
    try {
      return props.session?.server?.data;
    } catch {
      return undefined;
    }
  };

  const messageList = () => {
    try {
      const list = store()?.session?.message?.list?.(props.session.id);
      return Array.isArray(list) ? list : [];
    } catch {
      return [];
    }
  };

  const load = async () => {
    const session = props.session;
    if (!session) return;
    if (session.id !== sessionID) {
      sessionID = session.id;
      reading = empty();
      children = {at: 0, session: "", data: []};
    }
    if (busy) return;
    busy = true;
    try {
      const value = await ctx.client.rpc(Rain).context({sessionID: session.id});
      if (value) reading = value;
    } catch {}
    try {
      if (children.session !== session.id || Date.now() - children.at > CHILDREN_MS) {
        const page = await ctx.client.session.list({parentID: session.id, limit: 50});
        children = {at: Date.now(), session: session.id, data: Array.isArray(page?.data) ? page.data : []};
      }
    } catch {}
    busy = false;
  };

  const paintBar = (used, limit, value) => {
    contextBar.replaceChildren();
    const usedFraction = limit > 0 ? Math.min(1, Math.max(0, used / limit)) : 0;
    if (usedFraction <= 0) return;

    const list = groups(value);
    const estimate = list.reduce((total, group) => total + group.tokens, 0);
    if (estimate <= 0) {
      contextBar.append(node("div", `width:${usedFraction * 100}%;background:${ACCENT};`));
    } else {
      for (const group of list) {
        const share = (group.tokens / estimate) * usedFraction * 100;
        if (share <= 0) continue;
        const part = node("div", `width:${share}%;background:${shade(group.id)};`);
        part.title = `${group.label}: about ${formatTokens(group.tokens)} tokens`;
        contextBar.append(part);
      }
    }
    if (usedFraction < 1) contextBar.append(node("div", "flex:1;"));
  };

  const paintContext = (used, limit, value) => {
    contextRows.replaceChildren();
    const list = groups(value);
    for (const group of list) {
      const line = node("div", "display:flex;align-items:center;gap:6px;font-size:0.82em;");
      line.append(
        connectorDot(shade(group.id)),
        node("span", `color:${MUTED};white-space:nowrap;`, group.label),
        node(
          "span",
          `margin-left:auto;font-variant-numeric:tabular-nums;white-space:nowrap;`,
          formatTokens(group.tokens),
        ),
        node(
          "span",
          `width:6ch;text-align:right;font-variant-numeric:tabular-nums;color:${MUTED};white-space:nowrap;`,
          limit > 0 ? formatPercent((group.tokens / limit) * 100) : "",
        ),
      );
      contextRows.append(line);
    }

    const free = limit > 0 ? Math.max(0, limit - used) : 0;
    if (free > 0) {
      const line = node("div", "display:flex;align-items:center;gap:6px;font-size:0.82em;");
      line.append(
        connectorDot(TRACK),
        node("span", `color:${MUTED};white-space:nowrap;`, "Free space"),
        node(
          "span",
          `margin-left:auto;font-variant-numeric:tabular-nums;white-space:nowrap;color:${MUTED};`,
          formatTokens(free),
        ),
        node(
          "span",
          `width:6ch;text-align:right;font-variant-numeric:tabular-nums;color:${MUTED};white-space:nowrap;`,
          formatPercent((free / limit) * 100),
        ),
      );
      contextRows.append(line);
    }

    contextUpdated.textContent = value.updatedAt
      ? `Estimated split from the last request, ${relative(value.updatedAt)}. The total is exact.`
      : "The split appears after this session's next turn.";
  };

  const paintConnectors = (data) => {
    const session = props.session;
    let mcp = [];
    let integrations = [];
    try {
      const list = data?.location?.mcp?.server?.list?.(session.location);
      mcp = Array.isArray(list) ? list : [];
    } catch {}
    try {
      const list = data?.location?.integration?.list?.(session.location);
      integrations = Array.isArray(list) ? list : [];
    } catch {}

    const list = [
      ...mcp.map((server) => ({
        id: `mcp:${server.name}`,
        name: server.title || server.name,
        kind: "MCP",
        state: server.status?.status ?? "unknown",
      })),
      ...integrations.map((integration) => {
        const connections = integration.connections ?? [];
        const broken = connections.some((connection) => connection?.status?.status === "needs_auth");
        return {
          id: `integration:${integration.id}`,
          name: integration.name,
          kind: "Integration",
          state: connections.length > 0 && !broken ? "connected" : "disabled",
        };
      }),
    ];

    const connected = list.filter((item) => item.state === "connected").length;
    connectorCount.textContent = list.length > 0 ? `${connected}/${list.length} connected` : "";
    connectorRows.replaceChildren();

    for (const item of list) {
      const tone =
        item.state === "connected"
          ? SUCCESS
          : item.state === "failed"
            ? DANGER
            : item.state === "pending" || item.state === "needs_auth"
              ? WARNING
              : MUTED;
      const line = node("div", "display:flex;align-items:center;gap:6px;font-size:0.82em;");
      line.append(
        connectorDot(tone),
        node("span", "overflow:hidden;text-overflow:ellipsis;white-space:nowrap;", item.name),
        node("span", `font-size:0.9em;color:${MUTED};white-space:nowrap;`, item.kind),
        node(
          "span",
          `margin-left:auto;font-size:0.9em;color:${MUTED};white-space:nowrap;`,
          STATUS[item.state] ?? item.state,
        ),
      );
      connectorRows.append(line);
    }

    if (list.length === 0) connectorRows.append(node("div", `font-size:0.82em;color:${MUTED};`, "None connected."));
  };

  const paintChanges = (session) => {
    const live = changes();
    let diffs = [];
    if (live.status === "active") {
      try {
        const list = live.value.diffs(session);
        diffs = Array.isArray(list) ? list : [];
      } catch {}
    }

    const add = diffs.reduce((total, diff) => total + (diff.additions ?? 0), 0);
    const del = diffs.reduce((total, diff) => total + (diff.deletions ?? 0), 0);
    additions.textContent = `+${add.toLocaleString()}`;
    deletions.textContent = `−${del.toLocaleString()}`;
    changedFiles.textContent = diffs.length > 0 ? `${diffs.length} file${diffs.length === 1 ? "" : "s"}` : "";
    changesNote.textContent =
      live.status !== "active" ? "Change data unavailable." : diffs.length > 0 ? "" : "No changes in the review.";
    review.disabled = live.status !== "active";
    review.style.opacity = review.disabled ? "0.5" : "1";
    review.style.cursor = review.disabled ? "default" : "pointer";
    review.onclick = () => {
      if (live.status === "active") live.value.open(session);
    };

    if (!watched && live.status === "active") {
      try {
        watch = live.value.watch(props.screen, "tree");
        watched = true;
      } catch {}
    }
  };

  const finishedTasks = (session) => {
    const known = new Map();
    for (const child of children.data) if (child?.id) known.set(child.id, child);
    try {
      for (const id of store()?.session?.family?.(session.id) ?? []) {
        const child = store()?.session?.get?.(id);
        if (child?.id) known.set(child.id, child);
      }
    } catch {}

    const subagents = [...known.values()]
      .filter((child) => child.parentID === session.id && child.outcome)
      .map((child) => ({
        id: `subagent:${child.id}`,
        label: child.title ?? child.agent ?? "Subagent",
        state: child.outcome,
        duration: Math.max(0, (child.time?.updated ?? 0) - (child.time?.created ?? 0)),
        open: () => ctx.tabs.open({server: session.server.id, id: child.id}, {focus: true}),
      }));

    const all = subagents.sort((a, b) => b.duration - a.duration);
    return {all, count: all.length};
  };

  const taskLine = (task, running) => {
    const tone =
      running || task.state === "succeeded" || task.state === "exited"
        ? running
          ? ACCENT
          : SUCCESS
        : task.state === "failed" || task.state === "error" || task.state === "timeout" || task.state === "killed"
          ? DANGER
          : MUTED;
    const label =
      running || task.state === "succeeded" || task.state === "exited"
        ? running
          ? "running"
          : "done"
        : STATUS[task.state] ?? String(task.state ?? "");
    const line = node(
      "div",
      "display:flex;align-items:center;gap:6px;font-size:0.82em;",
    );
    line.append(
      connectorDot(tone),
      node("span", "overflow:hidden;text-overflow:ellipsis;white-space:nowrap;", task.label),
      node("span", `margin-left:auto;font-size:0.9em;color:${MUTED};white-space:nowrap;`, label),
      node(
        "span",
        `width:7ch;text-align:right;font-size:0.9em;color:${MUTED};font-variant-numeric:tabular-nums;white-space:nowrap;`,
        task.duration !== undefined ? formatDuration(task.duration) : "",
      ),
    );
    if (task.open) {
      line.style.cursor = "pointer";
      line.onclick = task.open;
      line.title = "Open this subagent's session";
    }
    return line;
  };

  const paintTasks = (session) => {
    const running = Array.isArray(session.background) ? session.background : [];
    const finished = finishedTasks(session);
    taskCount.textContent = finished.count > 0 ? `${finished.count} finished` : "";
    taskRows.replaceChildren();

    for (const task of running) {
      taskRows.append(taskLine({label: task.label ?? task.agent ?? task.type, state: "running"}, true));
    }
    for (const task of finished.all.slice(0, FINISHED)) taskRows.append(taskLine(task, false));
    if (running.length === 0 && finished.all.length === 0) {
      taskRows.append(node("div", `font-size:0.82em;color:${MUTED};`, "No background tasks."));
    }
  };

  const paint = () => {
    const session = props.session;
    if (!session) return;
    const data = store();
    let info;
    try {
      info = data?.session?.get?.(session.id);
    } catch {}
    const messages = messageList();
    const step = lastAssistantWithUsage(messages, info?.revert?.messageID);
    const used = step?.tokens ? sumTokens(step.tokens) : 0;
    const ref = step?.model ?? info?.model;
    let models = [];
    try {
      const list = data?.location?.model?.list?.(session.location);
      models = Array.isArray(list) ? list : [];
    } catch {}
    const model = ref
      ? models.find(
          (item) => item.providerID === ref.providerID && (item.id === ref.id || item.modelID === ref.id),
        )
      : undefined;
    const limit = model?.limit?.context ?? reading.limit ?? 0;

    project.textContent = session.listedProject?.name ?? session.project?.name ?? baseName(session.directory);
    directory.textContent = shortPath(session.directory);
    try {
      branch.value.textContent = data?.location?.vcs?.info?.(session.location)?.branch?.current ?? "—";
    } catch {
      branch.value.textContent = "—";
    }
    kind.textContent = session.local ? "Project root" : "Worktree";

    const percent = limit > 0 ? (used / limit) * 100 : 0;
    contextPercent.textContent = limit > 0 ? formatPercent(percent) : "—";
    contextTotal.textContent =
      limit > 0 ? `${formatTokens(used)} / ${formatTokens(limit)}` : `${formatTokens(used)} tokens`;
    paintBar(used, limit, reading);
    paintContext(used, limit, reading);
    paintConnectors(data);
    paintChanges(session);
    paintTasks(session);
  };

  const stop = () => {
    if (stopped) return;
    stopped = true;
    clearInterval(timer);
    unsubscribe();
    try {
      watch?.();
    } catch {}
  };

  const tick = async () => {
    if (stopped) return;
    if (!root.isConnected) {
      stop();
      return;
    }
    await load();
    paint();
  };

  let unsubscribe = () => {};
  try {
    unsubscribe = ctx.client.rpc(Rain).events.on("changed", (event) => {
      if (event?.data?.sessionID === props.session?.id) void tick();
    });
  } catch {}

  timer = setInterval(() => void tick(), REFRESH_MS);
  void tick();

  return root;
}

module.exports = Plugin.define({
  setup(ctx) {
    const changes = ctx.use(Changes);

    const open = () => {
      const session = ctx.sessions.current();
      if (session) ctx.layout.open(KEY, session, {tab: "select"});
    };

    const tab = {
      id: TAB,
      get title() {
        return "Session Rain";
      },
      closable: "compact",
    };

    ctx.add(Panel, {
      id: TAB,
      region: "side",
      mobile: {
        get title() {
          return "Session Rain";
        },
        order: 40,
        kind: "menu",
        icon: "window-analytics",
      },
      list: (input) => (input.open.includes(TAB) ? [tab] : []),
      render: (props) => panel(ctx, props, changes),
    });

    ctx.add(MenuItem, () => {
      const session = ctx.sessions.current();
      if (!session) return undefined;
      return {
        menu: "session.panel",
        id: "open",
        title: "Session Rain",
        icon: "window-analytics",
        description: "Context, connectors, changes and tasks",
        opened: ctx.layout.state(KEY, session) !== "closed",
        run: open,
      };
    });

    ctx.add(Command, () => ({
      id: "open",
      title: "Open Session Rain",
      keywords: "context connectors changes tasks background",
      section: "navigation",
      run: open,
    }));
  },
});
