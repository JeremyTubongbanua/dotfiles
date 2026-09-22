import {
    getAgentDir,
    type BeforeAgentStartEvent,
    type ExtensionAPI,
    type ExtensionCommandContext,
    type ExtensionContext,
    type SessionStartEvent,
    type ToolCallEvent,
} from "@earendil-works/pi-coding-agent";
import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";

const MODE_STATE_PATH: string = join(getAgentDir(), "coding-mode.json");
const STATUS_KEY: string = "coding-mode";
const PLAN_SECTION_KEY: string = "coding_mode";

const PLAN_TOOL_NAMES: ReadonlySet<string> = new Set<string>([
    "ast_grep_outline",
    "ast_grep_search",
    "effective_config",
    "fetch_content",
    "find",
    "get_search_content",
    "grep",
    "lens_diagnostic_mark",
    "lens_diagnostics",
    "ls",
    "module_report",
    "pi_lens_activate_tools",
    "project_report",
    "question",
    "questionnaire",
    "read",
    "read_enclosing",
    "read_symbol",
    "source_check",
    "symbol_search",
    "web_search",
]);

const FILE_MUTATION_TOOL_PATTERN: RegExp = /(^|[_-])(apply|copy|create|delete|edit|mkdir|move|patch|remove|rename|replace|touch|write)([_-]|$)/i;
const UNSAFE_SHELL_PATTERN: RegExp = /(?:^|\s)(?:chmod|chown|cp|install|ln|mkdir|mv|rm|rmdir|tee|touch|truncate)(?:\s|$)|(?:^|\s)git\s+(?:add|am|apply|checkout|cherry-pick|clean|clone|commit|fetch|init|merge|pull|push|rebase|reset|restore|revert|stash|switch|tag)(?:\s|$)|(?:^|\s)(?:bun|npm|pnpm|yarn)\s+(?:add|ci|install|link|publish|remove|uninstall|update|upgrade)(?:\s|$)|(?:^|\s)(?:pip|pip3)\s+(?:install|uninstall)(?:\s|$)|(?:^|\s)(?:kill|killall|pkill|reboot|shutdown|sudo)(?:\s|$)|(?:^|[^<])>{1,2}(?!>)|\bsed\s+(?:[^\n]*\s)?-i(?:\s|$)/i;

type CodingMode = "auto" | "manual" | "plan";

type ModeState = {
    mode: CodingMode;
};

const isCodingMode = (value: unknown): value is CodingMode => {
    return value === "auto" || value === "manual" || value === "plan";
};

const loadMode = async (): Promise<CodingMode> => {
    try {
        const contents: string = await readFile(MODE_STATE_PATH, "utf8");
        const state: unknown = JSON.parse(contents);
        if (
            typeof state === "object"
            && state !== null
            && "mode" in state
            && isCodingMode(state.mode)
        ) {
            return state.mode;
        }
    } catch {
        return "auto";
    }
    return "auto";
};

const saveMode = async (mode: CodingMode): Promise<void> => {
    const state: ModeState = { mode };
    const temporaryPath: string = `${MODE_STATE_PATH}.${process.pid}.${Date.now()}.tmp`;
    await mkdir(dirname(MODE_STATE_PATH), { recursive: true });
    try {
        await writeFile(temporaryPath, `${JSON.stringify(state, null, 2)}\n`, "utf8");
        await rename(temporaryPath, MODE_STATE_PATH);
    } finally {
        await rm(temporaryPath, { force: true });
    }
};

const isPlanTool = (toolName: string): boolean => {
    return PLAN_TOOL_NAMES.has(toolName) || toolName.startsWith("lsp_");
};

const isFileMutationTool = (toolName: string): boolean => {
    return FILE_MUTATION_TOOL_PATTERN.test(toolName);
};

const isPotentiallyMutatingShellCommand = (command: string): boolean => {
    return UNSAFE_SHELL_PATTERN.test(command);
};

const describeToolCall = (toolName: string, input: unknown): string => {
    if (typeof input === "object" && input !== null) {
        const values: Record<string, unknown> = input as Record<string, unknown>;
        if (typeof values.path === "string") {
            return `${toolName}: ${values.path}`;
        }
        if (typeof values.command === "string") {
            return `${toolName}: ${values.command}`;
        }
    }

    const serialized: string = JSON.stringify(input);
    const summary: string = serialized.length > 300
        ? `${serialized.slice(0, 297)}...`
        : serialized;
    return `${toolName}: ${summary}`;
};

