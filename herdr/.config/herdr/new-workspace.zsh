#!/usr/bin/env zsh
#
# Prompt for a directory and a workspace name, then build a 3-tab workspace:
#
#   tab 1  "sh"      shell in <dir>
#   tab 2  "nvim"    shell in <dir>, runs nvim
#   tab 3  "claude"  shell in <dir>, left idle for `claude` / `claude-work`
#
# <dir> is created if missing. If it sits inside a worktree collection -- i.e.
# ../trunk or ../../trunk is a checkout -- that trunk is pruned, fetched and
# reset --hard to upstream/trunk, then <dir> is added as a worktree before the
# tabs are built. The branch name is <dir> relative to the collection root, so
# ~/GitHub/atsign/noports/jt/feature -> jt/feature and .../jt-feature ->
# jt-feature.
#
# Bound in config.toml as a [[keys.command]] popup. Tab completes directories,
# Ctrl+C cancels.

emulate -L zsh
setopt err_exit pipe_fail

die() {
  print -u2 -- "$@"
  print -u2 -- '-- press any key --'
  read -k1 -s
  exit 1
}

autoload -Uz compinit
compinit -u -d "${XDG_CACHE_HOME:-$HOME/.cache}/herdr-zcompdump"
zstyle ':completion:*' file-patterns '*(-/):directories'

dir="$HOME/GitHub/"
vared -p 'workspace dir: ' dir

dir="${~dir}"
dir="${dir%/}"
dir="${dir:a}"
[[ -n $dir ]] || die 'no directory given'

label="${dir:t}"
vared -p 'workspace name: ' label
[[ -n $label ]] || die 'no workspace name given'

if [[ -d $dir ]]; then
  fresh=0
else
  fresh=1
  mkdir -p -- "$dir" || die "could not create: $dir"
fi
dir="${dir:A}"

# --- worktree collection? --------------------------------------------------

trunk=
if (( fresh )); then
  for cand in "${dir:h}/trunk" "${dir:h:h}/trunk"; do
    if [[ $cand != $dir && -e $cand/.git ]]; then
      trunk="$cand"
      break
    fi
  done
fi

if [[ -n $trunk ]]; then
  root="${trunk:h}"
  branch="${dir#$root/}"

  print -- "trunk:  $trunk"
  print -- "branch: $branch"

  remote=upstream
  git -C "$trunk" remote get-url upstream >/dev/null 2>&1 || remote=origin

  git -C "$trunk" worktree prune || die 'git worktree prune failed'
  git -C "$trunk" fetch --all --prune || die 'git fetch failed'
  git -C "$trunk" reset --hard "$remote/trunk" || die "git reset --hard $remote/trunk failed"

  if [[ -e $dir/.git ]]; then
    print -- "existing worktree, skipping add"
  elif git -C "$trunk" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$trunk" worktree add "../$branch" "$branch" \
      || die "git worktree add ../$branch $branch failed"
  elif git -C "$trunk" show-ref --verify --quiet "refs/remotes/$remote/$branch"; then
    git -C "$trunk" worktree add -b "$branch" "../$branch" "$remote/$branch" \
      || die "git worktree add -b $branch ../$branch $remote/$branch failed"
  else
    git -C "$trunk" worktree add -B "$branch" "../$branch" \
      || die "git worktree add -B $branch ../$branch failed"
  fi
fi

# --- tabs ------------------------------------------------------------------

ws_json="$(herdr workspace create --cwd "$dir" --label "$label" --focus)"
ws_id="$(print -r -- "$ws_json" | jq -r '.result.workspace.workspace_id')"
sh_tab="$(print -r -- "$ws_json" | jq -r '.result.tab.tab_id')"

herdr tab rename "$sh_tab" sh >/dev/null

nvim_json="$(herdr tab create --workspace "$ws_id" --cwd "$dir" --label nvim --no-focus)"
nvim_pane="$(print -r -- "$nvim_json" | jq -r '.result.root_pane.pane_id')"
herdr pane run "$nvim_pane" nvim >/dev/null

herdr tab create --workspace "$ws_id" --cwd "$dir" --label claude --no-focus >/dev/null

herdr tab focus "$sh_tab" >/dev/null
