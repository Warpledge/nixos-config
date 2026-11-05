//=====================================================================#
// OPENCODE USAGE BAR - CONSOLE USAGE AND REPO STATE (SERVER)
//=====================================================================#
import {execFile} from "node:child_process";
import {lstat, readlink, realpath} from "node:fs/promises";
import {promisify} from "node:util";
import {Plugin} from "@opencode/plugin";
import {LIMITS, PLAN_CAP, PLANS, type Plan} from "./limits";
import {UsageRpc} from "./rpc";

const CONSOLE = "https://console.opencode.ai";
const CACHE_MS = 30_000;
const SYSTEM = "/nix/var/nix/profiles/system";
const FIVE_SHARE = 0.2;
const WEEK_SHARE = 0.5;
// The models DeepSeek's peak hours apply to; kept in step with tui.tsx
const DEEPSEEK = new Set(["deepseek-v4.1-flash", "deepseek-v4-pro"]);
// Nix fills these in: the repo a rebuild builds, and the switch under Omni Settings' AI
const FLAKE = "__FLAKE_PATH__";
const BADGE = "__REBUILD_BADGE__" === "1";

const run = promisify(execFile);

type Reading = {
  fivePercent: number;
  weekPercent: number;
  fiveCost: number;
  weekCost: number;
  deepseek: boolean;
  at: number;
};

type State = {
  dirty: number;
  unbuilt: boolean;
  generation: number;
  age: number;
  dmsStale: boolean;
  plan: Plan;
};

// Monday 00:00 UTC, the plan's calendar week
function weekStart(now: Date) {
  const day = (now.getUTCDay() + 6) % 7;
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - day));
}

function isPlan(value: unknown): value is Plan {
  return typeof value === "string" && (PLANS as readonly string[]).includes(value);
}

// /nix/store/<hash>-name/bin/... to /nix/store/<hash>-name
function storeRoot(path: string) {
  const parts = path.split("/");
  return parts.length >= 5 ? parts.slice(0, 5).join("/") : path;
}

async function git(directory: string, args: readonly string[]) {
  try {
    const {stdout} = await run("git", ["-C", directory, ...args], {timeout: 4000});
    return stdout;
  } catch {
    return undefined;
  }
}

// A rebuild changed DMS when the running process comes from another store path
async function dmsStale() {
  try {
    const {stdout} = await run("systemctl", ["--user", "show", "dms.service", "-p", "MainPID", "--value"], {
      timeout: 3000,
    });
    const pid = Number(stdout.trim());
    if (!Number.isFinite(pid) || pid <= 0) return false;
    const running = storeRoot(await readlink(`/proc/${pid}/exe`));
    const {stdout: which} = await run("which", ["dms"], {timeout: 2000});
    const current = storeRoot(await realpath(which.trim()));
    return running !== current;
  } catch {
    return false;
  }
}

