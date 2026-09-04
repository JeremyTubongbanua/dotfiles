import { readFileSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
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

type AccountInfo = {
	label: string;
	email: string;
	family: "anthropic" | "openai-codex";
	fiveHourUsedPercent?: number;
	fiveHourResetAt?: number;
	sevenDayUsedPercent?: number;
	sevenDayResetAt?: number;
};

type UsageWindow = {
	usedPercent?: number;
	resetAt?: number;
	windowSeconds?: number;
};

type ProviderUsage = {
	account?: string;
	primary?: UsageWindow;
	secondary?: UsageWindow;
};

type FailoverState = {
	usageByProvider?: Record<string, ProviderUsage>;
};

type UsageSummary = {
	percentLeft: number;
	resetIn: string;
};

type ClaudeUsageWindow = {
	utilization?: number;
	resets_at?: string;
};

type ClaudeProfile = {
	oauthAccount?: {
		emailAddress?: string;
	};
	cachedUsageUtilization?: {
		utilization?: {
			five_hour?: ClaudeUsageWindow;
			seven_day?: ClaudeUsageWindow;
		};
	};
};

type CodexAuth = {
	tokens?: {
		access_token?: string;
	};
};

type CodexClaims = Record<string, { email?: string } | undefined>;

let cachedFailoverState: FailoverState | undefined;
let lastFailoverStateScan: number = 0;
const FAILOVER_STATE_SCAN_INTERVAL_MS: number = 30_000;

let cachedAccounts: AccountInfo[] = [];
let lastAccountScan: number = 0;
const ACCOUNT_SCAN_INTERVAL_MS: number = 30_000;

const getFailoverState = (): FailoverState | undefined => {
	const now: number = Date.now();
	if (now - lastFailoverStateScan < FAILOVER_STATE_SCAN_INTERVAL_MS) {
		return cachedFailoverState;
	}

	lastFailoverStateScan = now;
	try {
		const statePath: string = join(
			homedir(),
			".pi",
			"agent",
			"provider-failover-state.json",
		);
		cachedFailoverState = JSON.parse(
			readFileSync(statePath, "utf-8"),
		) as FailoverState;
	} catch {
		cachedFailoverState = undefined;
	}
	return cachedFailoverState;
};

const getProviderUsage = (provider: string): ProviderUsage | undefined => {
	return getFailoverState()?.usageByProvider?.[provider];
};

const parseResetAt = (value: string | undefined): number | undefined => {
	if (!value) return undefined;
	const resetAt: number = Date.parse(value);
	return Number.isFinite(resetAt) ? resetAt : undefined;
};

const readClaudeAccount = (
	directory: string,
	label: string,
): AccountInfo | undefined => {
	try {
		const profile: ClaudeProfile = JSON.parse(
			readFileSync(join(directory, ".claude.json"), "utf-8"),
		) as ClaudeProfile;
		const email: string | undefined = profile.oauthAccount?.emailAddress;
		if (!email) return undefined;
		const usage = profile.cachedUsageUtilization?.utilization;
		return {
			label,
			email,
			family: "anthropic",
			fiveHourUsedPercent: usage?.five_hour?.utilization,
			fiveHourResetAt: parseResetAt(usage?.five_hour?.resets_at),
			sevenDayUsedPercent: usage?.seven_day?.utilization,
			sevenDayResetAt: parseResetAt(usage?.seven_day?.resets_at),
		};
	} catch {
		return undefined;
	}
};

const readCodexAccount = (
	directory: string,
	label: string,
): AccountInfo | undefined => {
	try {
		const auth: CodexAuth = JSON.parse(
			readFileSync(join(directory, "auth.json"), "utf-8"),
		) as CodexAuth;
		const token: string | undefined = auth.tokens?.access_token;
		const payload: string | undefined = token?.split(".")[1];
		if (!payload) return undefined;
		const claims: CodexClaims = JSON.parse(
			Buffer.from(payload, "base64url").toString("utf-8"),
		) as CodexClaims;
		const profileKey: string | undefined = Object.keys(claims).find(
			(key: string): boolean => key.endsWith("/profile"),
		);
		const email: string | undefined = profileKey
			? claims[profileKey]?.email
			: undefined;
		return email ? { label, email, family: "openai-codex" } : undefined;
	} catch {
		return undefined;
	}
};

const getAccounts = (): AccountInfo[] => {
	const now: number = Date.now();
	if (now - lastAccountScan < ACCOUNT_SCAN_INTERVAL_MS) return cachedAccounts;

	lastAccountScan = now;
	const home: string = homedir();
	const accounts: AccountInfo[] = [];
	try {
		for (const entry of readdirSync(home)) {
			if (entry === ".claude" || entry.startsWith(".claude-")) {
				const account: AccountInfo | undefined = readClaudeAccount(
					join(home, entry),
					entry.slice(1),
				);
				if (account) accounts.push(account);
			} else if (entry === ".codex" || entry.startsWith(".codex-")) {
				const account: AccountInfo | undefined = readCodexAccount(
					join(home, entry),
					entry.slice(1),
				);
				if (account) accounts.push(account);
			}
		}
	} catch {
		cachedAccounts = [];
		return cachedAccounts;
	}

	cachedAccounts = accounts;
	return cachedAccounts;
};

const usageWindowMatches = (
	usage: UsageWindow | undefined,
	usedPercent: number | undefined,
	resetAt: number | undefined,
): boolean => {
	if (usage?.usedPercent === undefined || usage.resetAt === undefined)
		return false;
	if (usedPercent === undefined || resetAt === undefined) return false;
	return (
		Math.round(usage.usedPercent) === Math.round(usedPercent) &&
		Math.abs(usage.resetAt - resetAt) < 5_000
	);
};

const getAccountInfo = (provider: string): AccountInfo => {
	const usage: ProviderUsage | undefined = getProviderUsage(provider);
	const family: "anthropic" | "openai-codex" = provider.startsWith(
		"openai-codex",
	)
		? "openai-codex"
		: "anthropic";
	const accounts: AccountInfo[] = getAccounts().filter(
		(account: AccountInfo): boolean => account.family === family,
	);
	const reportedAccount: AccountInfo | undefined = usage?.account
		? accounts.find(
				(account: AccountInfo): boolean => account.email === usage.account,
			)
		: undefined;
	if (reportedAccount) return reportedAccount;

	if (family === "anthropic") {
		const matchedAccount: AccountInfo | undefined = accounts.find(
			(account: AccountInfo): boolean =>
				usageWindowMatches(
					usage?.primary,
					account.fiveHourUsedPercent,
					account.fiveHourResetAt,
				) &&
				usageWindowMatches(
					usage?.secondary,
					account.sevenDayUsedPercent,
					account.sevenDayResetAt,
				),
		);
		if (matchedAccount) return matchedAccount;
	}

	return {
		label: provider || "no account",
		email: usage?.account ?? "unknown",
		family,
	};
};

const formatResetCountdown = (resetAt: number): string => {
	const resetMilliseconds: number =
		resetAt < 10_000_000_000 ? resetAt * 1000 : resetAt;
	const minutesLeft: number = Math.max(
		0,
		Math.ceil((resetMilliseconds - Date.now()) / 60_000),
	);
	if (minutesLeft === 0) return "now";

	const hours: number = Math.floor(minutesLeft / 60);
	const minutes: number = minutesLeft % 60;
	if (hours === 0) return `${minutes}m`;
	if (hours < 24) return minutes === 0 ? `${hours}h` : `${hours}h ${minutes}m`;

	const days: number = Math.floor(hours / 24);
	const remainingHours: number = hours % 24;
	return remainingHours === 0 ? `${days}d` : `${days}d ${remainingHours}h`;
};

const stripAnsi = (value: string): string => {
	let plain: string = "";
	let escapeState: "none" | "start" | "csi" = "none";

	for (const character of value) {
		const code: number = character.charCodeAt(0);
		if (escapeState === "none" && code === 27) {
			escapeState = "start";
			continue;
		}
		if (escapeState === "start") {
			escapeState = character === "[" ? "csi" : "none";
			continue;
		}
		if (escapeState === "csi") {
			if (code >= 64 && code <= 126) escapeState = "none";
			continue;
		}
		plain += character;
	}

	return plain;
};

const getUsageSummary = (
	provider: string,
	statuses: ReadonlyArray<readonly [string, string]>,
): UsageSummary | undefined => {
	const providerUsage: ProviderUsage | undefined = getProviderUsage(provider);
	const windows: UsageWindow[] = [
		providerUsage?.primary,
		providerUsage?.secondary,
	].filter(
		(window: UsageWindow | undefined): window is UsageWindow =>
			window?.usedPercent !== undefined && window.resetAt !== undefined,
	);
	const shortestWindow: UsageWindow | undefined = windows.sort(
		(left: UsageWindow, right: UsageWindow): number =>
			(left.windowSeconds ?? Number.POSITIVE_INFINITY) -
			(right.windowSeconds ?? Number.POSITIVE_INFINITY),
	)[0];

	if (
		shortestWindow?.usedPercent !== undefined &&
		shortestWindow.resetAt !== undefined
	) {
		return {
			percentLeft: Math.max(
				0,
				Math.min(100, Math.round(100 - shortestWindow.usedPercent)),
			),
			resetIn: formatResetCountdown(shortestWindow.resetAt),
		};
	}

	for (const [, status] of statuses) {
		const plain: string = stripAnsi(status);
		const match: RegExpMatchArray | null = plain.match(
			/\b(?:\d+[dh]|week(?:ly)?|session|auth)\s+(\d{1,3})%\s+left\s*\/\s*(\d+[dhm](?:\s?\d+[hm])?)/i,
		);
		if (!match?.[1] || !match[2]) continue;
		return {
			percentLeft: Math.max(0, Math.min(100, Number(match[1]))),
			resetIn: match[2].replace(/([dh])(?=\d)/g, "$1 "),
		};
	}

	return undefined;
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
					const provider: string = ctx.model?.provider ?? "";
					const account: AccountInfo = getAccountInfo(provider);
					const branch: string | null = footerData.getGitBranch();
					const modelName: string = ctx.model?.name ?? ctx.model?.id ?? "no model";
					const thinking: string = ctx.model?.reasoning
						? ` (${ctx.thinkingLevel ?? "off"})`
						: "";
					const firstLine: string[] = [
						theme.fg("accent", shortenHome(ctx.cwd)),
						theme.fg(branch ? "success" : "dim", branch ?? "no branch"),
						theme.fg("warning", `${modelName}${thinking}`),
						theme.fg("accent", account.email),
					];

					const statuses: Array<readonly [string, string]> = [
						...footerData.getExtensionStatuses(),
					];
					const contextUsage = ctx.getContextUsage();
					const contextText: string =
						contextUsage?.percent === null || contextUsage === undefined
							? "ctx: ? left"
							: `ctx: ${Math.max(0, Math.round(100 - contextUsage.percent))}% left`;
					let contextColor: "error" | "warning" | "success" = "success";
					if ((contextUsage?.percent ?? 0) >= 80) {
						contextColor = "error";
					} else if ((contextUsage?.percent ?? 0) >= 50) {
						contextColor = "warning";
					}
					const usageSummary: UsageSummary | undefined = getUsageSummary(
						provider,
						statuses,
					);
					const secondLine: string[] = [
						theme.fg("accent", account.label),
						theme.fg(contextColor, contextText),
						theme.fg(
							"dim",
							usageSummary
								? `usage: ${usageSummary.percentLeft}% left`
								: "usage: ? left",
						),
						theme.fg(
							"dim",
							usageSummary ? `resets in ${usageSummary.resetIn}` : "resets in ?",
						),
					];

					const activeLspNames: string[] = [];
					for (const [statusId, status] of statuses) {
						if (statusId !== "pi-lens-lsp") continue;
						const activeMatch: RegExpMatchArray | null = stripAnsi(status).match(
							/LSP Active:\s*([^·]+)/i,
						);
						if (activeMatch?.[1]) {
							activeLspNames.push(
								...activeMatch[1].split(",").map((name: string) => name.trim()),
							);
						}
					}

					const todayCost: number = getTodayCost();
					const thirdLine: string[] = [
						theme.fg("warning", `cost: $${formatCost(todayCost)} USD today`),
						theme.fg(
							"dim",
							`LSPs: ${activeLspNames.length > 0 ? activeLspNames.join(", ") : "inactive"}`,
						),
					];

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
