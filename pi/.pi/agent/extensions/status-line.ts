import { readFileSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
	calculateCost,
	type Api,
	type Model,
	type Usage,
} from "@earendil-works/pi-ai";
import { getBuiltinModels } from "@earendil-works/pi-ai/providers/all";
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
	directory?: string;
	fiveHourUsedPercent?: number;
	fiveHourResetAt?: number;
	sevenDayUsedPercent?: number;
	sevenDayResetAt?: number;
};

type PiAuthEntry = {
	access?: string;
};

type PiAuthFile = Record<string, PiAuthEntry | undefined>;

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

type FiveHourUsage = {
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
		account_id?: string;
	};
};

type CodexUsageWindow = {
	used_percent?: number;
	limit_window_seconds?: number;
	reset_at?: number;
};

type CodexRateLimit = {
	primary_window?: CodexUsageWindow | null;
	secondary_window?: CodexUsageWindow | null;
};

type CodexUsageResponse = {
	rate_limit?: CodexRateLimit;
	additional_rate_limits?: Array<{
		rate_limit?: CodexRateLimit;
	}>;
};

type CodexProfileClaims = {
	email?: string;
};

type CodexClaims = Record<string, CodexProfileClaims | string | undefined> & {
	email?: string;
};

let cachedFailoverState: FailoverState | undefined;
let lastFailoverStateScan: number = 0;
const FAILOVER_STATE_SCAN_INTERVAL_MS: number = 30_000;

let cachedAccounts: AccountInfo[] = [];
let cachedProviderAccounts: ReadonlyMap<string, AccountInfo> = new Map();
let lastAccountScan: number = 0;
const ACCOUNT_SCAN_INTERVAL_MS: number = 30_000;

const cachedCodexFiveHourUsage: Map<
	string,
	{ account: string; window: UsageWindow }
> = new Map();
const lastCodexUsageRefresh: Map<string, number> = new Map();
const CODEX_USAGE_REFRESH_INTERVAL_MS: number = 60_000;
const CODEX_USAGE_URL: string = [
	"https://chatgpt.com",
	"backend-api",
	"wham",
	"usage",
].join("/");

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
			directory,
			fiveHourUsedPercent: usage?.five_hour?.utilization,
			fiveHourResetAt: parseResetAt(usage?.five_hour?.resets_at),
			sevenDayUsedPercent: usage?.seven_day?.utilization,
			sevenDayResetAt: parseResetAt(usage?.seven_day?.resets_at),
		};
	} catch {
		return undefined;
	}
};

const getCodexEmailFromToken = (
	token: string | undefined,
): string | undefined => {
	try {
		const payload: string | undefined = token?.split(".")[1];
		if (!payload) return undefined;
		const claims: CodexClaims = JSON.parse(
			Buffer.from(payload, "base64url").toString("utf-8"),
		) as CodexClaims;
		if (claims.email) return claims.email;

		const profileKey: string | undefined = Object.keys(claims).find(
			(key: string): boolean => key.endsWith("/profile"),
		);
		const profile: CodexProfileClaims | undefined = profileKey
			? (claims[profileKey] as CodexProfileClaims | undefined)
			: undefined;
		return profile?.email;
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
		const email: string | undefined = getCodexEmailFromToken(
			auth.tokens?.access_token,
		);
		return email
			? { label, email, family: "openai-codex", directory }
			: undefined;
	} catch {
		return undefined;
	}
};

