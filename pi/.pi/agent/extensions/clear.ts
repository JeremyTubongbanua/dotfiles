import { randomUUID } from "node:crypto";
import { existsSync, writeFileSync } from "node:fs";
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

const truncateSessionFile = (sessionFile: string, header: SessionHeader, name: string): void => {
	const nameEntry: SessionInfoEntry = {
		type: "session_info",
		id: randomUUID().slice(0, 8),
		parentId: null,
		timestamp: new Date().toISOString(),
		name,
	};
	writeFileSync(sessionFile, `${JSON.stringify(header)}\n${JSON.stringify(nameEntry)}\n`);
};

const clearNamedSession = async (
	ctx: ExtensionCommandContext,
	sessionFile: string,
	header: SessionHeader,
	name: string,
): Promise<void> => {
	// Leave the session first so nothing still holds the old file while it is rewritten.
	await ctx.newSession({
		withSession: async (blankContext: ReplacedSessionContext): Promise<void> => {
			truncateSessionFile(sessionFile, header, name);
			await blankContext.switchSession(sessionFile, {
				withSession: async (clearedContext: ReplacedSessionContext): Promise<void> => {
					clearedContext.ui.notify(`Cleared session "${name}"`, "info");
				},
			});
		},
	});
};

const clearExtension = (pi: ExtensionAPI): void => {
	pi.registerCommand("clear", {
		description: "Clear the current named session, or start a blank one",
		handler: async (_args: string, ctx: ExtensionCommandContext): Promise<void> => {
			await ctx.waitForIdle();
			const name: string | undefined = ctx.sessionManager.getSessionName();
			const sessionFile: string | undefined = ctx.sessionManager.getSessionFile();
			const header: SessionHeader | null = ctx.sessionManager.getHeader();
			if (!name) {
				await startBlankSession(ctx, undefined);
				return;
			}
			if (!sessionFile || !header || !existsSync(sessionFile)) {
				await startBlankSession(ctx, name);
				return;
			}
			await clearNamedSession(ctx, sessionFile, header, name);
		},
	});
};

export default clearExtension;
