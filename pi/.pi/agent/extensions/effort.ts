import { getSupportedThinkingLevels } from "@earendil-works/pi-ai";
import {
	ThinkingSelectorComponent,
	type ExtensionAPI,
	type ExtensionCommandContext,
	type Theme,
} from "@earendil-works/pi-coding-agent";
import type { AutocompleteItem, KeybindingsManager, TUI } from "@earendil-works/pi-tui";

type ThinkingLevel = ReturnType<ExtensionAPI["getThinkingLevel"]>;

const ALL_LEVELS: ThinkingLevel[] = ["off", "minimal", "low", "medium", "high", "xhigh", "max"];

const getAvailableLevels = (ctx: ExtensionCommandContext | undefined): ThinkingLevel[] => {
	if (!ctx?.model) {
		return ALL_LEVELS;
	}
	return getSupportedThinkingLevels(ctx.model) as ThinkingLevel[];
};

const pickLevel = (
	ctx: ExtensionCommandContext,
	current: ThinkingLevel,
	availableLevels: ThinkingLevel[],
): Promise<ThinkingLevel | undefined> => {
	return ctx.ui.custom<ThinkingLevel | undefined>(
		(
			_tui: TUI,
			_theme: Theme,
			_keybindings: KeybindingsManager,
			done: (result: ThinkingLevel | undefined) => void,
		): ThinkingSelectorComponent => {
			return new ThinkingSelectorComponent(
				current,
				availableLevels,
				(level: ThinkingLevel): void => {
					done(level);
				},
				(): void => {
					done(undefined);
				},
				(): void => {
					ctx.ui.notify("Use /thinking to save a default thinking level.", "info");
				},
			);
		},
	);
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
				const choice: ThinkingLevel | undefined = await pickLevel(ctx, pi.getThinkingLevel(), availableLevels);
				if (!choice) {
					return;
				}
				requested = choice;
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
