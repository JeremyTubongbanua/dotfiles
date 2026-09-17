import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const clearExtension = (pi: ExtensionAPI): void => {
	pi.registerCommand("clear", {
		description: "Start a blank session",
		handler: async (_args: string, ctx): Promise<void> => {
			await ctx.newSession({
				withSession: async (newSessionContext): Promise<void> => {
					newSessionContext.ui.notify("Started a blank session", "info");
				},
			});
		},
	});
};

export default clearExtension;
