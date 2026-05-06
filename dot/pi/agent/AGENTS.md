# Pi Agent Instructions

## TLDR;

This document outlines how pi should be used. Keep responses concise, make targeted edits, and verify changes with a small smoke test when practical.

## Global Operating Preferences

- Prefer reading existing files before changing them.
- Explain assumptions briefly when the request is ambiguous.
- Make the smallest safe change that satisfies the request.
- Show changed file paths clearly in final responses.
- Do not expose or copy secrets, tokens, API keys, local credentials, or private machine state into tracked files.
- When editing dotfiles or agent config, preserve existing user intent and avoid deleting unrelated settings.

## General

- Do a smoke test everytime you implement something. This means that you should test the general functionality of the system,
even if it is not testing the feature itself. Check quickly for compilation errors.

## Git

- Do not `git add`, `git commit` or `git push`. I will usually do those myself, unless I explicitly ask you to do so.
- Everytime you make changes to any dotfiles in my home directory, ensure you update ~/GitHub/dotfiles which is where I like to keep track and persist my dotfiles setup. Read the documentation in that repo to ensure you are modifying it correctly. I will commit/push things myself in the dotfiles repo, you just have to make sure that the changes are properly tracked so it is easy for me to decide if I should push.

## Future Home Dotfiles

- Track future hidden home files and folders under `dot/` without the leading dot. For example, `~/.codex` is tracked in `dot/codex/`, so `~/.claude` should be tracked in `dot/claude/`.
- Use `./install.sh` to activate tracked paths. If adding a new path, add a matching `link_path` entry there so the README inventory and link checker can detect it automatically.
- If creating a link manually, point from the home directory to the `dot/` path in this repo. Example:

```sh
ln -s "$PWD/dot/claude" "$HOME/.claude"
```

- If the home folder already exists, do not overwrite it blindly. Move or copy the existing files into the repo folder first, review them for secrets, then replace the home folder with the symlink.
- Do not track machine-local secrets, caches, logs, or generated state. Add those paths to the folder's `.gitignore` before committing.
- After adding or changing a folder, run a quick smoke test for the relevant tool to confirm the symlinked config still loads.

## Dart

- After Dart or Flutter code changes, run the narrowest useful check, such as `dart analyze`, `flutter analyze`, a targeted test, or a smoke command.
- Prefer idiomatic Dart with clear names, null-safety, and simple control flow.
- Add or update tests when changing behavior, especially for bug fixes.
