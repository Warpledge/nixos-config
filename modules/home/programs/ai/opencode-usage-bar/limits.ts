//=====================================================================#
// OPENCODE USAGE BAR - GO PLAN LIMITS
//=====================================================================#
// Monthly dollar limit per model, from the plan columns of
// https://opencode.ai/console/go#usage-limits, read 2026-11-01.
// The Console counts a model's list cost against its own limit, and the
// 5-hour window is 20% of it while the week is 50%.
export type Plan = "go" | "go-plus" | "go-teams";

export const PLANS: readonly Plan[] = ["go", "go-plus", "go-teams"];

type Limits = Readonly<Record<string, number>>;

const FREE: Limits = {
  "beam-free": Infinity,
  "iceman-contributor-free": Infinity,
};

const go: Limits = {
  ...FREE,
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
};

const plus: Limits = {
  ...FREE,
  "glm-5.3-flash": 180,
  "glm-5.3": 120,
  "glm-5.2": 180,
  "kimi-k3.1-pro": 60,
  "kimi-k3": 60,
  "kimi-k2.7-code": 180,
  "longcat-2.0": 240,
  "step-5-preview": 60,
  "mimo-v2.6-flash": 120,
  "mimo-v2.6-pro": 60,
  "mimo-v2.5": 120,
  "mimo-v2.5-pro": 60,
  "minimax-m3.1-flash": 80,
  "minimax-m3": 180,
  "muse-spark-1.3-contributor": 120,
  "muse-spark-1.2-contributor": 120,
  "qwen3.8-max": 60,
  "qwen3.8-flash": 90,
  "qwen3.7-plus": 180,
  "deepseek-v4.1-flash": 200,
  "deepseek-v4-pro": 60,
  "hy4-preview": 120,
  "hy3": 240,
  "grok-4.7": 60,
  "gpt-6-luna": 60,
  "gpt-5.6-luna": 60,
  "claude-haiku-5-5": 60,
  "gemini-4-argon": 120,
};

const teams: Limits = {
  ...FREE,
  "glm-5.3-flash": 65,
  "glm-5.3": 20,
  "glm-5.2": 65,
  "kimi-k3.1-pro": 20,
  "kimi-k3": 20,
  "kimi-k2.7-code": 65,
  "longcat-2.0": 65,
  "step-5-preview": 20,
  "mimo-v2.6-flash": 65,
  "mimo-v2.6-pro": 20,
  "mimo-v2.5": 65,
  "mimo-v2.5-pro": 20,
  "minimax-m3.1-flash": 25,
  "minimax-m3": 65,
  "muse-spark-1.3-contributor": 65,
  "muse-spark-1.2-contributor": 65,
  "qwen3.8-max": 20,
  "qwen3.8-flash": 35,
  "qwen3.7-plus": 65,
  "deepseek-v4.1-flash": 105,
  "deepseek-v4-pro": 20,
  "hy4-preview": 35,
  "hy3": 65,
  "grok-4.7": 20,
  "gpt-6-luna": 20,
  "gpt-5.6-luna": 20,
  "claude-haiku-5-5": 20,
  "gemini-4-argon": 35,
};

export const LIMITS: Readonly<Record<Plan, Limits>> = {go, "go-plus": plus, "go-teams": teams};

// The plan's own monthly cap, used for a model the table does not list yet
export const PLAN_CAP: Readonly<Record<Plan, number>> = {go: 60, "go-plus": 240, "go-teams": 60};
