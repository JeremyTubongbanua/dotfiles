// Reports pi agent state (working, blocked, idle) to herdr.
// Based on the herdr pi integration (HERDR_INTEGRATION_VERSION=9), plus a bridge for ask_user_question.

import net from "node:net";
import path from "node:path";
import type {
    AgentSettledEvent,
    AgentStartEvent,
    ExtensionAPI,
    ExtensionContext,
    SessionStartEvent,
} from "@earendil-works/pi-coding-agent";

type AgentState = "working" | "blocked" | "idle";

type QueuedState = {
    state: AgentState;
    message?: string;
    seq: number;
};

type DesiredState = {
    state: AgentState;
    message?: string;
};

type BlockedEvent = {
    active?: unknown;
    label?: unknown;
};

const HERDR_ENV: string | undefined = process.env.HERDR_ENV;
const SOCKET_PATH: string | undefined = process.env.HERDR_SOCKET_PATH;
const SOCKET_ENDPOINT: string | undefined =
    process.platform === "win32" && SOCKET_PATH ? `\\\\.\\pipe\\${SOCKET_PATH}` : SOCKET_PATH;
const PANE_ID: string | undefined = process.env.HERDR_PANE_ID;
const SOURCE: string = "herdr:pi";

const HERDR_BLOCKED_EVENT: string = "herdr:blocked";
const ASK_USER_BLOCKED_EVENT: string = "rpiv:ask-user:blocked";
const ASK_USER_BLOCKED_LABEL: string = "Waiting for an answer to a question";

let reportSeq: number = Date.now() * 1000;
let currentAgentSessionId: string | undefined;
let currentAgentSessionPath: string | undefined;
let sendInFlight: boolean = false;
let queuedState: QueuedState | undefined;

const enabled = (): boolean => {
    return HERDR_ENV === "1" && !!SOCKET_PATH && !!PANE_ID;
};

const requestId = (kind?: string): string => {
    const prefix: string = kind ? `${SOURCE}:${kind}` : SOURCE;
    return `${prefix}:${Date.now()}:${Math.random().toString(36).slice(2)}`;
};

const sendRequestAttempt = (request: unknown, timeoutMs: number): Promise<boolean> => {
    if (!enabled()) {
        return Promise.resolve(true);
    }

    return new Promise((resolve: (delivered: boolean) => void): void => {
        let done: boolean = false;
        let timeout: ReturnType<typeof setTimeout> | undefined;
        const socket: net.Socket = net.createConnection(SOCKET_ENDPOINT!);

        const finish = (delivered: boolean): void => {
            if (done) return;
            done = true;
            if (timeout) {
                clearTimeout(timeout);
            }
            socket.destroy();
            resolve(delivered);
        };

        socket.on("error", (): void => finish(false));
        socket.on("connect", (): void => {
            socket.write(`${JSON.stringify(request)}\n`);
        });
        socket.on("data", (): void => finish(true));
        socket.on("end", (): void => finish(false));
        timeout = setTimeout((): void => finish(false), timeoutMs);
        timeout.unref?.();
    });
};

const sendRequest = async (request: unknown): Promise<void> => {
    if (await sendRequestAttempt(request, 500)) {
        return;
    }
    await sendRequestAttempt(request, 1500);
};

const nextReportSeq = (): number => {
    reportSeq += 1;
    return reportSeq;
};

const updateSessionRef = (ctx: ExtensionContext): void => {
    try {
        const file: string | undefined = ctx.sessionManager.getSessionFile();
        currentAgentSessionPath =
            typeof file === "string" && (path.posix.isAbsolute(file) || path.win32.isAbsolute(file))
                ? file
                : undefined;
    } catch {
        currentAgentSessionPath = undefined;
    }

    try {
        const id: string = ctx.sessionManager.getSessionId();
        currentAgentSessionId = typeof id === "string" && id.length > 0 ? id : undefined;
    } catch {
        currentAgentSessionId = undefined;
    }
};

const currentSessionRef = (): Record<string, unknown> | undefined => {
    if (currentAgentSessionPath) {
        return { agent_session_path: currentAgentSessionPath };
    }
    if (currentAgentSessionId) {
        return { agent_session_id: currentAgentSessionId };
    }
    return undefined;
};

