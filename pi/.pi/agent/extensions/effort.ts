import { getSupportedThinkingLevels } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import type { AutocompleteItem } from "@earendil-works/pi-tui";

type ThinkingLevel = ReturnType<ExtensionAPI["getThinkingLevel"]>;

const ALL_LEVELS: ThinkingLevel[] = ["off", "minimal", "low", "medium", "high", "xhigh", "max"];

const getAvailableLevels = (ctx: ExtensionCommandContext | undefined): ThinkingLevel[] => {
	if (!ctx?.model) {
		return ALL_LEVELS;
	}
	return getSupportedThinkingLevels(ctx.model) as ThinkingLevel[];
};

const effortExtension = (pi: ExtensionAPI): void => {
	pi.registerCommand("effort", {
		description: "Set thinking level (alias for /thinking)",
		getArgumentCompletions: (prefix: string): AutocompleteItem[] | null => {
			const items: AutocompleteItem[] = ALL_LEVELS.filter((level: ThinkingLevel): boolean => {
				return level.startsWith(prefix.trim().toLowerCase());
			}).map((level: ThinkingLevel): AutocompleteItem => {
				return { value: level, label: level };
			});
			return items.length > 0 ? items : null;
		},
		handler: async (args: string, ctx: ExtensionCommandContext): Promise<void> => {
			const availableLevels: ThinkingLevel[] = getAvailableLevels(ctx);
			let requested: string | undefined = args.trim().toLowerCase();
			if (!requested) {
				const current: ThinkingLevel = pi.getThinkingLevel();
				const options: string[] = availableLevels.map((level: ThinkingLevel): string => {
					return level === current ? `${level} (current)` : level;
				});
				const choice: string | undefined = await ctx.ui.select("Thinking level", options);
				if (!choice) {
					return;
				}
				requested = choice.replace(" (current)", "");
			}
			const level: ThinkingLevel | undefined = availableLevels.find((candidate: ThinkingLevel): boolean => {
				return candidate === requested;
			});
			if (!level) {
				ctx.ui.notify(`Unknown thinking level "${requested}". Available levels: ${availableLevels.join(", ")}.`, "error");
				return;
			}
			pi.setThinkingLevel(level);
			ctx.ui.notify(`Thinking level: ${level}`, "info");
		},
	});
};

export default effortExtension;
