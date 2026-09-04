import { homedir } from "node:os";
import { sep } from "node:path";
import type { Usage } from "@earendil-works/pi-ai";
import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const formatCost = (value: number): string => {
	return value < 1 ? value.toFixed(4) : value.toFixed(2);
};

const shortenHome = (cwd: string): string => {
	const home: string = homedir();
	if (cwd === home) return "~";
	if (cwd.startsWith(`${home}${sep}`)) return `~${cwd.slice(home.length)}`;
	return cwd;
};

const addCost = (cost: number, usage: Usage): number => {
	return cost + usage.cost.total;
};

const getSessionCost = (ctx: ExtensionContext): number => {
	let cost: number = 0;

	for (const entry of ctx.sessionManager.getEntries()) {
		if (entry.type === "message" && entry.message.role === "assistant") {
			cost = addCost(cost, entry.message.usage);
		} else if (
			entry.type === "message" &&
			entry.message.role === "toolResult" &&
			entry.message.usage
		) {
			cost = addCost(cost, entry.message.usage);
		} else if (
			(entry.type === "branch_summary" || entry.type === "compaction") &&
			entry.usage
		) {
			cost = addCost(cost, entry.usage);
		}
	}

	return cost;
};

const statusLine = (pi: ExtensionAPI): void => {
	let requestRender: (() => void) | undefined;

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		ctx.ui.setFooter((tui, theme, footerData) => {
			requestRender = (): void => tui.requestRender();
			const unsubscribe: () => void = footerData.onBranchChange(requestRender);

			return {
				dispose: (): void => {
					unsubscribe();
					requestRender = undefined;
				},
				invalidate: (): void => {},
				render: (width: number): string[] => {
					const separator: string = theme.fg("dim", " | ");
					const firstLine: string[] = [];
					const branch: string | null = footerData.getGitBranch();

					if (branch) firstLine.push(theme.fg("success", branch));
					if (ctx.model?.provider)
						firstLine.push(theme.fg("warning", ctx.model.provider));

					const modelName: string = ctx.model?.name ?? ctx.model?.id ?? "no model";
					const thinking: string = ctx.model?.reasoning
						? ` (${ctx.thinkingLevel ?? "off"})`
						: "";
					firstLine.push(theme.fg("accent", `${modelName}${thinking}`));

					const secondLine: string[] = [];
					const contextUsage = ctx.getContextUsage();
					if (contextUsage) {
						const contextText: string =
							contextUsage.percent === null
								? "ctx:?"
								: `ctx:${Math.max(0, Math.round(100 - contextUsage.percent))}% left`;
						const contextColor: "error" | "warning" | "success" =
							(contextUsage.percent ?? 0) >= 80
								? "error"
								: (contextUsage.percent ?? 0) >= 50
									? "warning"
									: "success";
						secondLine.push(theme.fg(contextColor, contextText));
					}

					for (const status of footerData.getExtensionStatuses().values()) {
						// Extract usage percentage and reset time from @narumitw/pi-usage format
						// Input: "codex 59% 5h 61% wk" or similar
						// Output: "usage: 59% left | resets in 5h" (skip 7d/wk)
						const usageMatch = status.match(
							/(\d+)%\s+(\d+[hmd])\s+(?:\d+%\s+(?:wk|7d))?/i,
						);
						if (usageMatch) {
							const percentage = usageMatch[1];
							const resetTime = usageMatch[2];
							secondLine.push(
								theme.fg("dim", `usage: ${percentage}% left | resets in ${resetTime}`),
							);
						} else {
							secondLine.push(status);
						}
					}

					const sessionCost: number = getSessionCost(ctx);
					const thirdLine: string[] = [theme.fg("accent", shortenHome(ctx.cwd))];
					thirdLine.push(
						theme.fg("mdLink", `$${formatCost(sessionCost)} USD (session)`),
					);

					return [
						truncateToWidth(firstLine.join(separator), width, theme.fg("dim", "...")),
						truncateToWidth(
							secondLine.join(separator),
							width,
							theme.fg("dim", "..."),
						),
						truncateToWidth(thirdLine.join(separator), width, theme.fg("dim", "...")),
					];
				},
			};
		});
	});

	pi.on("message_end", () => requestRender?.());
	pi.on("model_select", () => requestRender?.());
	pi.on("thinking_level_select", () => requestRender?.());
};

export default statusLine;
