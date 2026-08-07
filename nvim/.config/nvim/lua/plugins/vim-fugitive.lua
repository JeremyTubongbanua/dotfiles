-- no opts/config: fugitive is vimscript, there is no lua module and no setup()
-- is this window showing a fugitive buffer? used by <leader>gq
local is_fugitive = function(win)
  return vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)):match('^fugitive://') ~= nil
end

local git = function(root, args)
  local out = vim.fn.systemlist(vim.list_extend({ 'git', '-C', root }, args))
  if vim.v.shell_error ~= 0 then return nil end
  return out
end

local git_root = function()
  local dir = vim.bo.buftype == '' and vim.fn.expand('%:p:h') or ''
  if dir == '' then dir = vim.fn.getcwd() end
  local out = vim.fn.systemlist({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' })
  if vim.v.shell_error ~= 0 then return nil end
  return out[1]
end

-- the branch a PR would target, not `@{upstream}`: a pushed jt/<feature> tracks
-- itself, which would hide everything already pushed
local base_branch = function(root)
  local remotes = git(root, { 'remote' })
  if not remotes or #remotes == 0 then return nil, 'no git remotes' end

  local remote = remotes[1]
  if vim.tbl_contains(remotes, 'upstream') then
    remote = 'upstream'
  elseif vim.tbl_contains(remotes, 'origin') then
    remote = 'origin'
  end

  -- `trunk` is tried before refs/remotes/<remote>/HEAD because that ref goes stale:
  -- this repo's still points at a dead `main` holding only the initial commit
  local candidates = { 'trunk' }
  local head = git(root, { 'symbolic-ref', '--short', 'refs/remotes/' .. remote .. '/HEAD' })
  if head and head[1] then
    candidates[#candidates + 1] = head[1]:gsub('^' .. vim.pesc(remote) .. '/', '')
  end
  vim.list_extend(candidates, { 'main', 'master' })

  for _, branch in ipairs(candidates) do
    local ref = remote .. '/' .. branch
    if git(root, { 'rev-parse', '--verify', '--quiet', ref .. '^{commit}' }) then return ref end
  end
  return nil, 'no trunk/main/master on ' .. remote
end

local changed_files = function(root, base)
  local out = git(root, { '-c', 'core.quotePath=false', 'diff', '--name-status', base })
  if not out then return nil end

  local items = {}
  for _, line in ipairs(out) do
    local fields = vim.split(line, '\t')
    local status = fields[1]:sub(1, 1)
    local path = fields[#fields]
    items[#items + 1] = {
      status = status,
      path = path,
      before = status == 'R' and fields[2] or path, -- a rename's base side lives at the old path
      file = root .. '/' .. path,
      text = path,
    }
  end

  -- untracked files never appear in `git diff`
  for _, path in ipairs(git(root, { '-c', 'core.quotePath=false', 'ls-files', '--others', '--exclude-standard' }) or {}) do
    items[#items + 1] = { status = '?', path = path, file = root .. '/' .. path, text = path }
  end

  table.sort(items, function(a, b) return a.path < b.path end)
  return items
end

local state = nil

local open_diff = function(item, edit)
  if edit then vim.cmd('edit ' .. vim.fn.fnameescape(item.file)) end
  if item.status == 'A' or item.status == '?' then
    vim.notify(item.path .. ' is new, nothing to diff in ' .. state.ref, vim.log.levels.INFO)
    return
  end
  local object = state.base .. ':' .. item.before
  local ok, err = pcall(vim.cmd, 'leftabove Gvdiffsplit! ' .. vim.fn.fnameescape(object))
  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
  end
end

local close_base_wins = function()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff and is_fugitive(win) then
      pcall(vim.api.nvim_win_close, win, false) -- non-force, same as <leader>gq
    end
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then vim.wo[win].diff = false end
  end
end

-- re-split after any quickfix motion, but only while the list is still a <leader>gD one
local goto_entry = function(cmd, fallback)
  if vim.fn.getqflist({ size = 0 }).size == 0 then
    vim.notify('quickfix list is empty', vim.log.levels.WARN)
    return
  end

  local reviewing = state ~= nil and vim.fn.getqflist({ title = 0 }).title == state.title
  if reviewing then close_base_wins() end

  if not pcall(vim.cmd, cmd) and fallback then
    if not pcall(vim.cmd, fallback) then return end
  end

  if reviewing then
    local item = state.by_file[vim.api.nvim_buf_get_name(0)]
    if item then open_diff(item, false) end
  end
end

local qf_confirm = function()
  goto_entry('cc ' .. vim.fn.line('.'))
end

local start_review = function(root, ref)
  local merge_base = git(root, { 'merge-base', 'HEAD', ref })
  local base = merge_base and merge_base[1] or ref

  local items = changed_files(root, base)
  if not items or #items == 0 then
    vim.notify('no changes against ' .. ref, vim.log.levels.INFO)
    return
  end

  local title = 'Diff vs ' .. ref
  state = { root = root, ref = ref, base = base, title = title, by_file = {} }
  for _, item in ipairs(items) do
    state.by_file[item.file] = item
  end

  local qf = {}
  for _, item in ipairs(items) do
    qf[#qf + 1] = { filename = item.file, lnum = 1, text = item.status } -- filename column already shows the path
  end
  vim.fn.setqflist({}, ' ', { title = title, items = qf })
  vim.cmd('copen')

  for _, lhs in ipairs({ '<CR>', '<2-LeftMouse>' }) do
    vim.keymap.set('n', lhs, qf_confirm, { buffer = 0, desc = 'Git Review Open Diff' })
  end
end

local review = function()
  local root = git_root()
  if not root then
    vim.notify('not in a git repository', vim.log.levels.WARN)
    return
  end

  vim.ui.input({
    prompt = 'Diff against: ',
    default = base_branch(root) or '',
    completion = 'customlist,fugitive#CompleteObject',
  }, function(input)
    if not input then return end
    local ref = vim.trim(input)
    if ref == '' then return end
    if not git(root, { 'rev-parse', '--verify', '--quiet', ref .. '^{commit}' }) then
      vim.notify('no such revision: ' .. ref, vim.log.levels.WARN)
      return
    end
    start_review(root, ref)
  end)
end

local nav = function(step)
  if step > 0 then
    goto_entry('cnext', 'cfirst') -- wrap at the end of the list
  else
    goto_entry('cprevious', 'clast')
  end
end

---@type LazyPluginSpec
return {
  'tpope/vim-fugitive',
  -- no version pin: the newest tag (v3.7, 2022) is ~200 commits behind master and
  -- predates `P` pushing from the Unpushed section (s:StagePatch)
  lazy = false, -- must load early
  keys = {
    { '<leader>gg', ':Git<CR>', desc = 'Git Status' }, -- opens fugitive
    { '<leader>gd', ':Gvdiffsplit!<CR>', desc = 'Git Diff Split' }, -- create a three-way vertical split. Left = feature branch (//2), Middle = current file, Right = merging branch (//3)
    { '<leader>gD', review, desc = 'Git Review vs Base Branch' }, -- pick a changed file, get base (left) vs work tree (right)
    -- n: blame the whole file, scrollbound to this window. x: Vim auto-prepends '<,'>,
    -- and fugitive restricts blame to just that range (own split, no scrollbind) when a range is given
    { '<leader>gb', ':Git blame<CR>', mode = { 'n', 'x' }, desc = 'Git Blame' },
    { ']q', function() nav(1) end, desc = 'Quickfix Next' },
    { '[q', function() nav(-1) end, desc = 'Quickfix Previous' },
    { '<leader>gh', ':diffget //2<CR>', mode = { 'n', 'x' }, desc = 'Git Diff Get Left' }, -- get changes from the left side where your cursor or selection is. Cursor must be in the middle buffer.
    { '<leader>gl', ':diffget //3<CR>', mode = { 'n', 'x' }, desc = 'Git Diff Get Right' }, -- get changes from the right side where your cursor or selection is. Cursor must be in the middle buffer.
    {
      '<leader>gq',
      function()
        local wins = vim.api.nvim_tabpage_list_wins(0)
        if is_fugitive(vim.api.nvim_get_current_win()) then
          local target = nil
          for _, win in ipairs(wins) do
            if not is_fugitive(win) then
              target = target or win
              if vim.wo[win].diff then
                target = win
                break
              end
            end
          end
          if target then vim.api.nvim_set_current_win(target) end
        end
        local cur = vim.api.nvim_get_current_win()
        for _, win in ipairs(wins) do
          if win ~= cur and vim.api.nvim_win_is_valid(win) and is_fugitive(win) then
            vim.api.nvim_win_close(win, false) -- non-force: refuses rather than discarding unsaved edits
          end
        end
      end,
      desc = 'Git Diff Quit',
    },
  },
}
