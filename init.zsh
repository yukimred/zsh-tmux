#
# Copyright 2021, laggardkernel and the zsh-tmux contributors
# SPDX-License-Identifier: MIT

#
# Authors:
#   laggardkernel <laggardkernel@gmail.com>
#

# Return if requirements are not found.
if (( ! $+commands[tmux] )); then
  return
fi

# Wrapper function for tmux.
function _zsh_tmux_plugin_run() {
  local -a tmux_cmd
  tmux_cmd=(command tmux)

  if [[ "$TERM_PROGRAM" == "iTerm.app" ]] && \
    zstyle -t ":prezto:module:tmux:iterm" integrate; then
    # revert aggressive-resize set by tmux-sensible
    tmux setw -g aggressive-resize off
    tmux_cmd+=(-CC)
  fi

  local _tmux_session
  local _tmux_session_hash
  # name session as <directory>-<hash>
  _tmux_session="$(pwd)" && _tmux_session="${_tmux_session##*/}"
  # TODO: remove illegal characters with regex
  _tmux_session="${_tmux_session// /_}"; _tmux_session="${_tmux_session//./_}"; _tmux_session="${_tmux_session//:/_}"

  if (( $+commands[md5sum] )); then
    _tmux_session_hash="$(pwd|md5sum)" \
      && _tmux_session_hash="${_tmux_session_hash% -}"
  elif (( $+commands[md5] )); then
    _tmux_session_hash="$(pwd|md5 -r)"
  fi
  _tmux_session_hash="${_tmux_session_hash:0:5}"

  _tmux_session="${_tmux_session}-${_tmux_session_hash}" && unset _tmux_session_hash

  # set -x
  local return_val
  if [[ "$TERM_PROGRAM" == "iTerm.app" ]] && \
    zstyle -t ":prezto:module:tmux:iterm" integrate; then
    if zstyle -T ":prezto:module:tmux" auto-close; then
      if ! tmux has-session -t "$_tmux_session" &>/dev/null; then
        exec $tmux_cmd new-session -AD -s "$_tmux_session"
      fi
    else
      if ! tmux has-session -t "$_tmux_session" &>/dev/null; then
        $tmux_cmd new-session -AD -s "$_tmux_session"
      fi
    fi
  else
    if ! tmux has-session -t "$_tmux_session" &>/dev/null; then
      if return_val=$($tmux_cmd new-session -AD -s "$_tmux_session"); then
        zstyle -T ":prezto:module:tmux" auto-close && exit
      else
        [[ "$return_val" = *exited* ]] && exit
      fi
    fi
  fi
  # set +x
}

if [[ -z "$NO_AUTO_TMUX" ]] && \
  [[ -z "$TMUX" && -z "$EMACS" && -z "$VIM" && -z "$INSIDE_EMACS" && "$TERM_PROGRAM" != "vscode" && "$TERMINAL_EMULATOR" != "JetBrains-JediTerm" ]] && ( \
  ( [[ -n "$SSH_TTY" ]] && zstyle -t ':prezto:module:tmux:auto-start' remote ) ||
  ( [[ -z "$SSH_TTY" ]] && zstyle -T ':prezto:module:tmux:auto-start' local ) \
); then
  export NO_AUTO_TMUX=1 # disable auto tmux connection in sub-shells
  _zsh_tmux_plugin_run
fi
