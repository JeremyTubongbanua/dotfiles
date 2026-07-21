-- claude-ref
-- Copy a "path:line-range" reference to the system clipboard, formatted for
-- pasting into Claude Code so you can ask about a specific chunk of code.
-- `file_path:line` is the native format Claude uses to cite code, so it
-- resolves the reference directly.

local M = {}

-- Buffer path relative to nvim's working directory (where you launched nvim).
-- e.g. launched in packages/website, editing packages/website/vite.config.ts
-- -> "vite.config.ts".
local function relative_path()
  local rel = vim.fn.expand("%:.")
  if rel == "" then
    return nil
  end
  return rel
end

-- Start/end line of the current visual selection. Valid while still in visual
-- mode, which is the case when an `x`-mode mapping fires.
local function visual_range()
  local a = vim.fn.line("v")
  local b = vim.fn.line(".")
  if a > b then
    a, b = b, a
  end
  return a, b
end

-- e.g. "vite.config.ts:5-7", or "vite.config.ts:5" for a single line.
local function make_ref(path, a, b)
  if a == b then
    return string.format("%s:%d", path, a)
  end
  return string.format("%s:%d-%d", path, a, b)
end

local function copy(text)
  vim.fn.setreg("+", text) -- system clipboard (also '"' for in-editor paste)
  vim.fn.setreg('"', text)
  vim.notify(text, vim.log.levels.INFO, { title = "claude-ref" })
end

-- visual: copy the `@path start-end` reference for the selection.
function M.yank_range_ref()
  local path = relative_path()
  if not path then
    vim.notify("No file name for this buffer", vim.log.levels.WARN, { title = "claude-ref" })
    return
  end
  local a, b = visual_range()
  copy(make_ref(path, a, b))
end

return M
