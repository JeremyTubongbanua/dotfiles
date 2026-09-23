import {
    ModelSelectorComponent,
    type ExtensionAPI,
    type ExtensionContext,
    type ExtensionUIContext,
    type SessionStartEvent,
    type Theme,
    type ThemeColor,
} from "@earendil-works/pi-coding-agent";
import {
    CURSOR_MARKER,
    getKeybindings,
    Key,
    matchesKey,
    Text,
    type Input,
    type Keybinding,
    type KeybindingsManager,
} from "@earendil-works/pi-tui";

const ORIGINALS_KEY: unique symbol = Symbol.for("dotfiles.pi.vim-model-selector.originals");
const DOWN_KEY: string = "\x1b[B";
const UP_KEY: string = "\x1b[A";
const REVERSE_VIDEO_PATTERN: RegExp = /\x1b\[(?:7|27)m/g;

const NORMAL_MODE_BINDINGS: readonly Keybinding[] = [
    "tui.select.up",
    "tui.select.down",
    "tui.select.confirm",
    "tui.select.cancel",
    "tui.input.tab",
    "app.models.save",
];

type VimMode = "normal" | "insert";

type SelectorState = {
    mode: VimMode;
    label: Text;
};

type InputHandler = (this: ModelSelectorComponent, data: string) => void;
type RenderHandler = (this: ModelSelectorComponent, width: number) => string[];

type OriginalMethods = {
    handleInput: InputHandler;
    render: RenderHandler;
    ownsRender: boolean;
};

type PatchablePrototype = {
    handleInput: InputHandler;
    render: RenderHandler;
    [ORIGINALS_KEY]?: OriginalMethods;
};

// SAFETY: Pi exports this component class, and its prototype owns handleInput and inherits render from Container.
const prototype: PatchablePrototype = ModelSelectorComponent.prototype as unknown as PatchablePrototype;
const selectorStates: WeakMap<ModelSelectorComponent, SelectorState> = new WeakMap<ModelSelectorComponent, SelectorState>();
let activeUi: ExtensionUIContext | undefined;

const renderModeLabel = (mode: VimMode): string => {
    const name: string = mode === "normal" ? "NORMAL" : "INSERT";
    const help: string = mode === "normal"
        ? "j/k move · i search · enter select · esc cancel"
        : "type to filter · esc normal mode";
    const theme: Theme | undefined = activeUi?.theme;
    if (!theme) {
        return `  ${name}  ${help}`;
    }
    const color: ThemeColor = mode === "normal" ? "accent" : "success";
    return `  ${theme.fg(color, theme.bold(name))}  ${theme.fg("dim", help)}`;
};

const hideCursorInNormalMode = (input: Input, state: SelectorState): void => {
    const renderInput: (width: number) => string[] = input.render;
    input.render = (width: number): string[] => {
        const lines: string[] = renderInput.call(input, width);
        if (state.mode === "insert") {
            return lines;
        }
        return lines.map((line: string): string => {
            return line.replaceAll(CURSOR_MARKER, "").replace(REVERSE_VIDEO_PATTERN, "");
        });
    };
};

const getSelectorState = (selector: ModelSelectorComponent): SelectorState => {
    const existing: SelectorState | undefined = selectorStates.get(selector);
    if (existing) {
        return existing;
    }

    const input: Input = selector.getSearchInput();
    const state: SelectorState = { mode: "normal", label: new Text("", 0, 0) };
    const inputIndex: number = selector.children.indexOf(input);
    const labelIndex: number = inputIndex >= 0 ? inputIndex + 1 : selector.children.length;
    selector.children.splice(labelIndex, 0, state.label);
    hideCursorInNormalMode(input, state);
    selectorStates.set(selector, state);
    return state;
};

const createHandleInput = (original: InputHandler): InputHandler => {
    return function (this: ModelSelectorComponent, data: string): void {
        const state: SelectorState = getSelectorState(this);

        if (state.mode === "insert") {
            if (matchesKey(data, Key.escape)) {
                state.mode = "normal";
                return;
            }
            original.call(this, data);
            return;
        }

        if (matchesKey(data, "i")) {
            state.mode = "insert";
            return;
        }
        if (matchesKey(data, "j")) {
            original.call(this, DOWN_KEY);
            return;
        }
        if (matchesKey(data, "k")) {
            original.call(this, UP_KEY);
            return;
        }

        const keybindings: KeybindingsManager = getKeybindings();
        const isSelectorAction: boolean = NORMAL_MODE_BINDINGS.some((binding: Keybinding): boolean => {
            return keybindings.matches(data, binding);
        });
        if (isSelectorAction) {
            original.call(this, data);
        }
    };
};

const createRender = (original: RenderHandler): RenderHandler => {
    return function (this: ModelSelectorComponent, width: number): string[] {
        const state: SelectorState = getSelectorState(this);
        state.label.setText(renderModeLabel(state.mode));
        return original.call(this, width);
    };
};

const restoreModelSelector = (): void => {
    const originals: OriginalMethods | undefined = prototype[ORIGINALS_KEY];
    if (!originals) {
        return;
    }
    prototype.handleInput = originals.handleInput;
    if (originals.ownsRender) {
        prototype.render = originals.render;
    } else {
        Reflect.deleteProperty(prototype, "render");
    }
    Reflect.deleteProperty(prototype, ORIGINALS_KEY);
};

const patchModelSelector = (): void => {
    restoreModelSelector();
    const originals: OriginalMethods = {
        handleInput: prototype.handleInput,
        render: prototype.render,
        ownsRender: Object.hasOwn(prototype, "render"),
    };
    prototype[ORIGINALS_KEY] = originals;
    prototype.handleInput = createHandleInput(originals.handleInput);
    prototype.render = createRender(originals.render);
};

const vimModelSelector = (pi: ExtensionAPI): void => {
    pi.on("session_start", (_event: SessionStartEvent, ctx: ExtensionContext): void => {
        if (ctx.mode !== "tui") {
            return;
        }
        activeUi = ctx.ui;
        patchModelSelector();
    });

    pi.on("session_shutdown", (): void => {
        restoreModelSelector();
        activeUi = undefined;
    });
};

export default vimModelSelector;
