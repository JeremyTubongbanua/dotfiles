-- vtsls replaces ts_ls. It speaks VSCode setting names rather than the raw
-- tsserver protocol ones, so the tsserver-style tables are translated below --
-- note `suppressWhenArgumentMatchesName` is the inverse of the ts_ls key.
local ts_inlay_hints = {
  includeInlayParameterNameHints = 'literals', -- 'none' | 'literals' | 'all'
  includeInlayParameterNameHintsWhenArgumentMatchesName = false,
  includeInlayFunctionParameterTypeHints = true,
  includeInlayVariableTypeHints = false, -- noisy in TSX, most vars are obvious
  includeInlayPropertyDeclarationTypeHints = true,
  includeInlayFunctionLikeReturnTypeHints = true,
  includeInlayEnumMemberValueHints = true,
}

local ts_preferences = {
  importModuleSpecifier = 'shortest', -- respects tsconfig `paths` when shorter
  includeCompletionsForModuleExports = true, -- auto-import unimported symbols
  quotePreference = 'auto',
  jsxAttributeCompletionStyle = 'auto', -- fills `={}` / `=""` on JSX props
}

local vtsls_ts = {
  inlayHints = {
    parameterNames = {
      enabled = ts_inlay_hints.includeInlayParameterNameHints,
      suppressWhenArgumentMatchesName = not ts_inlay_hints
        .includeInlayParameterNameHintsWhenArgumentMatchesName,
    },
    parameterTypes = { enabled = ts_inlay_hints.includeInlayFunctionParameterTypeHints },
    variableTypes = { enabled = ts_inlay_hints.includeInlayVariableTypeHints },
    propertyDeclarationTypes = { enabled = ts_inlay_hints.includeInlayPropertyDeclarationTypeHints },
    functionLikeReturnTypes = { enabled = ts_inlay_hints.includeInlayFunctionLikeReturnTypeHints },
    enumMemberValues = { enabled = ts_inlay_hints.includeInlayEnumMemberValueHints },
  },
  preferences = {
    importModuleSpecifier = ts_preferences.importModuleSpecifier,
    quoteStyle = ts_preferences.quotePreference,
    jsxAttributeCompletionStyle = ts_preferences.jsxAttributeCompletionStyle,
  },
  suggest = {
    autoImports = ts_preferences.includeCompletionsForModuleExports,
    completeFunctionCalls = true,
  },
  updateImportsOnFileMove = { enabled = 'always' },
}

return {
  settings = { typescript = vtsls_ts, javascript = vtsls_ts },
}
