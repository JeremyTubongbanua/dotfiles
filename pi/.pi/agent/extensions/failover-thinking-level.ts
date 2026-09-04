import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

type ThinkingLevel = "high" | "xhigh";

const modelThinkingLevels: Readonly<Record<string, ThinkingLevel>> = {
  "anthropic/claude-opus-4-6": "high",
  "openai-codex-account-2/gpt-5.6-sol": "xhigh",
  "openai-codex/gpt-5.6-sol": "xhigh",
};

const failoverThinkingLevel = (pi: ExtensionAPI): void => {
  const applyThinkingLevel = (ctx: ExtensionContext): void => {
    const provider: string | undefined = ctx.model?.provider;
    const modelId: string | undefined = ctx.model?.id;
    if (!provider || !modelId) return;

    const level: ThinkingLevel | undefined =
      modelThinkingLevels[`${provider}/${modelId}`];
    if (!level || pi.getThinkingLevel() === level) return;

    pi.setThinkingLevel(level);
  };

  pi.on("session_start", (_event, ctx) => applyThinkingLevel(ctx));
  pi.on("model_select", (_event, ctx) => applyThinkingLevel(ctx));
  pi.on("turn_start", (_event, ctx) => applyThinkingLevel(ctx));
};

export default failoverThinkingLevel;
