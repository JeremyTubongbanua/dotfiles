/**
 * Permission Gate Extension
 *
 * Prompts for confirmation before running potentially dangerous bash commands.
 * Patterns checked: rm -rf, sudo, chmod/chown 777
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	const dangerousPatterns = [/\brm\s+(-rf?|--recursive)/i, /\bsudo\b/i, /\b(chmod|chown)\b.*777/i];

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined;

		const command = event.input.command as string;
		const isDangerous = dangerousPatterns.some((p) => p.test(command));

		if (isDangerous) {
			if (!ctx.hasUI) {
				// In non-interactive mode, block by default
				return { block: true, reason: "Dangerous command blocked (no UI for confirmation)" };
			}

			pi.events.emit("herdr:blocked", { active: true, label: "Waiting for permission to run a dangerous command" });
			let choice: string | undefined;
			try {
				choice = await ctx.ui.select(`⚠️ Dangerous command:\n\n  ${command}\n\nAllow?`, ["Yes", "No"]);
			} finally {
				pi.events.emit("herdr:blocked", { active: false });
			}

			if (choice !== "Yes") {
				return { block: true, reason: "Blocked by user" };
			}
		}

		return undefined;
	});
}
