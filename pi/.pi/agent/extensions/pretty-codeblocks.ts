import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import {
  Markdown,
  type MarkdownTheme,
  visibleWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";

const PATCHED = Symbol.for("vlad.pi.pretty-codeblocks.patched");
const ORIGINAL = Symbol.for("vlad.pi.pretty-codeblocks.originalRenderToken");
const ORIGINAL_RENDER = Symbol.for("vlad.pi.pretty-codeblocks.originalRender");
const RESET = "\x1b[0m";

type CodeToken = {
  type?: string;
  lang?: string;
  text?: string;
};

type RenderToken = (
  token: CodeToken,
  width: number,
  nextTokenType?: string,
  styleContext?: unknown,
) => string[];

type MarkdownInternals = {
  theme: MarkdownTheme;
  defaultTextStyle?: { bgColor?: (text: string) => string };
  renderToken: RenderToken;
  render: (width: number) => string[];
  [key: symbol]: unknown;
};

let activeTheme: Theme | undefined;

const getBackground: () => string = () => activeTheme?.getBgAnsi("toolPendingBg") ?? "";
// Default is full-width because it looks like Pi's own user/tool blocks.
// Set PI_PRETTY_CODEBLOCKS_COMPACT=1 before starting pi for copy-friendly
// non-padded code lines instead.
// Set PI_PRETTY_CODEBLOCKS_BOX=1 before starting pi to use the decorative box.
// Set PI_PRETTY_CODEBLOCKS_LANG=0 to hide the language label.
const FULL_WIDTH = process.env.PI_PRETTY_CODEBLOCKS_COMPACT !== "1";
const BOX_STYLE = process.env.PI_PRETTY_CODEBLOCKS_BOX === "1";
const SHOW_LANG_LABEL = process.env.PI_PRETTY_CODEBLOCKS_LANG !== "0";

function repeat(char: string, count: number): string {
  return char.repeat(Math.max(0, count));
}

function applyBackground(line: string, width: number): string {
  const background: string = getBackground();
  const pad = repeat(" ", width - visibleWidth(line));
  // Syntax highlighters emit resets. Re-apply the background after each reset so the
  // block stays visually solid across colored spans.
  return background + line.replace(/\x1b\[0m/g, RESET + background) + pad + RESET;
}

function applyInlineBackground(line: string, width: number): string {
  if (FULL_WIDTH) return applyBackground(line, width);
  const background: string = getBackground();
  // Compact/copy-friendly mode: no decorative characters and no padding.
  // Empty lines still get one background cell so the block doesn't visually split.
  if (!line) return background + " " + RESET;
  return background + line.replace(/\x1b\[0m/g, RESET + background) + RESET;
}

function styledBorder(markdownTheme: MarkdownTheme, text: string): string {
  return markdownTheme.codeBlockBorder(text);
}

function isShellLang(lang?: string): boolean {
  return /^(bash|sh|shell|zsh|fish|powershell|ps1)$/i.test(String(lang || ""));
}

function highlightShellLine(line: string): string {
  if (!line) return line;
  if (/^\s*#/.test(line)) return activeTheme?.fg("syntaxComment", line) ?? line;
  // Lightweight shell highlighting: color command words at start of a command
  // segment. This catches `npm`, `curl`, commands after pipes/&&/||/; without
  // trying to fully parse shell syntax.
  return line
    .replace(
      /(^|[|&;]\s*)([A-Za-z0-9_./-]+)/g,
      (_match: string, prefix: string, command: string) =>
        `${prefix}${activeTheme?.fg("syntaxFunction", command) ?? command}`,
    )
    .replace(
      /(\s)(--?[A-Za-z0-9][A-Za-z0-9-_]*)/g,
      (_match: string, prefix: string, flag: string) =>
        `${prefix}${activeTheme?.fg("syntaxVariable", flag) ?? flag}`,
    );
}

function codeLines(markdownTheme: MarkdownTheme, code: string, lang?: string): string[] {
  if (isShellLang(lang)) return code.split("\n").map(highlightShellLine);
  if (markdownTheme.highlightCode) return markdownTheme.highlightCode(code, lang);
  return code.split("\n").map(markdownTheme.codeBlock);
}

function renderPrettyCodeBlock(
  markdown: MarkdownInternals,
  token: CodeToken,
  width: number,
  nextTokenType?: string,
): string[] {
  const markdownTheme: MarkdownTheme = markdown.theme;
  const lang: string = String(token.lang || "").trim();

  if (!BOX_STYLE) {
    const out: string[] = [];
    if (SHOW_LANG_LABEL && lang) {
      // Header is intentionally not background-filled, so the code background
      // itself remains visually distinct and copy stays simple.
      out.push(styledBorder(markdownTheme, ` ${lang} `));
    }
    for (const rawLine of codeLines(markdownTheme, token.text || "", lang || undefined)) {
      const wrapped = wrapTextWithAnsi(rawLine, Math.max(1, width));
      for (const part of wrapped.length ? wrapped : [""]) {
        out.push(applyInlineBackground(part, width));
      }
    }
    if (nextTokenType && nextTokenType !== "space") out.push("");
    return out;
  }

  const blockWidth = Math.max(12, width);
  const innerWidth = Math.max(1, blockWidth - 4);
  const title = lang ? ` ${lang} ` : "";

  const topVisible = "╭" + "─" + title;
  const top = styledBorder(markdownTheme, topVisible + repeat("─", blockWidth - visibleWidth(topVisible) - 1) + "╮");
  const bottom = styledBorder(markdownTheme, "╰" + repeat("─", blockWidth - 2) + "╯");
  const left = styledBorder(markdownTheme, "│ ");
  const right = styledBorder(markdownTheme, " │");

  const out: string[] = [applyBackground(top, blockWidth)];
  for (const rawLine of codeLines(markdownTheme, token.text || "", lang || undefined)) {
    const wrapped = wrapTextWithAnsi(rawLine || " ", innerWidth);
    for (const part of wrapped.length ? wrapped : [""]) {
      const padded = part + repeat(" ", innerWidth - visibleWidth(part));
      out.push(applyBackground(left + padded + right, blockWidth));
    }
  }
  out.push(applyBackground(bottom, blockWidth));

  if (nextTokenType && nextTokenType !== "space") out.push("");
  return out;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, context) => {
    activeTheme = context.ui.theme;
  });

  const proto: MarkdownInternals = Markdown.prototype as unknown as MarkdownInternals;

  // /reload runs extensions again in the same process. If an older version of
  // this patch is already installed, restore Pi's original methods first so
  // changes to this file are actually reapplied.
  if (proto[PATCHED] === true) {
    const previousRenderToken: RenderToken | undefined = proto[ORIGINAL] as RenderToken | undefined;
    const previousRender: ((width: number) => string[]) | undefined = proto[ORIGINAL_RENDER] as
      | ((width: number) => string[])
      | undefined;
    if (previousRenderToken) proto.renderToken = previousRenderToken;
    if (previousRender) proto.render = previousRender;
    proto[PATCHED] = false;
  }

  const originalRenderToken: RenderToken = proto.renderToken;
  const originalRender: (width: number) => string[] = proto.render;
  proto[ORIGINAL] = originalRenderToken;
  proto[ORIGINAL_RENDER] = originalRender;

  proto.renderToken = function patchedRenderToken(
    token: CodeToken,
    width: number,
    nextTokenType?: string,
    styleContext?: unknown,
  ): string[] {
    if (token.type === "code") {
      return renderPrettyCodeBlock(this, token, width, nextTokenType);
    }
    return originalRenderToken.call(this, token, width, nextTokenType, styleContext);
  };

  proto.render = function patchedRender(width: number): string[] {
    const lines: string[] = originalRender.call(this, width);
    // Pi's Markdown pads lines to the full terminal width. That looks OK, but it
    // makes copied code blocks include hundreds of trailing spaces. For Markdown
    // without an explicit block background, trim only the final literal spaces.
    if (this.defaultTextStyle?.bgColor) return lines;
    return lines.map((line: string) => line.trimEnd());
  };

  proto[PATCHED] = true;
}