const reportSession = (sessionStartSource?: string): Promise<void> => {
    const sessionRef: Record<string, unknown> | undefined = currentSessionRef();
    if (!sessionRef) {
        return Promise.resolve();
    }

    return sendRequest({
        id: requestId("session"),
        method: "pane.report_agent_session",
        params: {
            pane_id: PANE_ID,
            source: SOURCE,
            agent: "pi",
            seq: nextReportSeq(),
            session_start_source: sessionStartSource,
            ...sessionRef,
        },
    });
};

const sendState = (state: AgentState, message: string | undefined, seq: number): Promise<void> => {
    return sendRequest({
        id: requestId(),
        method: "pane.report_agent",
        params: {
            pane_id: PANE_ID,
            source: SOURCE,
            agent: "pi",
            state,
            message,
            seq,
            ...currentSessionRef(),
        },
    });
};

const drainStateQueue = async (): Promise<void> => {
    if (sendInFlight) {
        return;
    }

    sendInFlight = true;
    try {
        while (queuedState) {
            const next: QueuedState = queuedState;
            queuedState = undefined;
            await sendState(next.state, next.message, next.seq);
        }
    } finally {
        sendInFlight = false;
        if (queuedState) {
            void drainStateQueue();
        }
    }
};

const queueState = (state: AgentState, message?: string): void => {
    queuedState = { state, message, seq: nextReportSeq() };
    if (!sendInFlight) {
        void drainStateQueue();
    }
};

const jeremyHerdrState = (pi: ExtensionAPI): void => {
    if (!enabled()) {
        return;
    }

    let agentActive: boolean = false;
    let blockedCount: number = 0;
    let blockedMessage: string | undefined;
    let lastState: AgentState | undefined;
    let lastMessage: string | undefined;
    let rootSession: boolean = false;

    const desiredState = (): DesiredState => {
        if (blockedCount > 0) {
            return { state: "blocked", message: blockedMessage };
        }
        if (agentActive) {
            return { state: "working", message: undefined };
        }
        return { state: "idle", message: undefined };
    };

    const publishState = (force: boolean = false): void => {
        const next: DesiredState = desiredState();
        if (!force && next.state === lastState && next.message === lastMessage) {
            return;
        }
        lastState = next.state;
        lastMessage = next.message;
        queueState(next.state, next.message);
    };

    const setBlocked = (active: boolean, label?: string): void => {
        if (!rootSession) {
            return;
        }
        if (!active) {
            blockedCount = Math.max(0, blockedCount - 1);
            if (blockedCount === 0) {
                blockedMessage = undefined;
            }
            publishState();
            return;
        }

        blockedCount += 1;
        blockedMessage = label;
        publishState();
    };

    // Other extensions (for example permission-gate) emit this while waiting on the user.
    pi.events.on(HERDR_BLOCKED_EVENT, (data: unknown): void => {
        const event: BlockedEvent | undefined = data as BlockedEvent | undefined;
        const label: string | undefined = typeof event?.label === "string" ? event.label : undefined;
        setBlocked(!!event?.active, label);
    });

    pi.events.on(ASK_USER_BLOCKED_EVENT, (data: unknown): void => {
        const active: boolean = (data as BlockedEvent | undefined)?.active === true;
        setBlocked(active, active ? ASK_USER_BLOCKED_LABEL : undefined);
    });

    pi.on("session_start", async (event: SessionStartEvent, ctx: ExtensionContext): Promise<void> => {
        // TUI only: RPC/JSON/print modes are headless (no PTY herdr can display),
        // and RPC still reports hasUI=true, so mode is the reliable gate.
        if (ctx.mode !== "tui") {
            return;
        }
        rootSession = true;
        updateSessionRef(ctx);
        await reportSession(event.reason);
        // A reload can replace this extension mid-run without emitting another agent_start.
        agentActive = ctx.isIdle() === false;
        publishState(true);
    });

    pi.on("agent_start", (_event: AgentStartEvent, ctx: ExtensionContext): void => {
        if (!rootSession) {
            return;
        }
        updateSessionRef(ctx);
        void reportSession();
        agentActive = true;
        publishState();
    });

    pi.on("agent_settled", (_event: AgentSettledEvent, ctx: ExtensionContext): void => {
        if (!rootSession || ctx.isIdle() !== true) {
            return;
        }

        agentActive = false;
        publishState();
    });
};

export default jeremyHerdrState;
