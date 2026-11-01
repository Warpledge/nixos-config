"use strict";
//=====================================================================#
// OPENCODE USAGE BAR - DESKTOP PILL
//=====================================================================#
// Runs in every OpenCode Desktop window. The TUI part's slots do not exist
// here, so the same numbers ride a composer pill instead.
const {ComposerPill, Plugin} = require("@opencode/plugin/gui");
const {createSignal} = require("solid-js");

// Go plan caps: 5-hour 20% and week 50% of the $60 monthly allowance
const FIVE_CAP = 12;
const WEEK_CAP = 30;
const REFRESH_MS = 60_000;

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

function percent(spend, cap) {
  return Math.min(100, Math.round((spend / cap) * 100));
}

module.exports = Plugin.define({
  setup(ctx) {
    const [reading, setReading] = createSignal({five: -1, week: -1, at: 0, error: ""});
    let stopped = false;

    const refresh = async () => {
      try {
        const value = await ctx.client.rpc(Usage).read({});
        if (stopped) return;
        setReading({five: value.fiveHourCost, week: value.weekCost, at: value.fetchedAt, error: ""});
      } catch (error) {
        if (stopped) return;
        setReading({five: -1, week: -1, at: 0, error: String(error)});
      }
    };

    void refresh();
    const timer = setInterval(() => void refresh(), REFRESH_MS);

    ctx.add(ComposerPill, {
      id: "usage",
      order: 10,
      show: () => {
        const value = reading();
        if (value.error) return {label: "usage ?", tone: "warning"};
        if (value.at === 0) return {label: "usage …"};
        const five = percent(value.five, FIVE_CAP);
        const week = percent(value.week, WEEK_CAP);
        return {
          label: `5H ${five}% · WK ${week}% · ${peakHours(new Date()) ? "PEAK" : "OFF-PEAK"}`,
          title: `Go usage: $${value.five.toFixed(2)} of $${FIVE_CAP} in the last 5 hours, $${value.week.toFixed(2)} of $${WEEK_CAP} this week`,
          tone: five >= 90 || week >= 90 ? "danger" : five >= 70 || week >= 70 ? "warning" : undefined,
        };
      },
    });

    return () => {
      stopped = true;
      clearInterval(timer);
    };
  },
});
