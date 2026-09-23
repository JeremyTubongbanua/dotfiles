/**
 * Permission Gate Extension
 *
 * Prompts for confirmation before running potentially dangerous bash commands.
 * Patterns checked: rm -rf, sudo, chmod/chown 777
 */

import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import type { AutocompleteItem } from "@earendil-works/pi-tui";

const DANGEROUS_PATTERNS: RegExp[] = [/\brm\s+(-rf?|--recursive)/i, /\bsudo\b/i, /\b(chmod|chown)\b.*777/i];

const COMMAND_ARGS: string[] = ["on", "off", "status"];

const permissionGate = (pi: ExtensionAPI): void => {
	let enabled: boolean = true;

	pi.registerCommand("permission-gate", {
		description: "Toggle the dangerous bash command prompt (on, off, status)",
		getArgumentCompletions: (prefix: string): AutocompleteItem[] | null => {
			const items: AutocompleteItem[] = COMMAND_ARGS.filter((arg: string): boolean => {
				return arg.startsWith(prefix.trim().toLowerCase());
			}).map((arg: string): AutocompleteItem => {
				return { value: arg, label: arg };
			});
			return items.length > 0 ? items : null;
		},
		handler: async (args: string, ctx: ExtensionCommandContext): Promise<void> => {
			const requested: string = args.trim().toLowerCase();
			if (requested === "on") {
				enabled = true;
			} else if (requested === "off") {
				enabled = false;
			} else if (requested === "") {
				enabled = !enabled;
			} else if (requested !== "status") {
				ctx.ui.notify(`Unknown argument "${requested}". Use on, off, or status.`, "error");
				return;
			}
			ctx.ui.notify(`Permission gate is ${enabled ? "on" : "off"}`, enabled ? "info" : "warning");
		},
	});

	pi.on("tool_call", async (event, ctx) => {
		if (!enabled) return undefined;
		if (event.toolName !== "bash") return undefined;

		const command: string = event.input.command as string;
		const isDangerous: boolean = DANGEROUS_PATTERNS.some((p: RegExp): boolean => p.test(command));

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
};

export default permissionGate;
