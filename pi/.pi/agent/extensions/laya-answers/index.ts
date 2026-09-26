import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATE_TYPE: string = "laya-answers-state";

const layaAnswers = (pi: ExtensionAPI): void => {
    let enabled: boolean = true;

    const updateStatus = (ctx: ExtensionContext): void => {
        ctx.ui.setStatus("laya-answers", enabled ? "Laya answers on" : undefined);
    };

    pi.registerCommand("laya-answers", {
        description: "Toggle Laya suggestions for structured questions (on/off/status)",
        handler: async (args: string, ctx: ExtensionContext): Promise<void> => {
            const action: string = args.trim().toLowerCase();
            if (action === "status") {
                ctx.ui.notify(`Laya answers ${enabled ? "on" : "off"}.`);
                return;
            }
            if (action !== "" && action !== "on" && action !== "off") {
                ctx.ui.notify("Usage: /laya-answers [on|off|status]", "warning");
                return;
            }

            enabled = action === "" ? !enabled : action === "on";
            pi.appendEntry(STATE_TYPE, { enabled });
            updateStatus(ctx);
            ctx.ui.notify(`Laya answers ${enabled ? "on" : "off"}.`);
        },
    });

    pi.on("session_start", (_event, ctx: ExtensionContext): void => {
        const entry = ctx.sessionManager.getBranch()
            .filter((item) => item.type === "custom" && item.customType === STATE_TYPE)
            .pop();
        const hasSavedState: boolean = entry?.type === "custom" && entry.data !== null
            && typeof entry.data === "object" && "enabled" in entry.data;
        enabled = hasSavedState ? (entry?.data as { enabled: unknown }).enabled === true : true;
        updateStatus(ctx);
    });

    pi.on("before_agent_start", () => {
        if (!enabled) return;
        return {
            message: {
                customType: "laya-answers-guidance",
                display: false,
                content: `Laya answers mode is ON for this session. Before calling ask_user_question for a single-select question with 2-20 concrete options, use the laya_predict MCP tool to choose among the exact option labels. Pass the question and the full option labels, descriptions and previews as state. Ask Laya a choice question with those labels as criteria and instructions to select the best option given the user's stated goals and the current task context. If multiple independent single-select questions are ready, batch them into one laya_predict call. Only select an option without asking the user when Laya returns an unambiguous exact label, answer_confidence of at least 0.80 and a clear lead over the runner-up probability. The confidence field is not the winning option's probability. Tell the user which option Laya chose and continue with it. If the tool fails, answer_confidence is missing or below 0.80, the answer is not an exact option, the question is multi-select or free-form, or the choice depends on a personal preference not established by the user, ask the user normally. Never use Laya for permission, security approval, destructive action or dangerous-command prompts. This mode does not change Herdr or Pi permission gates.`,
            },
        };
    });
};

export default layaAnswers;
