# Codex

## TLDR;

This document outlines how codex should be used.

## General

- Do a smoke test everytime you implement something. This means that you should test the general functionality of the system,
even if it is not testing the feature itself. Check quickly for compilation errors.

## Git

- Do not `git add`, `git commit` or `git push`. I will usually do those myself, unless I explicitly ask you to do so.

## Future Home Folders

- Track future dot folders as top-level folders without the leading dot. For example, `~/.codex` is tracked in `codex/`, so `~/.claude` should be tracked in `claude/`.
- Use a symlink from the home directory to this repo when activating a tracked folder. Example:

```sh
ln -s "$PWD/claude" "$HOME/.claude"
```

- If the home folder already exists, do not overwrite it blindly. Move or copy the existing files into the repo folder first, review them for secrets, then replace the home folder with the symlink.
- Do not track machine-local secrets, caches, logs, or generated state. Add those paths to the folder's `.gitignore` before committing.
- After adding or changing a folder, run a quick smoke test for the relevant tool to confirm the symlinked config still loads.

## Dart
