import {
    generateUnifiedPatch,
    getAgentDir,
    type BeforeAgentStartEvent,
    type ExtensionAPI,
    type ExtensionCommandContext,
    type ExtensionContext,
    type ExecResult,
    type SessionStartEvent,
    type Theme,
    type ToolCallEvent,
} from "@earendil-works/pi-coding-agent";
import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { Key, matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { dirname, join, resolve } from "node:path";

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

type ModeOption = {
    mode: CodingMode;
    label: string;
    description: string;
};

const MODE_OPTIONS: readonly ModeOption[] = [
    { mode: "auto", label: "Auto", description: "Pi's default automatic tool behavior" },
    { mode: "manual", label: "Manual", description: "Approve file changes before they run" },
    { mode: "plan", label: "Plan", description: "Read-only analysis and planning" },
];

type ModeState = {
    mode: CodingMode;
};

type EditReplacement = {
    oldText: string;
    newText: string;
};

type EditInput = {
    path: string;
    edits: EditReplacement[];
};

type WriteInput = {
    path: string;
    content: string;
};

type ApprovalAction = "approve" | "deny" | "feedback";

type ApprovalDecision = {
    approved: boolean;
    feedback?: string;
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

const isEditInput = (input: unknown): input is EditInput => {
    if (typeof input !== "object" || input === null || !("path" in input) || !("edits" in input)) {
        return false;
    }
    if (typeof input.path !== "string" || !Array.isArray(input.edits)) {
        return false;
    }
    return input.edits.every((edit: unknown): edit is EditReplacement => {
        return typeof edit === "object"
            && edit !== null
            && "oldText" in edit
            && "newText" in edit
            && typeof edit.oldText === "string"
            && typeof edit.newText === "string";
    });
};

const isWriteInput = (input: unknown): input is WriteInput => {
    return typeof input === "object"
        && input !== null
        && "path" in input
        && "content" in input
        && typeof input.path === "string"
        && typeof input.content === "string";
};

const resolveToolPath = (cwd: string, path: string): string => {
    const normalizedPath: string = path.startsWith("@") ? path.slice(1) : path;
    return resolve(cwd, normalizedPath);
};

const applyPreviewEdits = (content: string, edits: EditReplacement[]): string => {
    const replacements: Array<{ index: number; oldText: string; newText: string }> = edits.map(
        (edit: EditReplacement): { index: number; oldText: string; newText: string } => {
            const index: number = content.indexOf(edit.oldText);
            if (index < 0 || content.indexOf(edit.oldText, index + edit.oldText.length) >= 0) {
                throw new Error("An edit target is missing or not unique");
            }
            return { index, oldText: edit.oldText, newText: edit.newText };
        },
    );

    const ordered = replacements.sort((left, right): number => right.index - left.index);
    let preview: string = content;
    let previousStart: number = content.length;
    for (const replacement of ordered) {
        const replacementEnd: number = replacement.index + replacement.oldText.length;
        if (replacementEnd > previousStart) {
            throw new Error("Edit targets overlap");
        }
        preview = `${preview.slice(0, replacement.index)}${replacement.newText}${preview.slice(replacementEnd)}`;
        previousStart = replacement.index;
    }
    return preview;
};

const truncateDiff = (diff: string): string => {
    const maximumLines: number = 200;
    const maximumCharacters: number = 20_000;
    const body: string = diff.replace(/^--- [^\n]*\n\+\+\+ [^\n]*\n/, "");
    const lines: string[] = body.split("\n");
    let preview: string = lines.slice(0, maximumLines).join("\n");
    if (preview.length > maximumCharacters) {
        preview = preview.slice(0, maximumCharacters);
    }
    if (lines.length > maximumLines || body.length > maximumCharacters) {
        preview += "\n... diff truncated for approval ...";
    }
    return preview;
};

const buildApprovalMessage = async (
    toolName: string,
    input: unknown,
    cwd: string,
): Promise<string> => {
    try {
        if (toolName === "edit" && isEditInput(input)) {
            const original: string = await readFile(resolveToolPath(cwd, input.path), "utf8");
            const updated: string = applyPreviewEdits(original, input.edits);
            const diff: string = generateUnifiedPatch(input.path, original, updated);
            return `${input.path}\n\n${truncateDiff(diff)}`;
        }

        if (toolName === "write" && isWriteInput(input)) {
            let original: string = "";
            try {
                original = await readFile(resolveToolPath(cwd, input.path), "utf8");
            } catch (error: unknown) {
                const code: unknown = typeof error === "object" && error !== null && "code" in error
                    ? error.code
                    : undefined;
                if (code !== "ENOENT") {
                    throw error;
                }
            }
            const diff: string = generateUnifiedPatch(input.path, original, input.content);
            return `${input.path}\n\n${truncateDiff(diff)}`;
        }
    } catch (error: unknown) {
        const message: string = error instanceof Error ? error.message : String(error);
        return `${describeToolCall(toolName, input)}\n\nDiff preview unavailable: ${message}`;
    }

    return describeToolCall(toolName, input);
};

const renderApprovalPanel = (theme: Theme, width: number, content: string[]): string[] => {
    if (width <= 0) {
        return [];
    }
    const framed: boolean = width >= 5;
    const contentWidth: number = framed ? width - 4 : width;
    const side: string = framed ? theme.fg("borderAccent", "│") : "";
    const inset: string = framed ? " " : "";
    const renderRow = (line: string): string => {
        const clipped: string = truncateToWidth(line, contentWidth);
        const padding: string = " ".repeat(Math.max(0, contentWidth - visibleWidth(clipped)));
        return side
            + theme.bg("toolPendingBg", `${inset}${clipped}`)
            + theme.bg("toolPendingBg", `${padding}${inset}`)
            + side;
    };
    const rows: string[] = [renderRow(""), ...content.map(renderRow), renderRow("")];
    if (framed) {
        const edge: string = "─".repeat(width - 2);
        rows.unshift(theme.fg("borderAccent", `╭${edge}╮`));
        rows.push(theme.fg("borderAccent", `╰${edge}╯`));
    }
    return [...rows, "", ""];
};

const waitForApprovalFocus = (ctx: ExtensionContext, message: string): Promise<boolean> => {
    const signal: AbortSignal | undefined = ctx.signal;
    if (signal?.aborted) {
        return Promise.resolve(false);
    }
    if (ctx.ui.getEditorText().trim().length === 0) {
        return Promise.resolve(true);
    }

    return new Promise<boolean>((resolve, reject): void => {
        let unsubscribe: (() => void) | undefined;
        let finished: boolean = false;
        const cleanup = (): void => {
            unsubscribe?.();
            signal?.removeEventListener("abort", onAbort);
            ctx.ui.setWidget("manual-approval", undefined);
        };
        const finish = (review: boolean): void => {
            if (finished) {
                return;
            }
            finished = true;
            cleanup();
            resolve(review);
        };
        const onAbort = (): void => finish(false);

        try {
            unsubscribe = ctx.ui.onTerminalInput((data: string) => {
                if (matchesKey(data, Key.alt("r"))) {
                    finish(true);
                    return { consume: true };
                }
                return undefined;
            });
            signal?.addEventListener("abort", onAbort, { once: true });
            ctx.ui.setWidget("manual-approval", (_tui, theme) => ({
                render: (width: number): string[] => renderApprovalPanel(theme, width, [
                    theme.fg("warning", theme.bold("Approval waiting: Alt+R to review")),
                    theme.fg("toolOutput", message.split("\n", 1)[0] ?? ""),
                    theme.fg("dim", "Keep typing below. Approval keys are inactive until you open review."),
                ]),
                invalidate: (): void => {},
            }));
            if (signal?.aborted) {
                finish(false);
            }
        } catch (error: unknown) {
            cleanup();
            reject(error);
        }
    });
};

const requestApproval = async (ctx: ExtensionContext, message: string): Promise<ApprovalDecision> => {
    if (ctx.mode !== "tui") {
        const approved: boolean = await ctx.ui.confirm("Approve change?", message);
        return { approved };
    }

    const reviewRequested: boolean = await waitForApprovalFocus(ctx, message);
    const signal: AbortSignal | undefined = ctx.signal;
    if (!reviewRequested || signal?.aborted) {
        return { approved: false };
    }

    const action: ApprovalAction = await ctx.ui.custom<ApprovalAction>((tui, theme, _keybindings, done) => {
        const lines: string[] = message.split("\n");
        let pageSize: number = 20;
        let offset: number = 0;
        const onAbort = (): void => done("deny");
        signal?.addEventListener("abort", onAbort, { once: true });
        if (signal?.aborted) {
            signal.removeEventListener("abort", onAbort);
            done("deny");
        }

        const renderLine = (line: string): string => {
            if (line.startsWith("+")) {
                return theme.bg("toolSuccessBg", theme.fg("success", line));
            }
            if (line.startsWith("-")) {
                return theme.bg("toolErrorBg", theme.fg("error", line));
            }
            if (line.startsWith("@@")) {
                return theme.fg("accent", theme.bold(line));
            }
            return theme.fg("toolOutput", line);
        };

        return {
            render: (width: number): string[] => {
                pageSize = Math.max(1, Math.min(20, tui.terminal.rows - 16));
                offset = Math.min(offset, Math.max(0, lines.length - pageSize));
                const lastVisibleLine: number = Math.min(lines.length, offset + pageSize);
                const visibleLines: string[] = lines.slice(offset, lastVisibleLine).map(renderLine);
                const position: string = lines.length > pageSize
                    ? ` ${offset + 1}-${lastVisibleLine}/${lines.length}`
                    : "";
                return renderApprovalPanel(theme, width, [
                    theme.fg("warning", theme.bold("Approve change?")),
                    "",
                    ...visibleLines,
                    "",
                    theme.fg("dim", "Y/Enter approve • N/Esc deny • Tab feedback"),
                    theme.fg("dim", `↑↓ scroll • Page Up/Down${position}`),
                ]);
            },
            invalidate: (): void => {},
            dispose: (): void => signal?.removeEventListener("abort", onAbort),
            handleInput: (data: string): void => {
                if (matchesKey(data, Key.up)) {
                    offset = Math.max(0, offset - 1);
                } else if (matchesKey(data, Key.down)) {
                    offset = Math.min(Math.max(0, lines.length - pageSize), offset + 1);
                } else if (matchesKey(data, Key.pageUp)) {
                    offset = Math.max(0, offset - pageSize);
                } else if (matchesKey(data, Key.pageDown)) {
                    offset = Math.min(Math.max(0, lines.length - pageSize), offset + pageSize);
                } else if (data.toLowerCase() === "y" || matchesKey(data, Key.enter)) {
                    done("approve");
                    return;
                } else if (data.toLowerCase() === "n" || matchesKey(data, Key.escape)) {
                    done("deny");
                    return;
                } else if (matchesKey(data, Key.tab)) {
                    done("feedback");
                    return;
                }
                tui.requestRender();
            },
        };
    });

    if (action === "approve") {
        return { approved: true };
    }
    if (action === "deny") {
        return { approved: false };
    }

    const feedback: string | undefined = await ctx.ui.editor(
        "Deny with feedback: what should the agent do next?",
        "",
    );
    const normalizedFeedback: string | undefined = feedback?.trim() || undefined;
    return { approved: false, feedback: normalizedFeedback };
};

const requestModeSelection = async (
    ctx: ExtensionContext,
    currentMode: CodingMode,
): Promise<CodingMode | undefined> => {
    if (ctx.mode !== "tui") {
        const labels: string[] = MODE_OPTIONS.map((option: ModeOption): string => option.label);
        const selectedLabel: string | undefined = await ctx.ui.select("Select coding mode", labels);
        return MODE_OPTIONS.find((option: ModeOption): boolean => option.label === selectedLabel)?.mode;
    }

    return ctx.ui.custom<CodingMode | undefined>((tui, theme, _keybindings, done) => {
        let selectedIndex: number = Math.max(
            0,
            MODE_OPTIONS.findIndex((option: ModeOption): boolean => option.mode === currentMode),
        );

        const moveSelection = (offset: number): void => {
            selectedIndex = (selectedIndex + offset + MODE_OPTIONS.length) % MODE_OPTIONS.length;
        };

        return {
            render: (width: number): string[] => {
                const safeWidth: number = Math.max(1, width);
                const optionLines: string[] = MODE_OPTIONS.map((option: ModeOption, index: number): string => {
                    const current: string = option.mode === currentMode ? " (current)" : "";
                    const prefix: string = index === selectedIndex ? "› " : "  ";
                    const label: string = `${prefix}${option.label}${current}`;
                    const line: string = `${label.padEnd(20)}${option.description}`;
                    if (index === selectedIndex) {
                        return theme.bg("selectedBg", theme.fg("accent", theme.bold(line)));
                    }
                    return theme.fg("text", line);
                });
                return [
                    truncateToWidth(theme.fg("accent", theme.bold("Select coding mode")), safeWidth),
                    ...optionLines.map((line: string): string => truncateToWidth(line, safeWidth)),
                    truncateToWidth(
                        theme.fg("dim", "j/k or ↑/↓ navigate • tab next • enter select • esc cancel"),
                        safeWidth,
                    ),
                ];
            },
            invalidate: (): void => {},
            handleInput: (data: string): void => {
                if (data.toLowerCase() === "j" || matchesKey(data, Key.down) || matchesKey(data, Key.tab)) {
                    moveSelection(1);
                } else if (data.toLowerCase() === "k" || matchesKey(data, Key.up) || matchesKey(data, Key.shift("tab"))) {
                    moveSelection(-1);
                } else if (matchesKey(data, Key.enter)) {
                    done(MODE_OPTIONS[selectedIndex]?.mode);
                    return;
                } else if (matchesKey(data, Key.escape)) {
                    done(undefined);
                    return;
                }
                tui.requestRender();
            },
        };
    });
};

const modesExtension = async (pi: ExtensionAPI): Promise<void> => {
    let mode: CodingMode = await loadMode();
    let toolsBeforePlan: string[] | undefined;
    let herdrSequence: number = Date.now() * 1000;
    let herdrApprovalPending: boolean = false;

    const reportHerdrApprovalState = async (
        ctx: ExtensionContext,
        active: boolean,
        label?: string,
    ): Promise<void> => {
        const paneId: string | undefined = process.env.HERDR_PANE_ID;
        if (ctx.mode !== "tui" || process.env.HERDR_ENV !== "1" || !paneId) {
            return;
        }
        if (active) {
            herdrApprovalPending = true;
        } else if (!herdrApprovalPending) {
            return;
        }

        const herdrBinary: string = process.env.HERDR_BIN_PATH || "herdr";
        herdrSequence = Math.max(herdrSequence + 1, Date.now() * 1000);
        const args: string[] = [
            "pane",
            active ? "report-agent" : "release-agent",
            paneId,
            "--source",
            "herdr:pi-modes",
            "--agent",
            "pi",
            "--seq",
            String(herdrSequence),
        ];
        if (active) {
            args.push("--state", "blocked", "--message", label || "Approval required");
        }

        try {
            const result: ExecResult = await pi.exec(herdrBinary, args, { timeout: 2000 });
            if (result.code !== 0 || result.killed) {
                throw new Error(result.stderr.trim() || `Herdr exited with code ${result.code}`);
            }
            if (!active) {
                herdrApprovalPending = false;
            }
        } catch (error: unknown) {
            const message: string = error instanceof Error ? error.message : String(error);
            ctx.ui.notify(`Could not ${active ? "report" : "clear"} Herdr approval state: ${message}`, "warning");
        }
    };

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

    pi.registerCommand("mode", {
        description: "Select Auto, Manual, or Plan mode",
        handler: async (_args: string, ctx: ExtensionCommandContext): Promise<void> => {
            await ctx.waitForIdle();
            if (!ctx.hasUI) {
                ctx.ui.notify("/mode requires an interactive UI", "warning");
                return;
            }
            const selectedMode: CodingMode | undefined = await requestModeSelection(ctx, mode);
            if (selectedMode !== undefined) {
                await setMode(selectedMode, ctx);
            }
        },
    });

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

    pi.on("session_shutdown", async (_event, ctx: ExtensionContext): Promise<void> => {
        await reportHerdrApprovalState(ctx, false);
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

        const approvalMessage: string = await buildApprovalMessage(event.toolName, input, ctx.cwd);
        const blockedLabel: string = `Approval required for ${describeToolCall(event.toolName, input)}`;
        let decision: ApprovalDecision = { approved: false };
        pi.events.emit("herdr:blocked", { active: true, label: blockedLabel });
        try {
            await reportHerdrApprovalState(ctx, true, blockedLabel);
            decision = await requestApproval(ctx, approvalMessage);
        } finally {
            pi.events.emit("herdr:blocked", { active: false });
            await reportHerdrApprovalState(ctx, false);
        }
        if (!decision.approved) {
            const feedback: string = decision.feedback
                ? `\n\nUser feedback:\n${decision.feedback}`
                : "";
            return {
                block: true,
                reason: `User declined '${event.toolName}' in MANUAL mode.${feedback}`,
            };
        }

        return undefined;
    });
};

export default modesExtension;
