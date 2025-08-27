# Make zsh behave and look more like the fish shell.
# Scope:
#   - fish-like autosuggestions (dim gray), history-substring search on ↑/↓
#   - fuzzy-ish, menu-driven completion with grouped descriptions
#   - fish-style prompt (if Starship is not active): pwd, git, exit code, time
#   - lightweight "abbr" expansion (fish-like) on <Space> and <Enter>
#
# Notes:
#   - This file is safe to source multiple times.
#   - It works best if zsh-autosuggestions and zsh-syntax-highlighting are available.
#   - Keep Starship as-is: if Starship is detected, prompt theming is skipped.

# Guard: only in zsh
[[ -n "${ZSH_VERSION-}" ]] || return 0
[[ -n "${__FISHIFY_LOADED:-}" ]] && return 0
typeset -g __FISHIFY_LOADED=1

# ----------------------------
# 0) Keymap: fish defaults are Emacs-like (not vi).
#    Keep vi-mode if already active; otherwise switch to Emacs keybindings.
# ----------------------------
if [[ -z "${_ZVM_LOADED:-}" ]]; then
  bindkey -e
fi

# ----------------------------
# 1) Autosuggestions similar to fish (dim gray)
#    Requires zsh-autosuggestions; if missing, this section is harmless.
# ----------------------------
# Style: use a dim, gray look akin to fish
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
# Strategy: follow the cursor; accept with →, Ctrl-f, End
bindkey '^F'    forward-char
bindkey '^E'    end-of-line
# If plugin is present, remap keys to accept suggestions
if [[ -n "${widgets[autosuggest-accept]:-}" ]]; then
  bindkey "${terminfo[kcuf1]:-$'\e[C'}" autosuggest-accept
  bindkey '^F' autosuggest-accept
  bindkey '^E' autosuggest-accept
fi

# ----------------------------
# 2) History substring search on Up/Down (fish-like)
# ----------------------------
# Use built-in widgets for beginning-of-line substring search
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "${terminfo[kcuu1]:-$'\e[A'}" up-line-or-beginning-search
bindkey "${terminfo[kcud1]:-$'\e[B'}" down-line-or-beginning-search

# ----------------------------
# 3) Completion UI: grouped, menu-select, fuzzy-ish matchers
# ----------------------------
zmodload zsh/complist
autoload -Uz compinit
if [[ -n "${ZDOTDIR:-}" && -d "$ZDOTDIR" ]]; then
  compinit -C -d "$ZDOTDIR/.zcompdump"
else
  compinit -C -d "$HOME/.zcompdump"
fi
# Show menu automatically and allow interactive selection
zstyle ':completion:*' menu select=2
# Friendly matchers: case-insensitive + separators are optional
zstyle ':completion:*' matcher-list \
  'm:{a-z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'
# Group results with green descriptions (fish-ish clarity)
zstyle ':completion:*' group-name 'yes'
zstyle ':completion:*:descriptions' format '%F{green}%d%f'
zstyle ':completion:*:messages'     format '%F{green}%d%f'
zstyle ':completion:*:warnings'     format '%F{red}%d%f'
# Highlight only the matching parts (neon-on-dark effect)
zstyle ':completion:*' list-colors 'ma=1;32'

# ----------------------------
# 4) Prompt: fish-like, if Starship is NOT active
#    Left: user@host (on SSH), shortened pwd, git branch
#    Right: exit code (when nonzero), HH:MM
# ----------------------------
if ! command -v starship >/dev/null 2>&1; then
  setopt PROMPT_SUBST
  autoload -Uz colors && colors

  # Shorten $PWD fish-style: first letters for parent dirs, full last dir
  fishify_pwd() {
    # Prints something like ~/p/s/myproject instead of /home/user/projects/src/myproject
    local IFS='/'
    local -a parts=(${PWD/#$HOME/~})
    local out=""
    local i last=$(( ${#parts[@]} - 1 ))
    for i in {1..$last}; do
      # Skip empty elements and ~
      if [[ $i -eq $last ]]; then
        out+="/${parts[i]}"
      else
        case "${parts[i]}" in
          ''|'~') out+="/${parts[i]}" ;;
          *)      out+="/${parts[i]:0:1}" ;;
        esac
      fi
    done
    # Handle root/edge cases
    [[ -z "$out" ]] && out="${PWD/#$HOME/~}"
    print -r -- "${out#/}"  # drop leading slash for aesthetics
  }

  # Lightweight git branch detector
  git_branch() {
    local b
    b=$(command git symbolic-ref --quiet --short HEAD 2>/dev/null) \
      || b=$(command git rev-parse --short HEAD 2>/dev/null) \
      || return 0
    print -r -- "$b"
  }

  # Left prompt
  local _ssh=''
  [[ -n "$SSH_CONNECTION" ]] && _ssh='%F{cyan}%n@%m%f '
  PROMPT='${_ssh}%F{blue}$(fishify_pwd)%f %F{green}$(git_branch)%f
%# '

  # Right prompt: show exit code if non-zero and time
  RPROMPT='%F{red}%(?..%?)%f %F{yellow}%*%f'
fi

# ----------------------------
# 5) Abbreviations (fish-like "abbr"): expand on Space and Enter
#    Define pairs in FISH_ABBR (key -> replacement).
# ----------------------------
typeset -gA FISH_ABBR
# Examples (edit freely):
# FISH_ABBR[gs]='git status'
# FISH_ABBR[ga]='git add'
# FISH_ABBR[gc]='git commit -v'
# FISH_ABBR[gco]='git checkout'
# FISH_ABBR[gd]='git diff'
# FISH_ABBR[nr]='npm run'
# FISH_ABBR[tf]='terraform'

# Expansion widget: replace the word before cursor if it matches a key
_fish_abbr_expand() {
  setopt localoptions noshwordsplit
  local L="${#LBUFFER}" R="${#RBUFFER}" cur word start end
  cur=$L
  # Find word boundaries around cursor
  zle backward-word; start=$(( ${#LBUFFER} )); zle forward-word; end=$(( ${#LBUFFER} ))
  # Restore original cursor position
  CURSOR=$cur
  # Extract current word
  word="${BUFFER:start:end-start}"
  # If there is an abbreviation, replace it
  if [[ -n "${FISH_ABBR[$word]-}" ]]; then
    BUFFER="${BUFFER:0:start}${FISH_ABBR[$word]}${BUFFER:end}"
    CURSOR=$(( start + ${#FISH_ABBR[$word]} ))
  fi
}

# Bind abbreviation expansion to <Space> and <Enter>
_fish_magic_space()  { _fish_abbr_expand; zle magic-space; }
_fish_accept_line()  { _fish_abbr_expand; zle accept-line; }
zle -N _fish_magic_space
zle -N _fish_accept_line
bindkey ' ' _fish_magic_space
bindkey '^M' _fish_accept_line

# ----------------------------
# 6) Small QoL tweaks to mimic fish behavior
# ----------------------------
setopt AUTO_CD                 # cd by typing a directory name
setopt INTERACTIVE_COMMENTS    # allow comments in interactive commands
setopt COMPLETE_IN_WORD        # complete in the middle of a word
setopt GLOB_DOTS               # include dotfiles in globs (fish shows them)
setopt NO_BEEP                 # quiet, fish-like
