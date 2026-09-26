import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const ASK_USER_BLOCKED_EVENT: string = "rpiv:ask-user:blocked";

const herdrQuestionState = (pi: ExtensionAPI): void => {
    pi.events.on(ASK_USER_BLOCKED_EVENT, (data: unknown): void => {
        const active: boolean = (data as { active?: unknown } | undefined)?.active === true;
        pi.events.emit("herdr:blocked", {
            active,
            label: active ? "Waiting for an answer to a question" : undefined,
        });
    });
};

export default herdrQuestionState;
