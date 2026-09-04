import { readFileSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join, sep } from "node:path";
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

const getTodayDateString = (): string => {
	const now: Date = new Date();
	const y: string = String(now.getFullYear());
	const m: string = String(now.getMonth() + 1).padStart(2, "0");
	const d: string = String(now.getDate()).padStart(2, "0");
	return `${y}-${m}-${d}`;
};

const extractCostFromLine = (line: string): number => {
	if (!line.includes('"cost"')) return 0;
	try {
		const obj: Record<string, unknown> = JSON.parse(line);
		const msg = (obj.message ?? {}) as Record<string, unknown>;
		const usage = (msg.usage ?? obj.usage ?? {}) as Record<string, unknown>;
		const cost = (usage.cost ?? {}) as Record<string, unknown>;
		return typeof cost.total === "number" ? cost.total : 0;
	} catch {
		return 0;
	}
};

const sumCostsInFile = (filePath: string): number => {
	try {
		const content: string = readFileSync(filePath, "utf-8");
		let total: number = 0;
		for (const line of content.split("\n")) {
			total += extractCostFromLine(line);
		}
		return total;
	} catch {
		return 0;
	}
};

const collectJsonlFiles = (dir: string): string[] => {
	const results: string[] = [];
	try {
		const entries: string[] = readdirSync(dir);
		for (const entry of entries) {
			const full: string = join(dir, entry);
			try {
				const st = statSync(full);
				if (st.isDirectory()) {
					results.push(...collectJsonlFiles(full));
				} else if (entry.endsWith(".jsonl")) {
					results.push(full);
				}
			} catch {
				// skip unreadable entries
			}
		}
	} catch {
		// skip unreadable dirs
	}
	return results;
};

let cachedTodayCost: number = 0;
let cachedTodayDate: string = "";
let lastScanTime: number = 0;
const SCAN_INTERVAL_MS: number = 30_000;

const getTodayCost = (): number => {
	const today: string = getTodayDateString();
	const now: number = Date.now();

	if (today !== cachedTodayDate) {
		cachedTodayCost = 0;
		cachedTodayDate = today;
		lastScanTime = 0;
	}

	if (now - lastScanTime < SCAN_INTERVAL_MS) {
		return cachedTodayCost;
	}

	lastScanTime = now;

	// Today's date in the filename format: 2026-09-04
	const sessionsDir: string = join(homedir(), ".pi", "agent", "sessions");
	let total: number = 0;

	try {
		const projectDirs: string[] = readdirSync(sessionsDir);
		for (const projDir of projectDirs) {
			const projPath: string = join(sessionsDir, projDir);
			try {
				if (!statSync(projPath).isDirectory()) continue;
			} catch {
				continue;
			}

			const allFiles: string[] = collectJsonlFiles(projPath);
			for (const f of allFiles) {
				// Match today's date in the path (covers both flat and nested)
				if (!f.includes(today)) continue;
				total += sumCostsInFile(f);
			}
		}
	} catch {
		// sessions dir may not exist yet
	}

	cachedTodayCost = total;
	return total;
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
					const firstLine: string[] = [theme.fg("accent", shortenHome(ctx.cwd))];
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

					const todayCost: number = getTodayCost();
					const thirdLine: string[] = [
						theme.fg("warning", `$${formatCost(todayCost)} USD today`),
					];

					for (const status of footerData.getExtensionStatuses().values()) {
						const plain: string = status.replace(/\x1b\[[0-9;]*m/g, "");

						const multiMatch = plain.match(
							/\d+h\s+(\d+)%\s+left\/(\d+[dhm](?:\d+[hm])?)/i,
						);
						const piMatch = plain.match(/(\d+)%\s+(?:↻\s*)?(\d+[dhm](?:\d+[hm])?)/i);

						const match = multiMatch ?? piMatch;
						if (match) {
							const percentage: string = match[1] ?? "";
							const resetTime: string = (match[2] ?? "").replace(
								/(\d+[dh])(\d)/,
								"$1 $2",
							);
							thirdLine.push(
								theme.fg("dim", `usage: ${percentage}% left | resets in ${resetTime}`),
							);
						} else {
							thirdLine.push(status);
						}
					}

					return [
						"",
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
