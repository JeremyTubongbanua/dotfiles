return {
  init_options = {
    onlyAnalyzeProjectsWithOpenFiles = false -- will open any file, even if unanalyzed
  },
  settings = {
    dart = {
      updateImportsOnRename = true -- updates the imports on rename
    }
  },
}
