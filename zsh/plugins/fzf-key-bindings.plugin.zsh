#!/usr/bin/env zsh

# Key bindings
# ------------
if [[ $- == *i* ]]; then

# CTRL-T - Paste the selected file path(s) into the command line
__fsel() {
  # '*/' for all files
  # '*/\\.*' to hide hidden files
  local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . \\( -path '*/' -o -fstype 'dev' -o -fstype 'proc' \\) -prune \
    -o -type f -print \
    -o -type d -print \
    -o -type l -print 2> /dev/null | grep -v '.git/' | sed 1d | cut -b3-"}"
  eval "$cmd" | $(__fzfcmd) -m | while read item; do
    printf '%q ' "$item"
  done
  echo
}

__fzfcmd() {
  [ ${FZF_TMUX:-1} -eq 1 ] && echo "fzf -d${FZF_TMUX_HEIGHT:-40%}" || echo "fzf"
}

fzf-file-widget() {
  LBUFFER="${LBUFFER}$(__fsel)"
  zle redisplay
}
zle     -N   fzf-file-widget
bindkey '^F' fzf-file-widget

# CTRL-G - cd into the selected directory
fzf-changedir-widget() {
  # '*/' for all files
  # '*/\\.*' to hide hidden files
  local cmd="${FZF_ALT_C_COMMAND:-"command find -L . \\( -path '*/' -o -fstype 'dev' -o -fstype 'proc' \\) -prune \
    -o -type d -print 2> /dev/null | grep -v '.git/' | sed 1d | cut -b3-"}"
  cd "${$(eval "$cmd" | $(__fzfcmd) +m):-.}"
  zle reset-prompt
}
zle -N fzf-changedir-widget
bindkey '^G' fzf-changedir-widget

# CTRL-R - Paste the selected command from history into the command line
fzf-history-widget() {
  local selected num
  selected=( $(fc -l 1 | $(__fzfcmd) +s --tac +m -n2..,.. --tiebreak=index --toggle-sort=ctrl-r -q "${LBUFFER//$/\\$}") )
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle redisplay
}
zle -N fzf-history-widget
bindkey '\C-R' fzf-history-widget

# CTRL-Z - Z integration
fzf-z-widget() {
  cd "$(z -l 2>&1 | tail -50 | fzf +s --tac | sed 's/^[0-9,.]* *//')"
  zle accept-line
}
zle -N fzf-z-widget
bindkey "^Z" fzf-z-widget

fi
