-- Completion plugin
-- Ctrl-n for next item
-- Ctrl-p for previous item
-- Ctrl-space to open completion menu
-- Ctrl-e to close completion menu
-- Ctrl-y to accept completion
--- @type LazyPluginSpec
return {
  'saghen/blink.cmp',
  version = '1.*',
  opts = {
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    keymap = { preset = 'default' },

    -- (Default) Only show the documentation popup when manually triggered
    completion = {
      documentation = {
        auto_show = false
      }
    },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      default = {
        'lsp',
        'path',
        'snippets',
        'buffer',
        'lazydev',
      },
      providers = {
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          score_offset = 100,
        },
      },
    },

    fuzzy = {
      implementation = "prefer_rust_with_warning"
    }
  },
  opts_extend = {
    "sources.default"
  }
}