const modesExtension = async (pi: ExtensionAPI): Promise<void> => {
    let mode: CodingMode = await loadMode();
    let toolsBeforePlan: string[] | undefined;

    const applyToolMode = (): void => {
        if (mode === "plan") {
            const availableTools: string[] = toolsBeforePlan ?? pi.getActiveTools();
            toolsBeforePlan = availableTools;
            pi.setActiveTools(availableTools.filter(isPlanTool));
            return;
        }

        if (toolsBeforePlan !== undefined) {
            pi.setActiveTools(toolsBeforePlan);
            toolsBeforePlan = undefined;
        }
    };

    const updateStatus = (ctx: ExtensionContext): void => {
        if (mode === "plan") {
            ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("warning", "PLAN"));
            return;
        }
        if (mode === "manual") {
            ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("accent", "MANUAL"));
            return;
        }
        ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("success", "AUTO"));
    };

    const setMode = async (nextMode: CodingMode, ctx: ExtensionContext): Promise<void> => {
        const changed: boolean = mode !== nextMode;
        mode = nextMode;
        applyToolMode();

        try {
            await saveMode(mode);
        } catch (error: unknown) {
            const message: string = error instanceof Error ? error.message : String(error);
            ctx.ui.notify(`Could not persist ${mode} mode: ${message}`, "error");
        }

        updateStatus(ctx);
        ctx.ui.notify(
            changed ? `${mode.toUpperCase()} mode enabled` : `${mode.toUpperCase()} mode is already active`,
            "info",
        );
    };

    pi.registerCommand("manual", {
        description: "Require approval before file-changing tool calls",
        handler: async (_args: string, ctx: ExtensionCommandContext): Promise<void> => {
            await ctx.waitForIdle();
            await setMode("manual", ctx);
        },
    });

    pi.registerCommand("auto", {
        description: "Use Pi's default automatic tool behavior",
        handler: async (_args: string, ctx: ExtensionCommandContext): Promise<void> => {
            await ctx.waitForIdle();
            await setMode("auto", ctx);
        },
    });

    pi.registerCommand("plan", {
        description: "Use read-only tools while creating a plan",
        handler: async (_args: string, ctx: ExtensionCommandContext): Promise<void> => {
            await ctx.waitForIdle();
            await setMode("plan", ctx);
        },
    });

    pi.on("session_start", async (_event: SessionStartEvent, ctx: ExtensionContext): Promise<void> => {
        applyToolMode();
        updateStatus(ctx);
    });

    pi.on("before_agent_start", async (event: BeforeAgentStartEvent): Promise<void> => {
        if (mode === "plan") {
            event.systemPromptOptions.sections[PLAN_SECTION_KEY] = `You are in PLAN mode. Work only on an implementation plan. Inspect and analyze with the available read-only tools, ask clarifying questions when needed, and produce a concrete ordered plan. Do not modify files, execute commands, or perform external side effects.`;
            return;
        }

        if (mode === "manual") {
            event.systemPromptOptions.sections[PLAN_SECTION_KEY] = `You are in MANUAL mode. You may inspect freely. File-changing tools and potentially mutating shell commands require explicit user approval before they run.`;
            return;
        }

        delete event.systemPromptOptions.sections[PLAN_SECTION_KEY];
    });

    pi.on("tool_call", async (event: ToolCallEvent, ctx: ExtensionContext) => {
        if (mode === "plan") {
            if (isPlanTool(event.toolName)) {
                return undefined;
            }
            return {
                block: true,
                reason: `PLAN mode is read-only. Tool '${event.toolName}' is unavailable. Use /manual or /auto to leave PLAN mode.`,
            };
        }

        if (mode !== "manual") {
            return undefined;
        }

        const input: unknown = event.input;
        const command: string | undefined = event.toolName === "bash"
            && typeof input === "object"
            && input !== null
            && "command" in input
            && typeof input.command === "string"
            ? input.command
            : undefined;
        const requiresApproval: boolean = isFileMutationTool(event.toolName)
            || (command !== undefined && isPotentiallyMutatingShellCommand(command));

        if (!requiresApproval) {
            return undefined;
        }

        if (!ctx.hasUI) {
            return {
                block: true,
                reason: `MANUAL mode blocked '${event.toolName}' because approval UI is unavailable.`,
            };
        }

        const approved: boolean = await ctx.ui.confirm(
            "Approve change?",
            describeToolCall(event.toolName, input),
        );
        if (!approved) {
            return {
                block: true,
                reason: `User declined '${event.toolName}' in MANUAL mode.`,
            };
        }

        return undefined;
    });
};

export default modesExtension;