const readPiCodexProviderAccounts = (
	accounts: ReadonlyArray<AccountInfo>,
): ReadonlyMap<string, AccountInfo> => {
	const agentDirectory: string = join(homedir(), ".pi", "agent");
	let auth: PiAuthFile = {};
	let sidecar: PiAuthFile = {};
	try {
		auth = JSON.parse(
			readFileSync(join(agentDirectory, "auth.json"), "utf-8"),
		) as PiAuthFile;
	} catch {
		return new Map();
	}
	try {
		sidecar = JSON.parse(
			readFileSync(
				join(agentDirectory, "pi-multi-account-proxy-oauth.json"),
				"utf-8",
			),
		) as PiAuthFile;
	} catch {
		sidecar = {};
	}

	const providerAccounts: Map<string, AccountInfo> = new Map();
	const providers: Set<string> = new Set([
		...Object.keys(auth),
		...Object.keys(sidecar),
	]);
	for (const provider of providers) {
		if (provider !== "openai-codex" && !provider.startsWith("openai-codex-")) {
			continue;
		}
		const token: string | undefined =
			sidecar[provider]?.access ?? auth[provider]?.access;
		const email: string | undefined = getCodexEmailFromToken(token);
		if (!email) continue;
		const matchingAccount: AccountInfo | undefined = accounts.find(
			(account: AccountInfo): boolean =>
				account.family === "openai-codex" && account.email === email,
		);
		providerAccounts.set(
			provider,
			matchingAccount ?? {
				label: provider,
				email,
				family: "openai-codex",
			},
		);
	}
	return providerAccounts;
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
		cachedProviderAccounts = new Map();
		return cachedAccounts;
	}

	cachedAccounts = accounts;
	cachedProviderAccounts = readPiCodexProviderAccounts(accounts);
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

	const providerAccount: AccountInfo | undefined =
		cachedProviderAccounts.get(provider);
	if (providerAccount) return providerAccount;

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

const parseCodexUsageWindow = (
	window: CodexUsageWindow | null | undefined,
): UsageWindow | undefined => {
	if (
		window?.limit_window_seconds !== 18_000 ||
		window.used_percent === undefined ||
		window.reset_at === undefined ||
		!Number.isFinite(window.used_percent) ||
		!Number.isFinite(window.reset_at)
	) {
		return undefined;
	}

	return {
		usedPercent: window.used_percent,
		resetAt: window.reset_at,
		windowSeconds: window.limit_window_seconds,
	};
};

