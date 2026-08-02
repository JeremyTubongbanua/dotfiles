return {
  root_markers = { 'biome.json', 'biome.jsonc' },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    if fname == '' then
      return
    end
    local config = vim.fs.find({ 'biome.json', 'biome.jsonc' }, { path = fname, upward = true })[1]
    if config then
      on_dir(vim.fs.dirname(config))
    end
  end,
}
