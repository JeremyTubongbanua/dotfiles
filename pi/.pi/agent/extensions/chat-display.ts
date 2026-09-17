import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
    AssistantMessageComponent,
    createBashTool,
    createEditTool,
    createFindTool,
    createGrepTool,
    createLsTool,
    createReadTool,
    createWriteTool,
} from "@earendil-works/pi-coding-agent";
import { Text, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { homedir } from "node:os";

const MAX_LABEL_LENGTH: number = 88;

const shortenPath = (path: string): string => {
    const home: string = homedir();
    const shortened: string = path.startsWith(home) ? `~${path.slice(home.length)}` : path;
    return truncateLabel(shortened || ".");
};

const truncateLabel = (value: string, maximum: number = MAX_LABEL_LENGTH): string => {
    const normalized: string = value.replace(/\s+/g, " ").trim();
    if (normalized.length <= maximum) {
        return normalized;
    }
    return `${normalized.slice(0, maximum - 3)}...`;
};

const textOutput = (result: { content: Array<{ type: string; text?: string }> }): string => {
    return result.content
        .filter((content): content is { type: "text"; text: string } => content.type === "text" && typeof content.text === "string")
        .map((content: { type: "text"; text: string }): string => content.text)
        .join("\n")
        .trim();
};

const lineCount = (output: string): number => {
    if (!output) {
        return 0;
    }
    return output.split(/\r?\n/).filter((line: string): boolean => line.trim().length > 0).length;
};

const lastLine = (output: string): string => {
    const lines: string[] = output.split(/\r?\n/).filter((line: string): boolean => line.trim().length > 0);
    return truncateLabel(lines.at(-1) ?? "Failed");
};

const expandedOutput = (output: string, theme: { fg: (color: "toolOutput", text: string) => string }): string => {
    if (!output) {
        return "";
    }
    const rendered: string = output
        .split(/\r?\n/)
        .map((line: string): string => theme.fg("toolOutput", line))
        .join("\n");
    return `\n${rendered}`;
};

const toolText = (content: string): Text => {
    const indented: string = content
        ? content.split("\n").map((line: string): string => `    ${line}`).join("\n")
        : "";
    return new Text(indented, 0, 0);
};

const createTools = (cwd: string) => ({
    bash: createBashTool(cwd),
    edit: createEditTool(cwd),
    find: createFindTool(cwd),
    grep: createGrepTool(cwd),
    ls: createLsTool(cwd),
    read: createReadTool(cwd),
    write: createWriteTool(cwd),
});

type BuiltInTools = ReturnType<typeof createTools>;
type AssistantRender = (this: AssistantMessageComponent, width: number) => string[];
type AssistantTheme = {
    bg: (color: "userMessageBg", text: string) => string;
    fg: (color: "borderAccent", text: string) => string;
};
type PatchableAssistantPrototype = {
    render: AssistantRender;
};

const toolCache: Map<string, BuiltInTools> = new Map<string, BuiltInTools>();

const toolsFor = (cwd: string): BuiltInTools => {
    const cached: BuiltInTools | undefined = toolCache.get(cwd);
    if (cached) {
        return cached;
    }
    const tools: BuiltInTools = createTools(cwd);
    toolCache.set(cwd, tools);
    return tools;
};

const chatDisplay = (pi: ExtensionAPI): void => {
    const initial: BuiltInTools = toolsFor(process.cwd());
    // SAFETY: Pi exports this component class, and its prototype owns the render method being wrapped.
    const prototype: PatchableAssistantPrototype = AssistantMessageComponent.prototype as unknown as PatchableAssistantPrototype;
    const originalRender: AssistantRender = prototype.render;
    let activeTheme: AssistantTheme | undefined;

    const renderWithBackground: AssistantRender = function (width: number): string[] {
        const safeWidth: number = Math.max(0, Math.floor(width));
        // SAFETY: Pi's AssistantMessageComponent runtime state includes the private hasToolCalls flag.
        const state: { hasToolCalls?: boolean } = this as unknown as { hasToolCalls?: boolean };
        const assistantTheme: AssistantTheme | undefined = activeTheme;
        if (!assistantTheme || state.hasToolCalls || safeWidth < 4) {
            return originalRender.call(this, safeWidth);
        }

        const innerWidth: number = safeWidth - 2;
        const lines: string[] = originalRender.call(this, innerWidth);
        if (lines.length === 0) {
            return lines;
        }

        const border = (text: string): string => assistantTheme.fg("borderAccent", text);
        const background = (text: string): string => assistantTheme.bg("userMessageBg", text);
        const wrapLine = (line: string): string => {
            const content: string = visibleWidth(line) > innerWidth
                ? truncateToWidth(line, innerWidth, "")
                : line;
            const padding: string = " ".repeat(Math.max(0, innerWidth - visibleWidth(content)));
            return background(`${border("│")}${content}${padding}${border("│")}`);
        };

        const topBorder: string = background(`${border("╭")}${border("─".repeat(innerWidth))}${border("╮")}`);
        const bottomBorder: string = background(`${border("╰")}${border("─".repeat(innerWidth))}${border("╯")}`);
        return [topBorder, ...lines.map(wrapLine), wrapLine(""), bottomBorder];
    };

    prototype.render = renderWithBackground;

    pi.on("session_start", (_event, context): void => {
        activeTheme = context.ui.theme;
        context.ui.setToolsExpanded(false);
    });

    pi.on("session_shutdown", (): void => {
        if (prototype.render === renderWithBackground) {
            prototype.render = originalRender;
        }
        activeTheme = undefined;
    });

    pi.registerTool({
        ...initial.bash,
        renderShell: "self",
        async execute(toolCallId, params, signal, onUpdate, context) {
            return toolsFor(context.cwd).bash.execute(toolCallId, params, signal, onUpdate);
        },
        renderCall(args, theme, context) {
            if (!context.isPartial) {
                return toolText("");
            }
            const command: string = truncateLabel(args.command || "...");
            return toolText(`${theme.fg("toolTitle", theme.bold("bash"))} ${theme.fg("muted", command)} ${theme.fg("warning", "…")}`);
        },
        renderResult(result, options, theme, context) {
            if (options.isPartial) {
                return toolText("");
            }
            const command: string = truncateLabel(context.args.command || "...");
            const output: string = textOutput(result);
            const count: number = lineCount(output);
            const status: string = context.isError
                ? theme.fg("error", `✗ ${lastLine(output)}`)
                : theme.fg("success", `✓${count > 0 ? ` ${count} lines` : ""}`);
            const details: string = options.expanded ? expandedOutput(output, theme) : "";
            return toolText(`${theme.fg("toolTitle", theme.bold("bash"))} ${theme.fg("muted", command)} ${status}${details}`);
        },
    });

    pi.registerTool({
        ...initial.read,
        renderShell: "self",
        async execute(toolCallId, params, signal, onUpdate, context) {
            return toolsFor(context.cwd).read.execute(toolCallId, params, signal, onUpdate);
        },
        renderCall(args, theme, context) {
            if (!context.isPartial) {
                return toolText("");
            }
            return toolText(`${theme.fg("toolTitle", theme.bold("read"))} ${theme.fg("accent", shortenPath(args.path || "..."))} ${theme.fg("warning", "…")}`);
        },
        renderResult(result, options, theme, context) {
            if (options.isPartial) {
                return toolText("");
            }
            const output: string = textOutput(result);
            const count: number = lineCount(output);
            const status: string = context.isError
                ? theme.fg("error", `✗ ${lastLine(output)}`)
                : theme.fg("success", `✓ ${count} lines`);
            const details: string = options.expanded ? expandedOutput(output, theme) : "";
            return toolText(`${theme.fg("toolTitle", theme.bold("read"))} ${theme.fg("accent", shortenPath(context.args.path || "..."))} ${status}${details}`);
        },
    });

    pi.registerTool({
        ...initial.edit,
        renderShell: "self",
        async execute(toolCallId, params, signal, onUpdate, context) {
            return toolsFor(context.cwd).edit.execute(toolCallId, params, signal, onUpdate);
        },
        renderCall(args, theme, context) {
            if (!context.isPartial) {
                return toolText("");
            }
            return toolText(`${theme.fg("toolTitle", theme.bold("edit"))} ${theme.fg("accent", shortenPath(args.path || "..."))} ${theme.fg("warning", "…")}`);
        },
        renderResult(result, options, theme, context) {
            if (options.isPartial) {
                return toolText("");
            }
            const output: string = textOutput(result);
            const diff: string = (result.details as { diff?: string } | undefined)?.diff ?? "";
            const diffLines: string[] = diff.split(/\r?\n/);
            const additions: number = diffLines.filter((line: string): boolean => line.startsWith("+") && !line.startsWith("+++")).length;
            const removals: number = diffLines.filter((line: string): boolean => line.startsWith("-") && !line.startsWith("---")).length;
            const status: string = context.isError
                ? theme.fg("error", `✗ ${lastLine(output)}`)
                : `${theme.fg("success", `✓ +${additions}`)}${theme.fg("dim", "/")}${theme.fg("error", `-${removals}`)}`;
            const detailSource: string = diff || output;
            const details: string = options.expanded ? expandedOutput(detailSource, theme) : "";
            return toolText(`${theme.fg("toolTitle", theme.bold("edit"))} ${theme.fg("accent", shortenPath(context.args.path || "..."))} ${status}${details}`);
        },
    });

    pi.registerTool({
        ...initial.write,
        renderShell: "self",
        async execute(toolCallId, params, signal, onUpdate, context) {
            return toolsFor(context.cwd).write.execute(toolCallId, params, signal, onUpdate);
        },
        renderCall(args, theme, context) {
            if (!context.isPartial) {
                return toolText("");
            }
            return toolText(`${theme.fg("toolTitle", theme.bold("write"))} ${theme.fg("accent", shortenPath(args.path || "..."))} ${theme.fg("warning", "…")}`);
        },
        renderResult(result, options, theme, context) {
            if (options.isPartial) {
                return toolText("");
            }
            const output: string = textOutput(result);
            const count: number = lineCount(context.args.content || "");
            const status: string = context.isError
                ? theme.fg("error", `✗ ${lastLine(output)}`)
                : theme.fg("success", `✓ ${count} lines`);
            const details: string = options.expanded ? expandedOutput(output, theme) : "";
            return toolText(`${theme.fg("toolTitle", theme.bold("write"))} ${theme.fg("accent", shortenPath(context.args.path || "..."))} ${status}${details}`);
        },
    });

    pi.registerTool({
        ...initial.grep,
        renderShell: "self",
        async execute(toolCallId, params, signal, onUpdate, context) {
            return toolsFor(context.cwd).grep.execute(toolCallId, params, signal, onUpdate);
        },
        renderCall(args, theme, context) {
            if (!context.isPartial) {
                return toolText("");
            }
            const target: string = `${truncateLabel(args.pattern || "...")} in ${shortenPath(args.path || ".")}`;
            return toolText(`${theme.fg("toolTitle", theme.bold("grep"))} ${theme.fg("muted", target)} ${theme.fg("warning", "…")}`);
        },
        renderResult(result, options, theme, context) {
            if (options.isPartial) {
                return toolText("");
            }
            const output: string = textOutput(result);
            const status: string = context.isError
                ? theme.fg("error", `✗ ${lastLine(output)}`)
                : theme.fg("success", `✓ ${lineCount(output)} matches`);
            const details: string = options.expanded ? expandedOutput(output, theme) : "";
            const target: string = `${truncateLabel(context.args.pattern || "...")} in ${shortenPath(context.args.path || ".")}`;
            return toolText(`${theme.fg("toolTitle", theme.bold("grep"))} ${theme.fg("muted", target)} ${status}${details}`);
        },
    });

    pi.registerTool({
        ...initial.find,
        renderShell: "self",
        async execute(toolCallId, params, signal, onUpdate, context) {
            return toolsFor(context.cwd).find.execute(toolCallId, params, signal, onUpdate);
        },
        renderCall(args, theme, context) {
            if (!context.isPartial) {
                return toolText("");
            }
            const target: string = `${truncateLabel(args.pattern || "...")} in ${shortenPath(args.path || ".")}`;
            return toolText(`${theme.fg("toolTitle", theme.bold("find"))} ${theme.fg("muted", target)} ${theme.fg("warning", "…")}`);
        },
        renderResult(result, options, theme, context) {
            if (options.isPartial) {
                return toolText("");
            }
            const output: string = textOutput(result);
            const status: string = context.isError
                ? theme.fg("error", `✗ ${lastLine(output)}`)
                : theme.fg("success", `✓ ${lineCount(output)} files`);
            const details: string = options.expanded ? expandedOutput(output, theme) : "";
            const target: string = `${truncateLabel(context.args.pattern || "...")} in ${shortenPath(context.args.path || ".")}`;
            return toolText(`${theme.fg("toolTitle", theme.bold("find"))} ${theme.fg("muted", target)} ${status}${details}`);
        },
    });

    pi.registerTool({
        ...initial.ls,
        renderShell: "self",
        async execute(toolCallId, params, signal, onUpdate, context) {
            return toolsFor(context.cwd).ls.execute(toolCallId, params, signal, onUpdate);
        },
        renderCall(args, theme, context) {
            if (!context.isPartial) {
                return toolText("");
            }
            return toolText(`${theme.fg("toolTitle", theme.bold("ls"))} ${theme.fg("accent", shortenPath(args.path || "."))} ${theme.fg("warning", "…")}`);
        },
        renderResult(result, options, theme, context) {
            if (options.isPartial) {
                return toolText("");
            }
            const output: string = textOutput(result);
            const status: string = context.isError
                ? theme.fg("error", `✗ ${lastLine(output)}`)
                : theme.fg("success", `✓ ${lineCount(output)} entries`);
            const details: string = options.expanded ? expandedOutput(output, theme) : "";
            return toolText(`${theme.fg("toolTitle", theme.bold("ls"))} ${theme.fg("accent", shortenPath(context.args.path || "."))} ${status}${details}`);
        },
    });
};

export default chatDisplay;
