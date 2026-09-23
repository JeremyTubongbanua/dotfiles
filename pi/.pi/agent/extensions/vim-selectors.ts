import {
    ModelSelectorComponent,
    SessionSelectorComponent,
    ThinkingSelectorComponent,
    TreeSelectorComponent,
    type ExtensionAPI,
    type ExtensionContext,
    type ExtensionUIContext,
    type SessionStartEvent,
    type Theme,
    type ThemeColor,
} from "@earendil-works/pi-coding-agent";
import {
    Container,
    CURSOR_MARKER,
    decodeKittyPrintable,
    getKeybindings,
    Input,
    Key,
    matchesKey,
    SettingsList,
    Text,
    type Component,
    type Keybinding,
    type KeybindingsManager,
} from "@earendil-works/pi-tui";

const ORIGINALS_KEY: unique symbol = Symbol.for("dotfiles.pi.vim-selectors.originals");
const ADD_CHILD_KEY: unique symbol = Symbol.for("dotfiles.pi.vim-selectors.add-child");
const REGISTRY_KEY: unique symbol = Symbol.for("dotfiles.pi.vim-selectors.registry");
const SCOPED_MODELS_SELECTOR_NAME: string = "ScopedModelsSelectorComponent";
const TREE_SEARCH_LINE_NAME: string = "SearchLine";
const DOWN_KEY: string = "\x1b[B";
const UP_KEY: string = "\x1b[A";
const ENTER_KEY: string = "\r";
const PASTE_START: string = "\x1b[200~";
const REVERSE_VIDEO_PATTERN: RegExp = /\x1b\[(?:7|27)m/g;

const TEXT_EDITING_BINDINGS: readonly Keybinding[] = [
    "tui.editor.deleteCharBackward",
    "tui.editor.deleteCharForward",
    "tui.editor.deleteWordBackward",
    "tui.editor.deleteWordForward",
    "tui.editor.deleteToLineStart",
    "tui.editor.deleteToLineEnd",
    "tui.editor.yank",
    "tui.editor.yankPop",
    "tui.editor.undo",
];

type VimMode = "normal" | "insert";

type SelectorState = {
    mode: VimMode;
    label: Text;
};

type SelectorComponent = Component & Record<string, unknown>;

type VimTarget = {
    normalHelp: string;
    normalBindings: readonly Keybinding[];
    normalRemaps: Readonly<Record<string, string>>;
    isActive: (component: SelectorComponent) => boolean;
    getInput: (component: SelectorComponent) => Input | undefined;
    placeLabel: (component: SelectorComponent, label: Text) => void;
    decorateRender?: (component: SelectorComponent, lines: string[], labelLines: string[]) => string[];
};

type InputHandler = (this: SelectorComponent, data: string) => void;
type RenderHandler = (this: SelectorComponent, width: number) => string[];
type AddChildHandler = (this: Container, component: Component) => void;

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

type PatchableContainerPrototype = {
    addChild: AddChildHandler;
    [ADD_CHILD_KEY]?: AddChildHandler;
};

type PatchRegistry = {
    [REGISTRY_KEY]?: Set<PatchablePrototype>;
};

// SAFETY: ModelSelectorComponent owns handleInput and inherits render from Container.
const modelSelectorPrototype: PatchablePrototype = ModelSelectorComponent.prototype as unknown as PatchablePrototype;
// SAFETY: TreeSelectorComponent owns handleInput and inherits render from Container.
const treeSelectorPrototype: PatchablePrototype = TreeSelectorComponent.prototype as unknown as PatchablePrototype;
// SAFETY: SettingsList owns handleInput and render in pi-tui.
const settingsListPrototype: PatchablePrototype = SettingsList.prototype as unknown as PatchablePrototype;
// SAFETY: SessionSelectorComponent owns handleInput and inherits render from Container.
const sessionSelectorPrototype: PatchablePrototype = SessionSelectorComponent.prototype as unknown as PatchablePrototype;
// SAFETY: ThinkingSelectorComponent owns handleInput and inherits render from Container.
const thinkingSelectorPrototype: PatchablePrototype = ThinkingSelectorComponent.prototype as unknown as PatchablePrototype;
// SAFETY: Container owns addChild in pi-tui, and every Pi selector is added through it.
const containerPrototype: PatchableContainerPrototype = Container.prototype as unknown as PatchableContainerPrototype;

const selectorStates: WeakMap<SelectorComponent, SelectorState> = new WeakMap<SelectorComponent, SelectorState>();
let activeUi: ExtensionUIContext | undefined;

const getRegistry = (): Set<PatchablePrototype> => {
    // SAFETY: globalThis survives extension reloads, so a reloaded module can restore earlier patches.
    const holder: PatchRegistry = globalThis as unknown as PatchRegistry;
    holder[REGISTRY_KEY] ??= new Set<PatchablePrototype>();
    return holder[REGISTRY_KEY];
};

const readField = <T>(component: SelectorComponent, field: string): T | undefined => {
    // SAFETY: reads private runtime fields of Pi components; callers treat undefined as absent.
    return component[field] as T | undefined;
};

const getOwnedSearchInput = (component: SelectorComponent): Input | undefined => {
    const searchInput: unknown = component["searchInput"];
    return searchInput instanceof Input ? searchInput : undefined;
};

const placeLabelAfter = (container: Container, anchor: Component | undefined, label: Text): void => {
    const anchorIndex: number = anchor ? container.children.indexOf(anchor) : -1;
    const labelIndex: number = anchorIndex >= 0 ? anchorIndex + 1 : container.children.length;
    container.children.splice(labelIndex, 0, label);
};

const appendLabelToInput = (input: Input | undefined, label: Text): void => {
    if (!input) {
        return;
    }
    const renderInput: (width: number) => string[] = input.render;
    input.render = (width: number): string[] => {
        return [...renderInput.call(input, width), ...label.render(width)];
    };
};

const placeLabelAfterSearchInput = (component: SelectorComponent, label: Text): void => {
    appendLabelToInput(getOwnedSearchInput(component), label);
};

const MODEL_SELECTOR_TARGET: VimTarget = {
    normalHelp: "j/k move · i search · enter select · esc cancel",
    normalBindings: [],
    normalRemaps: {},
    isActive: (): boolean => {
        return true;
    },
    getInput: getOwnedSearchInput,
    placeLabel: placeLabelAfterSearchInput,
};

const THINKING_SELECTOR_TARGET: VimTarget = {
    normalHelp: "j/k move \u00b7 i search \u00b7 enter select \u00b7 esc cancel",
    normalBindings: [],
    normalRemaps: {},
    isActive: (): boolean => {
        return true;
    },
    getInput: getOwnedSearchInput,
    placeLabel: placeLabelAfterSearchInput,
};

const SCOPED_MODELS_TARGET: VimTarget = {
    normalHelp: "j/k move · i search · enter toggle · esc cancel",
    normalBindings: [],
    normalRemaps: {},
    isActive: (): boolean => {
        return true;
    },
    getInput: getOwnedSearchInput,
    placeLabel: placeLabelAfterSearchInput,
};

const TREE_SELECTOR_TARGET: VimTarget = {
    normalHelp: "j/k move · i search · enter select · esc clear search or cancel",
    normalBindings: ["app.tree.editLabel", "app.tree.toggleLabelTimestamp"],
    normalRemaps: {},
    isActive: (component: SelectorComponent): boolean => {
        return readField<unknown>(component, "labelInput") == null;
    },
    getInput: (): Input | undefined => {
        return undefined;
    },
    placeLabel: (component: SelectorComponent, label: Text): void => {
        if (!(component instanceof Container)) {
            return;
        }
        const searchLine: Component | undefined = component.children.find((child: Component): boolean => {
            return child.constructor.name === TREE_SEARCH_LINE_NAME;
        });
        placeLabelAfter(component, searchLine, label);
    },
};

const SETTINGS_LIST_TARGET: VimTarget = {
    normalHelp: "j/k move · i search · enter/space change · esc cancel",
    normalBindings: [],
    normalRemaps: { " ": ENTER_KEY },
    isActive: (component: SelectorComponent): boolean => {
        const searchEnabled: boolean = readField<boolean>(component, "searchEnabled") === true;
        return searchEnabled && readField<unknown>(component, "submenuComponent") == null;
    },
    getInput: getOwnedSearchInput,
    placeLabel: (): void => {},
    decorateRender: (_component: SelectorComponent, lines: string[], labelLines: string[]): string[] => {
        return [...lines.slice(0, 1), ...labelLines, ...lines.slice(1)];
    },
};

const getSessionList = (component: SelectorComponent): SelectorComponent | undefined => {
    return readField<SelectorComponent>(component, "sessionList");
};

const getSessionSearchInput = (component: SelectorComponent): Input | undefined => {
    const sessionList: SelectorComponent | undefined = getSessionList(component);
    return sessionList ? getOwnedSearchInput(sessionList) : undefined;
};

const SESSION_SELECTOR_TARGET: VimTarget = {
    normalHelp: "j/k move \u00b7 i search \u00b7 enter resume \u00b7 esc cancel",
    normalBindings: ["app.session.deleteNoninvasive"],
    normalRemaps: {},
    isActive: (component: SelectorComponent): boolean => {
        const sessionList: SelectorComponent | undefined = getSessionList(component);
        const isConfirmingDelete: boolean = sessionList !== undefined && sessionList["confirmingDeletePath"] != null;
        return readField<string>(component, "mode") === "list" && !isConfirmingDelete;
    },
    getInput: getSessionSearchInput,
    placeLabel: (component: SelectorComponent, label: Text): void => {
        appendLabelToInput(getSessionSearchInput(component), label);
    },
};

const renderModeLabel = (mode: VimMode, target: VimTarget): string => {
    const name: string = mode === "normal" ? "NORMAL" : "INSERT";
    const help: string = mode === "normal" ? target.normalHelp : "type to filter · esc normal mode";
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

const getSelectorState = (component: SelectorComponent, target: VimTarget): SelectorState => {
    const existing: SelectorState | undefined = selectorStates.get(component);
    if (existing) {
        return existing;
    }

    const state: SelectorState = { mode: "insert", label: new Text("", 0, 0) };
    target.placeLabel(component, state.label);
    const input: Input | undefined = target.getInput(component);
    if (input) {
        hideCursorInNormalMode(input, state);
    }
    selectorStates.set(component, state);
    return state;
};

const isPrintable = (data: string): boolean => {
    if (decodeKittyPrintable(data) !== undefined) {
        return true;
    }
    return data.length > 0 && [...data].every((character: string): boolean => {
        const code: number = character.charCodeAt(0);
        return code >= 32 && code !== 0x7f && (code < 0x80 || code > 0x9f);
    });
};

const isTextEntry = (data: string, target: VimTarget): boolean => {
    const keybindings: KeybindingsManager = getKeybindings();
    const isAllowed: boolean = target.normalBindings.some((binding: Keybinding): boolean => {
        return keybindings.matches(data, binding);
    });
    if (isAllowed) {
        return false;
    }
    if (data.startsWith(PASTE_START)) {
        return true;
    }
    const isEditing: boolean = TEXT_EDITING_BINDINGS.some((binding: Keybinding): boolean => {
        return keybindings.matches(data, binding);
    });
    return isEditing || isPrintable(data);
};

const createHandleInput = (original: InputHandler, target: VimTarget): InputHandler => {
    return function (this: SelectorComponent, data: string): void {
        if (!target.isActive(this)) {
            original.call(this, data);
            return;
        }

        const state: SelectorState = getSelectorState(this, target);

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
        const remapped: string | undefined = target.normalRemaps[data];
        if (remapped !== undefined) {
            original.call(this, remapped);
            return;
        }
        if (isTextEntry(data, target)) {
            return;
        }
        original.call(this, data);
    };
};

const createRender = (original: RenderHandler, target: VimTarget): RenderHandler => {
    return function (this: SelectorComponent, width: number): string[] {
        if (!target.isActive(this)) {
            selectorStates.get(this)?.label.setText("");
            return original.call(this, width);
        }
        const state: SelectorState = getSelectorState(this, target);
        state.label.setText(renderModeLabel(state.mode, target));
        const lines: string[] = original.call(this, width);
        if (!target.decorateRender) {
            return lines;
        }
        return target.decorateRender(this, lines, state.label.render(width));
    };
};

const restorePrototype = (prototype: PatchablePrototype): void => {
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

const patchPrototype = (prototype: PatchablePrototype, target: VimTarget): void => {
    restorePrototype(prototype);
    const originals: OriginalMethods = {
        handleInput: prototype.handleInput,
        render: prototype.render,
        ownsRender: Object.hasOwn(prototype, "render"),
    };
    prototype[ORIGINALS_KEY] = originals;
    prototype.handleInput = createHandleInput(originals.handleInput, target);
    prototype.render = createRender(originals.render, target);
    getRegistry().add(prototype);
};

const captureScopedModelsSelector = (component: Component): void => {
    if (component.constructor.name !== SCOPED_MODELS_SELECTOR_NAME) {
        return;
    }
    // SAFETY: Pi does not export ScopedModelsSelectorComponent, so its prototype is taken from a live instance.
    const prototype: PatchablePrototype = Object.getPrototypeOf(component) as PatchablePrototype;
    if (Object.hasOwn(prototype, ORIGINALS_KEY)) {
        return;
    }
    patchPrototype(prototype, SCOPED_MODELS_TARGET);
};

const restoreAddChild = (): void => {
    const original: AddChildHandler | undefined = containerPrototype[ADD_CHILD_KEY];
    if (!original) {
        return;
    }
    containerPrototype.addChild = original;
    Reflect.deleteProperty(containerPrototype, ADD_CHILD_KEY);
};

const patchAddChild = (): void => {
    restoreAddChild();
    const original: AddChildHandler = containerPrototype.addChild;
    containerPrototype[ADD_CHILD_KEY] = original;
    containerPrototype.addChild = function (this: Container, component: Component): void {
        captureScopedModelsSelector(component);
        original.call(this, component);
    };
};

const restoreSelectors = (): void => {
    const registry: Set<PatchablePrototype> = getRegistry();
    for (const prototype of registry) {
        restorePrototype(prototype);
    }
    registry.clear();
    restoreAddChild();
};

const patchSelectors = (): void => {
    restoreSelectors();
    patchPrototype(modelSelectorPrototype, MODEL_SELECTOR_TARGET);
    patchPrototype(treeSelectorPrototype, TREE_SELECTOR_TARGET);
    patchPrototype(settingsListPrototype, SETTINGS_LIST_TARGET);
    patchPrototype(sessionSelectorPrototype, SESSION_SELECTOR_TARGET);
    patchPrototype(thinkingSelectorPrototype, THINKING_SELECTOR_TARGET);
    patchAddChild();
};

const vimSelectors = (pi: ExtensionAPI): void => {
    pi.on("session_start", (_event: SessionStartEvent, ctx: ExtensionContext): void => {
        if (ctx.mode !== "tui") {
            return;
        }
        activeUi = ctx.ui;
        patchSelectors();
    });

    pi.on("session_shutdown", (): void => {
        restoreSelectors();
        activeUi = undefined;
    });
};

export default vimSelectors;
