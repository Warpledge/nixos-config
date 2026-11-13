//=====================================================================#
// SESSION RAIL - RPC CONTRACT
//=====================================================================#
import {Rpc} from "@opencode/plugin/rpc";

const source = {
  type: "object",
  properties: {
    key: {type: "string"},
    tokens: {type: "number"},
  },
  required: ["key", "tokens"],
  additionalProperties: false,
} as const;

const reading = {
  type: "object",
  properties: {
    updatedAt: {type: "number"},
    limit: {type: "number"},
    system: {type: "number"},
    tools: {type: "number"},
    mcp: {type: "number"},
    messages: {type: "number"},
    residual: {type: "number"},
    sources: {type: "array", items: source},
  },
  required: ["updatedAt", "limit", "system", "tools", "mcp", "messages", "residual", "sources"],
  additionalProperties: false,
} as const;

export const RailRpc = Rpc.define({
  id: "session-rail",
  methods: {
    context: {
      input: {
        type: "object",
        properties: {sessionID: {type: "string"}},
        required: ["sessionID"],
        additionalProperties: false,
      },
      output: reading,
    },
  },
  events: {
    changed: {
      schema: {
        type: "object",
        properties: {sessionID: {type: "string"}},
        required: ["sessionID"],
        additionalProperties: false,
      },
    },
  },
});
