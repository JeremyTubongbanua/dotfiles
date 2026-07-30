#!/usr/bin/env zsh
#
# Prompt for a directory and a workspace name, then build a 3-tab workspace:
#
#   tab 1  "sh"      shell in <dir>
#   tab 2  "nvim"    shell in <dir>, runs nvim
#   tab 3  "claude"  shell in <dir>, left idle for `claude` / `claude-work`
#
# Bound in config.toml as a [[keys.command]] popup. Tab completes directories,
# Ctrl+C cancels.

emulate -L zsh
setopt err_exit pipe_fail

autoload -Uz compinit
compinit -u -d "${XDG_CACHE_HOME:-$HOME/.cache}/herdr-zcompdump"
zstyle ':completion:*' file-patterns '*(-/):directories'

dir="$HOME/GitHub/"
vared -p 'workspace dir: ' dir

dir="${~dir}"
dir="${dir:A}"
if [[ ! -d $dir ]]; then
  print -u2 -- "not a directory: $dir"
  read -k1 -s
  exit 1
fi

label="${dir:t}"
vared -p 'workspace name: ' label

ws_json="$(herdr workspace create --cwd "$dir" --label "$label" --focus)"
ws_id="$(print -r -- "$ws_json" | jq -r '.result.workspace.workspace_id')"
sh_tab="$(print -r -- "$ws_json" | jq -r '.result.tab.tab_id')"

herdr tab rename "$sh_tab" sh >/dev/null

nvim_json="$(herdr tab create --workspace "$ws_id" --cwd "$dir" --label nvim --no-focus)"
nvim_pane="$(print -r -- "$nvim_json" | jq -r '.result.root_pane.pane_id')"
herdr pane run "$nvim_pane" nvim >/dev/null

herdr tab create --workspace "$ws_id" --cwd "$dir" --label claude --no-focus >/dev/null

herdr tab focus "$sh_tab" >/dev/null
