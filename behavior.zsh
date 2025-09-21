# Shell behavior and UX defaults (portable across Linux/macOS).

# Pager
export PAGER="${PAGER:-less}"
export LESS="${LESS:--R}"
export EDITOR="nvim"
export VISUAL="$EDITOR"

# History
export HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
export HISTSIZE=1000
export SAVEHIST=1000
setopt SHARE_HISTORY        # merge history across sessions
setopt HIST_IGNORE_ALL_DUPS # drop older duplicate entries
setopt HIST_IGNORE_SPACE    # commands starting with space are not stored

# General shell options
setopt AUTO_CD # 'cd' implied when typing a directory
setopt INTERACTIVE_COMMENTS # allow comments in interactive shell
setopt PIPE_FAIL            # fail a pipeline if any command fails
#setopt GLOB_DOTS # include dotfiles in globs

# Enable completion for aliases like: alias z='__zoxide_z'
setopt COMPLETE_ALIASES

# Completion system with caching
autoload -Uz compinit
if [[ -n "${ZDOTDIR:-}" && -d "$ZDOTDIR" ]]; then
  _compdump="$ZDOTDIR/.zcompdump"
else
  _compdump="$HOME/.zcompdump"
fi
compinit -C -d "$_compdump"

# Make alias completion work (needed because `z` is an alias to __zoxide_z)
setopt COMPLETE_ALIASES

# Completion styles
zmodload zsh/complist                # Enable menuselect and color-capable completion widgets
zstyle ':completion:*' menu select=2 # Make the menu appear for multiple matches and allow interactive selection
# Fuzzy-ish matching
zstyle ':completion:*' matcher-list \
  'm:{a-z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'
# Colors for the completion listing
# - explicitly bias most classes to green.
# - 'ma' colors only the matched substrings → neon highlight effect.
# - 'or'/'mi' stay red so broken paths stand out.
zstyle ':completion:*' list-colors \
  'ma=1;32' \
  'no=0;32' 'fi=0;32' \
  'di=1;32' 'ln=0;36' \
  'pi=0;32' 'so=0;32' 'bd=0;32' 'cd=0;32' \
  'ex=1;32' \
  'or=1;31' 'mi=1;31' \
  '*.sh=1;32' '*.bash=1;32' '*.zsh=1;32' \
  '*.lua=1;32' '*.ts=1;32' '*.js=1;32' '*.go=1;32' \
  '*.md=0;32' '*.txt=0;32'
# Show group titles and style all helper texts in green
zstyle ':completion:*' group-name 'yes'
zstyle ':completion:*:descriptions' format '%F{green}%d%f'
zstyle ':completion:*:messages' format '%F{green}%d%f'
zstyle ':completion:*:warnings' format '%F{red}%d%f'
# Selection and list prompts with a neon touch
# %S ... %s toggles standout mode; colors are additive.
zstyle ':completion:*' select-prompt '%S%F{black}%K{green} >> %k%f%s'
zstyle ':completion:*' list-prompt '%S%F{green}%M matches (%p remaining)%f%s'
# Optional: keep results visually compact (off by default)
zstyle ':completion:*' verbose no

# Safer defaults for common tools
if command -v rg > /dev/null 2>&1; then
  # Use kitty hyperlinks only inside kitty; otherwise keep defaults
  if [[ "${TERM:-}" == "xterm-kitty" || -n "${KITTY_WINDOW_ID:-}" ]]; then
    export RIPGREP_CONFIG_PATH="${RIPGREP_CONFIG_PATH:-$HOME/.ripgreprc}"
    alias rg='rg --hyperlink-format=kitty'
  fi
fi

# FZF defaults (replace alias-based override)
if command -v fzf > /dev/null 2>&1; then
  export FZF_DEFAULT_OPTS=${FZF_DEFAULT_OPTS:-"--height 40% --layout=reverse --border"}
fi
