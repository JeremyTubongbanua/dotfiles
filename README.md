# dotfiles

My personal dotfiles

## Tracking Future Files

This repo mirrors files from my home directory using paths relative to `$HOME`,
but it removes the leading `.` from hidden files and folders. For example,
`~/.zshrc` is tracked here as `zshrc`, `~/.codex` is tracked here as `codex/`,
and `~/.config/nvim/init.lua` is tracked here as `config/nvim/init.lua`.

To add a new file:

1. Create the matching folder path in this repo.
2. If the source path starts with `.`, remove that leading dot in the repo path.
3. Copy the file into that path.
4. Review the file for secrets, credentials, machine-specific paths, and other
   private values before tracking it.
5. Run a quick smoke check for the tool the file configures.
6. Review the diff with `git diff`.

Example:

```sh
mkdir -p config/example
cp ~/.config/example/settings.toml config/example/settings.toml
git diff -- config/example/settings.toml
```

When adding a top-level hidden file or folder, track it without the leading dot.
For example, files from `~/.codex` should go under `codex/`, and `~/.zshrc`
should be tracked as `zshrc`.

Do not track generated caches, local state, package installs, or secret files.
Prefer documenting how to recreate those files instead.
