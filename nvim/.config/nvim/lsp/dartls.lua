-- The only server not installed by Mason -- it comes from the Dart SDK.
return {
  init_options = { onlyAnalyzeProjectsWithOpenFiles = false },
  settings = { dart = { updateImportsOnRename = true } },
}
