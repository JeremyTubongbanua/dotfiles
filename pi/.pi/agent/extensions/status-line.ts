import { homedir } from "node:os";
import { sep } from "node:path";
import type { Usage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

type UsageTotals = {
	input: number;
	output: number;
	cost: number;
};

const formatTokens = (value: number): string => {
	if (value < 1_000) return `${value}`;
	if (value < 10_000) return `${(value / 1_000).toFixed(1)}k`;
	if (value < 1_000_000) return `${Math.round(value / 1_000)}k`;
	return `${(value / 1_000_000).toFixed(1)}m`;
};

const formatCost = (value: number): string => {
	return value < 1 ? value.toFixed(4) : value.toFixed(2);
};

const shortenHome = (cwd: string): string => {
	const home: string = homedir();
	if (cwd === home) return "~";
	if (cwd.startsWith(`${home}${sep}`)) return `~${cwd.slice(home.length)}`;
	return cwd;
};

const addUsage = (totals: UsageTotals, usage: Usage): void => {
	totals.input += usage.input;
	totals.output += usage.output;
	totals.cost += usage.cost.total;
};

const getUsageTotals = (ctx: ExtensionContext): UsageTotals => {
	const totals: UsageTotals = { input: 0, output: 0, cost: 0 };

	for (const entry of ctx.sessionManager.getEntries()) {
		if (entry.type === "message" && entry.message.role === "assistant") {
			addUsage(totals, entry.message.usage);
		} else if (entry.type === "message" && entry.message.role === "toolResult" && entry.message.usage) {
			addUsage(totals, entry.message.usage);
		} else if ((entry.type === "branch_summary" || entry.type === "compaction") && entry.usage) {
			addUsage(totals, entry.usage);
		}
	}

	return totals;
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
					if (ctx.model?.provider) firstLine.push(theme.fg("warning", ctx.model.provider));

					const modelName: string = ctx.model?.name ?? ctx.model?.id ?? "no model";
					const thinking: string = ctx.model?.reasoning ? ` (${ctx.thinkingLevel ?? "off"})` : "";
					firstLine.push(theme.fg("accent", `${modelName}${thinking}`));

					const contextUsage = ctx.getContextUsage();
					if (contextUsage) {
						const contextText: string = contextUsage.percent === null
							? "ctx:?"
							: `ctx:${Math.max(0, Math.round(100 - contextUsage.percent))}% left`;
						const contextColor: "error" | "warning" | "success" =
							(contextUsage.percent ?? 0) >= 80
								? "error"
								: (contextUsage.percent ?? 0) >= 50
									? "warning"
									: "success";
						firstLine.push(theme.fg(contextColor, contextText));
					}

					const totals: UsageTotals = getUsageTotals(ctx);
					const secondLine: string[] = [theme.fg("accent", shortenHome(ctx.cwd))];
					secondLine.push(theme.fg("dim", `↑${formatTokens(totals.input)} ↓${formatTokens(totals.output)}`));
					secondLine.push(theme.fg("mdLink", `$${formatCost(totals.cost)} USD (session)`));

					return [
						truncateToWidth(firstLine.join(separator), width, theme.fg("dim", "...")),
						truncateToWidth(secondLine.join(separator), width, theme.fg("dim", "...")),
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
