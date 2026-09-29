import { randomUUID } from "node:crypto";
import { writeFileSync } from "node:fs";
import type {
	ExtensionAPI,
	ExtensionCommandContext,
	SessionHeader,
	SessionInfoEntry,
	SessionManager,
} from "@earendil-works/pi-coding-agent";

type NewSessionOptions = NonNullable<Parameters<ExtensionCommandContext["newSession"]>[0]>;
type ReplacedSessionContext = Parameters<NonNullable<NewSessionOptions["withSession"]>>[0];

const startBlankSession = async (ctx: ExtensionCommandContext, name: string | undefined): Promise<void> => {
	await ctx.newSession({
		setup: async (sessionManager: SessionManager): Promise<void> => {
			if (name) {
				sessionManager.appendSessionInfo(name);
			}
		},
		withSession: async (newSessionContext: ReplacedSessionContext): Promise<void> => {
			newSessionContext.ui.notify("Started a blank session", "info");
		},
	});
};

const truncateSessionFile = (sessionFile: string, header: SessionHeader, name: string | undefined): void => {
	if (!name) {
		writeFileSync(sessionFile, `${JSON.stringify(header)}\n`);
		return;
	}

	const nameEntry: SessionInfoEntry = {
		type: "session_info",
		id: randomUUID().slice(0, 8),
		parentId: null,
		timestamp: new Date().toISOString(),
		name,
	};
	writeFileSync(sessionFile, `${JSON.stringify(header)}\n${JSON.stringify(nameEntry)}\n`);
};

const clearCurrentSession = async (
	ctx: ExtensionCommandContext,
	sessionFile: string,
	header: SessionHeader,
	name: string | undefined,
): Promise<void> => {
	// Leave the session first so nothing still holds the old file while it is rewritten.
	await ctx.newSession({
		withSession: async (blankContext: ReplacedSessionContext): Promise<void> => {
			truncateSessionFile(sessionFile, header, name);
			await blankContext.switchSession(sessionFile, {
				withSession: async (clearedContext: ReplacedSessionContext): Promise<void> => {
					clearedContext.ui.notify(name ? `Cleared session "${name}"` : "Cleared session", "info");
				},
			});
		},
	});
};

const clearExtension = (pi: ExtensionAPI): void => {
	pi.registerCommand("clear", {
		description: "Clear context while keeping the current session",
		handler: async (_args: string, ctx: ExtensionCommandContext): Promise<void> => {
			await ctx.waitForIdle();
			const name: string | undefined = ctx.sessionManager.getSessionName();
			const sessionFile: string | undefined = ctx.sessionManager.getSessionFile();
			const header: SessionHeader | null = ctx.sessionManager.getHeader();
			if (!sessionFile || !header) {
				await startBlankSession(ctx, name);
				return;
			}
			await clearCurrentSession(ctx, sessionFile, header, name);
		},
	});
};

export default clearExtension;
