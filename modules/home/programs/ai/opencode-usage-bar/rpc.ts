//=====================================================================#
// OPENCODE USAGE BAR - RPC CONTRACT
//=====================================================================#
import {Rpc} from "@opencode/plugin/rpc";

const none = {type: "object", properties: {}, additionalProperties: false} as const;

export const UsageRpc = Rpc.define({
  id: "usage-bar",
  methods: {
    read: {
      input: none,
      output: {
        type: "object",
        properties: {
          fivePercent: {type: "number"},
          weekPercent: {type: "number"},
          fiveCost: {type: "number"},
          weekCost: {type: "number"},
          deepseek: {type: "boolean"},
          fetchedAt: {type: "number"},
        },
        required: ["fivePercent", "weekPercent", "fiveCost", "weekCost", "deepseek", "fetchedAt"],
        additionalProperties: false,
      },
    },
    state: {
      input: none,
      output: {
        type: "object",
        properties: {
          dirty: {type: "number"},
          unbuilt: {type: "boolean"},
          generation: {type: "number"},
          age: {type: "number"},
          dmsStale: {type: "boolean"},
          plan: {type: "string"},
        },
        required: ["dirty", "unbuilt", "generation", "age", "dmsStale", "plan"],
        additionalProperties: false,
      },
    },
    setPlan: {
      input: {
        type: "object",
        properties: {plan: {type: "string"}},
        required: ["plan"],
        additionalProperties: false,
      },
      output: {
        type: "object",
        properties: {plan: {type: "string"}},
        required: ["plan"],
        additionalProperties: false,
      },
    },
    restartDms: {
      input: none,
      output: {
        type: "object",
        properties: {ok: {type: "boolean"}, error: {type: "string"}},
        required: ["ok"],
        additionalProperties: false,
      },
    },
    askRebuild: {
      input: none,
      output: {
        type: "object",
        properties: {ok: {type: "boolean"}, error: {type: "string"}},
        required: ["ok"],
        additionalProperties: false,
      },
    },
  },
  events: {
    turn: {
      schema: {
        type: "object",
        properties: {
          dirty: {type: "number"},
          unbuilt: {type: "boolean"},
          generation: {type: "number"},
          age: {type: "number"},
          dmsStale: {type: "boolean"},
        },
        required: ["dirty", "unbuilt", "generation", "age", "dmsStale"],
        additionalProperties: false,
      },
    },
  },
});