const refreshCodexFiveHourUsage = async (provider: string): Promise<void> => {
	const account: AccountInfo = getAccountInfo(provider);
	if (account.family !== "openai-codex" || !account.directory) return;

	const now: number = Date.now();
	const refreshKey: string = `${provider}:${account.email}`;
	const lastRefresh: number = lastCodexUsageRefresh.get(refreshKey) ?? 0;
	if (now - lastRefresh < CODEX_USAGE_REFRESH_INTERVAL_MS) return;
	lastCodexUsageRefresh.set(refreshKey, now);

	try {
		const auth: CodexAuth = JSON.parse(
			readFileSync(join(account.directory, "auth.json"), "utf-8"),
		) as CodexAuth;
		const accessToken: string | undefined = auth.tokens?.access_token;
		if (!accessToken) return;

		const headers: Headers = new Headers({
			Authorization: `Bearer ${accessToken}`,
			Accept: "application/json",
		});
		if (auth.tokens?.account_id) {
			headers.set("ChatGPT-Account-Id", auth.tokens.account_id);
		}

		const response: Response = await fetch(CODEX_USAGE_URL, {
			headers,
			signal: AbortSignal.timeout(10_000),
		});
		if (!response.ok) return;

		const body: CodexUsageResponse =
			(await response.json()) as CodexUsageResponse;
		const rateLimits: Array<CodexRateLimit | undefined> = [
			body.rate_limit,
			...(body.additional_rate_limits ?? []).map(
				(item: { rate_limit?: CodexRateLimit }): CodexRateLimit | undefined =>
					item.rate_limit,
			),
		];
		for (const rateLimit of rateLimits) {
			const fiveHourWindow: UsageWindow | undefined =
				parseCodexUsageWindow(rateLimit?.primary_window) ??
				parseCodexUsageWindow(rateLimit?.secondary_window);
			if (!fiveHourWindow) continue;
			cachedCodexFiveHourUsage.set(provider, {
				account: account.email,
				window: fiveHourWindow,
			});
			return;
		}
	} catch {
		return;
	}
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
	if (minutes === 0) return `${hours}h`;
	return `${hours}h ${minutes}m`;
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

const getFiveHourUsage = (
	provider: string,
	statuses: ReadonlyArray<readonly [string, string]>,
): FiveHourUsage | undefined => {
	const providerUsage: ProviderUsage | undefined = getProviderUsage(provider);
	const account: AccountInfo = getAccountInfo(provider);
	const cachedCodexUsage = cachedCodexFiveHourUsage.get(provider);
	const windows: Array<UsageWindow | undefined> = [
		providerUsage?.primary,
		providerUsage?.secondary,
		cachedCodexUsage?.account === account.email
			? cachedCodexUsage.window
			: undefined,
	];
	const fiveHourWindow: UsageWindow | undefined = windows.find(
		(window: UsageWindow | undefined): boolean =>
			window?.windowSeconds === 18_000,
	);

	if (
		fiveHourWindow?.usedPercent !== undefined &&
		fiveHourWindow.resetAt !== undefined
	) {
		return {
			percentLeft: Math.max(
				0,
				Math.min(100, Math.round(100 - fiveHourWindow.usedPercent)),
			),
			resetIn: formatResetCountdown(fiveHourWindow.resetAt),
		};
	}

	for (const [, status] of statuses) {
		const plain: string = stripAnsi(status);
		const match: RegExpMatchArray | null = plain.match(
			/\b5h\s+(\d{1,3})%\s+left\s*\/\s*(\d+[dhm](?:\s?\d+[hm])?)/i,
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

type CostSessionEntry = {
	message?: {
		provider?: string;
		model?: string;
		usage?: Usage;
	};
	usage?: Usage;
};

const CODEX_COST_MODELS: ReadonlyMap<string, Model<Api>> = new Map(
	getBuiltinModels("openai-codex").map(
		(model: Model<Api>): readonly [string, Model<Api>] => [model.id, model],
	),
);

const calculateTrackedCost = (
	provider: string,
	modelId: string,
	usage: Usage,
): Usage["cost"] => {
	if (usage.cost.total !== 0) return usage.cost;
	if (provider !== "openai-codex" && !provider.startsWith("openai-codex-")) {
		return usage.cost;
	}

	const model: Model<Api> | undefined = CODEX_COST_MODELS.get(modelId);
	if (!model) return usage.cost;
	return calculateCost(model, { ...usage, cost: { ...usage.cost } });
};

const extractCostFromLine = (line: string): number => {
	if (!line.includes('"cost"')) return 0;
	try {
		const entry: CostSessionEntry = JSON.parse(line) as CostSessionEntry;
		const usage: Usage | undefined = entry.message?.usage ?? entry.usage;
		if (!usage) return 0;
		return calculateTrackedCost(
			entry.message?.provider ?? "",
			entry.message?.model ?? "",
			usage,
		).total;
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
	const refreshUsage = (provider: string): void => {
		void refreshCodexFiveHourUsage(provider).then(() => requestRender?.());
	};

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
					const fiveHourUsage: FiveHourUsage | undefined = getFiveHourUsage(
						provider,
						statuses,
					);
					const secondLine: string[] = [
						theme.fg("accent", account.label),
						theme.fg(contextColor, contextText),
					];
					if (fiveHourUsage) {
						secondLine.push(
							theme.fg("dim", `usage: ${fiveHourUsage.percentLeft}% left`),
							theme.fg("dim", `resets in ${fiveHourUsage.resetIn}`),
						);
					}

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
						theme.fg("warning", `$${formatCost(todayCost)} USD today`),
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
		refreshUsage(ctx.model?.provider ?? "");
	});

	pi.on("message_end", (event, ctx) => {
		requestRender?.();
		refreshUsage(ctx.model?.provider ?? "");
		if (event.message.role !== "assistant") return;

		const cost: Usage["cost"] = calculateTrackedCost(
			event.message.provider,
			event.message.model,
			event.message.usage,
		);
		if (cost === event.message.usage.cost) return;

		return {
			message: {
				...event.message,
				usage: { ...event.message.usage, cost },
			},
		};
	});
	pi.on("model_select", (event) => {
		requestRender?.();
		refreshUsage(event.model.provider);
	});
	pi.on("thinking_level_select", () => requestRender?.());
};

export default statusLine;
