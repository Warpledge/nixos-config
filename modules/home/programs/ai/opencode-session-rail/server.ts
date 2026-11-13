//=====================================================================#
// SESSION RAIL - CONTEXT SPLIT (SERVER)
//=====================================================================#
// Measures the request OpenCode assembles for each model call, so the
// desktop panel can show where the context goes. The figures are
// estimates at about four characters per token.
import {Plugin} from "@opencode/plugin";
import {RailRpc} from "./rpc";

type Source = {key: string; tokens: number};
type Reading = {
  updatedAt: number;
  limit: number;
  system: number;
  tools: number;
  mcp: number;
  messages: number;
  residual: number;
  sources: Source[];
};

type Instruction = {key?: unknown; text?: unknown};
type SystemPart = {
  text?: unknown;
  metadata?: {experimental?: {instructions?: readonly Instruction[]}};
};

type ContextEvent = {
  sessionID: string;
  model?: {providerID: string; id: string};
  system?: readonly SystemPart[];
  messages?: readonly unknown[];
  tools?: Readonly<Record<string, {description?: unknown; input?: unknown}>>;
};

// Measurements outlive one routed session, so the panel can read the last
// turn for a tab the user just opened. Bounded to keep the map small.
const MAX = 60;
const measurements = new Map<string, Reading>();

function empty(): Reading {
  return {updatedAt: 0, limit: 0, system: 0, tools: 0, mcp: 0, messages: 0, residual: 0, sources: []};
}

// Length of text, or of its JSON form for tool schemas and messages
function length(value: unknown) {
  if (typeof value === "string") return value.length;
  try {
    return JSON.stringify(value)?.length ?? 0;
  } catch {
    return 0;
  }
}

function tokens(chars: number) {
  return Math.ceil(chars / 4);
}

function measure(event: ContextEvent, limit: number, prefixes: readonly string[]): Reading {
  let systemChars = 0;
  let residualChars = 0;
  const sources = new Map<string, number>();

  for (const part of event.system ?? []) {
    const text = typeof part.text === "string" ? part.text : "";
    const entries = part.metadata?.experimental?.instructions;
    if (Array.isArray(entries) && entries.length > 0) {
      let used = 0;
      for (const entry of entries) {
        const key = typeof entry?.key === "string" ? entry.key : "other";
        const size = typeof entry?.text === "string" ? entry.text.length : 0;
        used += size;
        sources.set(key, (sources.get(key) ?? 0) + size);
      }
      residualChars += Math.max(0, text.length - used);
    } else {
      systemChars += text.length;
    }
  }

  let toolChars = 0;
  let mcpChars = 0;
  for (const [name, tool] of Object.entries(event.tools ?? {})) {
    const chars = name.length + length(tool?.description) + length(tool?.input);
    toolChars += chars;
    if (prefixes.some((prefix) => name.startsWith(`${prefix}_`) || name.startsWith(`${prefix}.`))) mcpChars += chars;
  }

  let messageChars = 0;
  for (const message of event.messages ?? []) messageChars += length(message);

  return {
    updatedAt: Date.now(),
    limit,
    system: tokens(systemChars),
    tools: tokens(toolChars),
    mcp: tokens(mcpChars),
    messages: tokens(messageChars),
    residual: tokens(residualChars),
    sources: [...sources.entries()]
      .map(([key, chars]) => ({key, tokens: tokens(chars)}))
      .filter((source) => source.tokens > 0)
      .sort((a, b) => b.tokens - a.tokens),
  };
}

function trim() {
  while (measurements.size > MAX) {
    const first = measurements.keys().next().value;
    if (typeof first !== "string") return;
    measurements.delete(first);
  }
}

export default Plugin.define({
  id: "session-rail",
  async setup(ctx) {
    const modelLimit = async (ref: ContextEvent["model"]) => {
      if (!ref) return 0;
      try {
        const result = await ctx.model.list();
        const models = (Array.isArray(result) ? result : (result as unknown as {data?: unknown[]}).data ?? []) as {
          providerID?: string;
          id?: string;
          modelID?: string;
          limit?: {context?: number};
        }[];
        const found = models.find(
          (model) => model.providerID === ref.providerID && (model.id === ref.id || model.modelID === ref.id),
        );
        return found?.limit?.context ?? 0;
      } catch {
        return 0;
      }
    };

    // Tool names carry the MCP server as a prefix, e.g. context7_query-docs.
    // The list changes rarely, so one read a minute is enough.
    let mcp = {at: 0, names: [] as string[]};
    const mcpPrefixes = async () => {
      if (Date.now() - mcp.at < 60_000) return mcp.names;
      try {
        const result = await ctx.mcp.list();
        const servers = (Array.isArray(result) ? result : (result as unknown as {data?: unknown[]}).data ?? []) as {
          name?: string;
        }[];
        mcp = {at: Date.now(), names: servers.map((server) => server.name).filter((name): name is string => !!name)};
      } catch {
        mcp = {at: Date.now(), names: []};
      }
      return mcp.names;
    };

    const registration = await ctx.rpc.register(RailRpc, {
      context: async (raw) => {
        const input = raw as {sessionID?: unknown};
        const sessionID = typeof input.sessionID === "string" ? input.sessionID : "";
        return measurements.get(sessionID) ?? empty();
      },
    });

    const record = async (event: ContextEvent) => {
      const [limit, prefixes] = await Promise.all([modelLimit(event.model), mcpPrefixes()]);
      measurements.set(event.sessionID, measure(event, limit, prefixes));
      trim();
      void registration.events.emit("changed", {sessionID: event.sessionID});
    };

    const hook = await ctx.session.hook("context", async (event) => {
      try {
        await record(event as unknown as ContextEvent);
      } catch {}
    });

    return () => {
      void hook.dispose();
      void registration.dispose();
    };
  },
});
