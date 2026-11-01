//=====================================================================#
// OPENCODE USAGE BAR - CONSOLE USAGE (SERVER)
//=====================================================================#
// The Console endpoint behind opencode.ai/console takes a time range and
// reports exact list cost for the whole workspace, which is what the Go plan
// counts against its 5-hour and weekly limits.
import {Plugin} from "@opencode/plugin";
import {UsageRpc} from "./rpc";

const CONSOLE = "https://opencode.ai";
const CACHE_MS = 30_000;

type Reading = {
  five: number;
  week: number;
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

      const read = async (since: Date) => {
        const url = new URL(`${CONSOLE}/api/usage/summary`);
        url.searchParams.set("since", since.toISOString());
        const response = await fetch(url, {
          headers: {
            accept: "application/json",
            authorization: `Bearer ${credential.access}`,
            "user-agent": `opencode/${ctx.app.version}`,
            ...(typeof orgID === "string" ? {"x-opencode-org-id": orgID} : {}),
          },
        });
        if (!response.ok) throw new Error(`usage ${response.status}`);
        const body = (await response.json()) as {totalCostMicroCents?: string | number};
        return Number(body.totalCostMicroCents ?? 0) / 1e8;
      };

      const now = new Date();
      const [five, week] = await Promise.all([
        read(new Date(now.getTime() - 5 * 60 * 60 * 1000)),
        read(weekStart(now)),
      ]);
      return {five, week, at: now.getTime()};
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
        return {fiveHourCost: reading.five, weekCost: reading.week, fetchedAt: reading.at};
      },
    });

    return () => {
      void registration.dispose();
    };
  },
});
