//=====================================================================#
// OPENCODE USAGE BAR - RPC CONTRACT
//=====================================================================#
import {Rpc} from "@opencode/plugin/rpc";

export const UsageRpc = Rpc.define({
  id: "usage-bar",
  methods: {
    read: {
      input: {
        type: "object",
        properties: {},
        additionalProperties: false,
      },
      output: {
        type: "object",
        properties: {
          fiveHourCost: {type: "number"},
          weekCost: {type: "number"},
          fetchedAt: {type: "number"},
        },
        required: ["fiveHourCost", "weekCost", "fetchedAt"],
        additionalProperties: false,
      },
    },
  },
  events: {},
});
