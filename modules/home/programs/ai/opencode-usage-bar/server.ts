//=====================================================================#
// OPENCODE USAGE BAR - CONSOLE USAGE (SERVER)
//=====================================================================#
// The Console endpoint behind opencode.ai/console takes a time range and
// reports exact list cost per model. The Go plan counts that cost against
// each model's own monthly limit, so a dollar of DeepSeek counts five
// times less than a dollar of a $20 model.
import {Plugin} from "@opencode/plugin";
import {UsageRpc} from "./rpc";

const CONSOLE = "https://console.opencode.ai";
const CACHE_MS = 30_000;

// Monthly limit per model, in dollars, for the Go plan.
// https://opencode.ai/console/go#usage-limits, read 2026-11-01. Go Plus and
// Go Teams use larger amounts, so their percentages would read low here.
const MONTHLY_LIMITS: Record<string, number> = {
  "glm-5.3-flash": 60,
  "glm-5.3": 15,
  "glm-5.2": 60,
  "kimi-k3.1-pro": 15,
  "kimi-k3": 15,
  "kimi-k2.7-code": 60,
  "longcat-2.0": 60,
  "step-5-preview": 15,
  "mimo-v2.6-flash": 60,
  "mimo-v2.6-pro": 15,
  "mimo-v2.5": 60,
  "mimo-v2.5-pro": 15,
  "minimax-m3.1-flash": 20,
  "minimax-m3": 60,
  "muse-spark-1.3-contributor": 60,
  "muse-spark-1.2-contributor": 60,
  "qwen3.8-max": 15,
  "qwen3.8-flash": 30,
  "qwen3.7-plus": 60,
  "deepseek-v4.1-flash": 100,
  "deepseek-v4-pro": 15,
  "hy4-preview": 30,
  "hy3": 60,
  "grok-4.7": 15,
  "gpt-6-luna": 15,
  "gpt-5.6-luna": 15,
  "claude-haiku-5-5": 15,
  "gemini-4-argon": 30,
  "beam-free": Infinity,
  "iceman-contributor-free": Infinity,
};

// An unknown model has no table entry; the plan's own $60 cap is the closest
const FALLBACK_LIMIT = 60;
const FIVE_SHARE = 0.2;
const WEEK_SHARE = 0.5;

type Reading = {
  fivePercent: number;
  weekPercent: number;
  fiveCost: number;
  weekCost: number;
  at: number;
};

// Monday 00:00 UTC, the plan's calendar week
function weekStart(now: Date) {
  const day = (now.getUTCDay() + 6) % 7;
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - day));
}

export default Plugin.define({
  id: "usage-bar",
  async setup(ctx) {
    let cache: Reading | undefined;
    let pending: Promise<Reading> | undefined;

    const load = async (): Promise<Reading> => {
      const connection = await ctx.integration.connection.active("opencode");
      if (!connection) throw new Error("not signed in to opencode.ai");
      const credential = await ctx.integration.connection.resolve(connection);
      if (!credential || credential.type !== "oauth") throw new Error("no console token");
      const orgID = credential.metadata?.orgID;

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
        for (const item of body.items ?? []) {
          const dollars = Number(item.totalCostMicroCents ?? 0) / 1e8;
          const limit = MONTHLY_LIMITS[item.model] ?? FALLBACK_LIMIT;
          cost += dollars;
          if (Number.isFinite(limit) && limit > 0) fraction += dollars / limit;
        }
        return {fraction, cost};
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
          fetchedAt: reading.at,
        };
      },
    });

    return () => {
      void registration.dispose();
    };
  },
});