export default Plugin.define({
  id: "usage-bar",
  async setup(ctx) {
    let cache: Reading | undefined;
    let pending: Promise<Reading> | undefined;

    const stored = await ctx.storage.get("plan");
    let plan: Plan = isPlan(stored) ? stored : "go";

    const snapshot = async (): Promise<State> => {
      const status = await git(FLAKE, ["status", "--porcelain"]);
      const head = await git(FLAKE, ["log", "-1", "--format=%ct"]);
      const dirty = status ? status.split("\n").filter(Boolean).length : 0;
      const committed = head ? Number(head.trim()) * 1000 : 0;
      let generation = 0;
      try {
        generation = (await lstat(SYSTEM)).mtimeMs;
      } catch {}
      return {
        dirty,
        unbuilt: dirty > 0 || (generation > 0 && committed > generation),
        generation,
        age: generation > 0 ? Date.now() - generation : 0,
        dmsStale: await dmsStale(),
        plan,
      };
    };

    const load = async (): Promise<Reading> => {
      const connection = await ctx.integration.connection.active("opencode");
      if (!connection) throw new Error("not signed in to opencode.ai");
      const credential = await ctx.integration.connection.resolve(connection);
      if (!credential || credential.type !== "oauth") throw new Error("no console token");
      const orgID = credential.metadata?.orgID;
      const limits = LIMITS[plan];

      const window = async (since: Date) => {
        const url = new URL(`${CONSOLE}/api/usage/models`);
        url.searchParams.set("since", since.toISOString());
        url.searchParams.set("pageSize", "100");
        const response = await fetch(url, {
          headers: {
            accept: "application/json",
            authorization: `Bearer ${credential.access}`,
            "user-agent": `opencode/${ctx.app.version}`,
            ...(typeof orgID === "string" ? {"x-opencode-org-id": orgID} : {}),
          },
        });
        if (!response.ok) throw new Error(`usage ${response.status}`);
        const body = (await response.json()) as {
          items?: readonly {model: string; totalCostMicroCents?: string | number}[];
        };
        let fraction = 0;
        let cost = 0;
        let deepseek = false;
        for (const item of body.items ?? []) {
          const dollars = Number(item.totalCostMicroCents ?? 0) / 1e8;
          const limit = limits[item.model] ?? PLAN_CAP[plan];
          cost += dollars;
          if (dollars > 0 && DEEPSEEK.has(item.model)) deepseek = true;
          if (Number.isFinite(limit) && limit > 0) fraction += dollars / limit;
        }
        return {fraction, cost, deepseek};
      };

      const now = new Date();
      const [five, week] = await Promise.all([
        window(new Date(now.getTime() - 5 * 60 * 60 * 1000)),
        window(weekStart(now)),
      ]);
      return {
        fivePercent: (five.fraction / FIVE_SHARE) * 100,
        weekPercent: (week.fraction / WEEK_SHARE) * 100,
        fiveCost: five.cost,
        weekCost: week.cost,
        deepseek: five.deepseek,
        at: now.getTime(),
      };
    };

    const read = async (): Promise<Reading> => {
      if (cache && Date.now() - cache.at < CACHE_MS) return cache;
      pending ??= load()
        .then((reading) => (cache = reading))
        .finally(() => (pending = undefined));
      return pending;
    };

    const registration = await ctx.rpc.register(UsageRpc, {
      read: async () => {
        const reading = await read();
        return {
          fivePercent: reading.fivePercent,
          weekPercent: reading.weekPercent,
          fiveCost: reading.fiveCost,
          weekCost: reading.weekCost,
          deepseek: reading.deepseek,
          fetchedAt: reading.at,
        };
      },
      state: async () => snapshot(),
      setPlan: async (raw) => {
        const input = raw as {plan?: unknown};
        if (!isPlan(input.plan)) throw new Error(`unknown plan: ${String(input.plan)}`);
        plan = input.plan;
        cache = undefined;
        await ctx.storage.set("plan", plan);
        return {plan};
      },
      restartDms: async () => {
        try {
          await run("systemctl", ["--user", "restart", "dms.service"], {timeout: 15_000});
          return {ok: true};
        } catch (error) {
          return {ok: false, error: String(error)};
        }
      },
      // Omni Settings' own Rebuild dialog picks the mode and checks nothing is pending
      askRebuild: async () => {
        try {
          await run("dms", ["ipc", "call", "omniSettings", "rebuild"], {timeout: 5000});
          return {ok: true};
        } catch (error) {
          return {ok: false, error: String(error)};
        }
      },
    });

    const controller = new AbortController();
    void (async () => {
      if (!BADGE) return;
      try {
        for await (const _ of ctx.event.subscribe({
          types: ["session.execution.succeeded"],
          signal: controller.signal,
        })) {
          const state = await snapshot();
          await registration.events.emit("turn", {
            dirty: state.dirty,
            unbuilt: state.unbuilt,
            generation: state.generation,
            age: state.age,
            dmsStale: state.dmsStale,
          });
        }
      } catch {}
    })();

    return () => {
      controller.abort();
      void registration.dispose();
    };
  },
});
