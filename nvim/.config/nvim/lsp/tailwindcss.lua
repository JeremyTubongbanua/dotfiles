return {
  settings = {
    tailwindCSS = {
      classFunctions = { 'cn', 'clsx', 'cx', 'cva', 'tw', 'twMerge' },
    },
  },
  -- Only attach where tailwind is actually used: a tailwind/postcss config, or
  -- a package.json that depends on tailwindcss. Without this it attaches to
  -- every html/css/jsx file in any git repo.
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    if fname == '' then
      return
    end
    local config = vim.fs.find({
      'tailwind.config.js', 'tailwind.config.cjs', 'tailwind.config.mjs', 'tailwind.config.ts',
      'postcss.config.js', 'postcss.config.cjs', 'postcss.config.mjs', 'postcss.config.ts',
    }, { path = fname, upward = true })[1]
    if config then
      on_dir(vim.fs.dirname(config))
      return
    end
    local pkgs = vim.fs.find('package.json', { path = fname, upward = true, limit = math.huge })
    for _, pkg in ipairs(pkgs) do
      local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(pkg), '\n'))
      if ok and type(data) == 'table' then
        for _, field in ipairs({ 'dependencies', 'devDependencies', 'peerDependencies' }) do
          if type(data[field]) == 'table' and data[field].tailwindcss then
            on_dir(vim.fs.dirname(pkg))
            return
          end
        end
      end
    end
  end,
}
