#!/usr/bin/env zsh
#
# Prompt for a directory and a workspace name, then build a 4-tab workspace:
#
#   tab 1  "zsh"          shell in <dir>
#   tab 2  "nvim"         shell in <dir>, runs nvim
#   tab 3  "pi"           shell in <dir>, runs pi
#   tab 4  "claude-work"  shell in <dir>, runs claude-work
#
# If <dir> already exists, no git work happens at all -- the tabs are just
# opened there. Otherwise <dir> is created, and if it lands inside a worktree
# collection -- i.e. ../trunk or ../../trunk is a checkout -- that trunk is
# pruned, fetched and reset --hard to upstream/trunk, then <dir> is added as a
# worktree before the tabs are built. The branch name is <dir> relative to the
# collection root, so ~/GitHub/atsign/noports/jt/feature -> jt/feature and
# .../jt-feature -> jt-feature.
#
# The workspace name defaults to that same branch name when <dir> sits in a
# worktree collection, otherwise to the last path component.
#
# Bound in config.toml as a [[keys.command]] popup. Tab completes directories,
# Ctrl+C cancels.
#
# Agents hand a task to a new workspace without prompts:
#
#   new-workspace.zsh --agent <pi|claude-work> <dir> [<name>] < prompt
#
# That builds the same workspace without focusing it, refuses to reset a trunk
# with uncommitted changes, and starts the chosen agent's tab with the prompt.

emulate -L zsh
setopt err_exit pipe_fail

usage='usage: new-workspace.zsh [--agent <pi|claude-work> <dir> [<name>] < prompt]'

agent=
if [[ $1 == --agent ]]; then
  agent="$2"
  [[ $agent == (pi|claude-work) && -n $3 ]] || { print -u2 -- "$usage"; exit 1 }
  dir="$3"
  label="$4"
  prompt="$(cat)"
  [[ -n $prompt ]] || { print -u2 -- 'no prompt on stdin'; exit 1 }
elif (( $# )); then
  print -u2 -- "$usage"
  exit 1
fi

die() {
  print -u2 -- "$@"
  if [[ -z $agent ]]; then
    print -u2 -- '-- press any key --'
    read -k1 -s
  fi
  exit 1
}

if [[ -z $agent ]]; then
  autoload -Uz compinit
  compinit -u -d "${XDG_CACHE_HOME:-$HOME/.cache}/herdr-zcompdump"
  zstyle ':completion:*' file-patterns '*(-/):directories'

  dir="$HOME/GitHub/"
  vared -p 'workspace dir: ' dir
fi

dir="${~dir}"
dir="${dir%/}"
dir="${dir:a}"
[[ -n $dir ]] || die 'no directory given'

if [[ -d $dir ]]; then
  fresh=0
else
  fresh=1
  mkdir -p -- "$dir" || die "could not create: $dir"
fi
dir="${dir:A}"

# --- worktree collection? --------------------------------------------------

trunk=
for cand in "${dir:h}/trunk" "${dir:h:h}/trunk"; do
  if [[ $cand != $dir && -e $cand/.git ]]; then
    trunk="$cand"
    break
  fi
done

if [[ -n $trunk ]]; then
  root="${trunk:h}"
  branch="${dir#$root/}"
  label="${label:-$branch}"
else
  label="${label:-${dir:t}}"
fi

if [[ -z $agent ]]; then
  vared -p 'workspace name: ' label
fi
[[ -n $label ]] || die 'no workspace name given'

if (( fresh )) && [[ -n $trunk ]]; then
  print -- "trunk:  $trunk"
  print -- "branch: $branch"

  if [[ -n $agent && -n "$(git -C "$trunk" status --porcelain)" ]]; then
    rmdir -- "$dir"
    die "trunk has uncommitted changes, not resetting it: $trunk"
  fi

  remote=upstream
  git -C "$trunk" remote get-url upstream >/dev/null 2>&1 || remote=origin

  git -C "$trunk" worktree prune || die 'git worktree prune failed'
  git -C "$trunk" fetch --all --prune || die 'git fetch failed'
  git -C "$trunk" reset --hard "$remote/trunk" || die "git reset --hard $remote/trunk failed"

  if git -C "$trunk" show-ref --verify --quiet "refs/heads/$branch"; then
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

if [[ -n $agent ]]; then
  prompt_file="$(mktemp -t herdr-prompt)"
  print -r -- "$prompt" >| "$prompt_file"
  focus=--no-focus
else
  focus=--focus
fi

ws_json="$(herdr workspace create --cwd "$dir" --label "$label" "$focus")"
ws_id="$(print -r -- "$ws_json" | jq -r '.result.workspace.workspace_id')"
sh_tab="$(print -r -- "$ws_json" | jq -r '.result.tab.tab_id')"

herdr tab rename "$sh_tab" zsh >/dev/null

herdr tab create --workspace "$ws_id" --cwd "$dir" --label nvim --no-focus >/dev/null

agent_tab() {
  local -a env
  if [[ $1 == $agent ]]; then
    env=(--env "HERDR_AGENT_PROMPT_FILE=$prompt_file")
  fi
  herdr tab create --workspace "$ws_id" --cwd "$dir" --label "$1" --no-focus "${env[@]}" \
    | jq -r '.result.tab.tab_id'
}

pi_tab="$(agent_tab pi)"
claude_tab="$(agent_tab claude-work)"

if [[ -z $agent ]]; then
  herdr tab focus "$sh_tab" >/dev/null
  exit 0
fi

if [[ $agent == pi ]]; then
  tab="$pi_tab"
else
  tab="$claude_tab"
fi
print -r -- "dispatched to workspace \"$label\" ($ws_id), tab $tab running $agent in $dir"
