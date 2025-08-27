# Load shell integrations/plugins from a portable repo location (no oh-my-zsh dependency).
#   Also supports Homebrew installs as a fallback. Pure zsh, idempotent sourcing.

# Guard: need zsh and MYGITHUB
[[ -n "${ZSH_VERSION-}" ]] || return 0
: "${MYGITHUB:?Please export MYGITHUB (e.g., /mnt/steve/MyGithub)}"

# Debug toggle: export MYZSH_DEBUG=1 to see which files are sourced
: "${MYZSH_DEBUG:=0}"

# Helper: first readable file from a list
__first_readable() {
  # Usage: __first_readable FILE_A FILE_B ...
  local f
  for f in "$@"; do
    [[ -f "$f" && -r "$f" ]] && print -r -- "$f" && return 0
  done
  return 1
}

# Resolve candidate plugin roots (highest priority first)
# 1) Explicit override via $ZSH_PLUGIN_DIR
# 2) Repo path under $MYGITHUB
# 3) User-local fallback
: "${ZSH_PLUGIN_DIR:=}"
typeset -a __plug_roots
__plug_roots=()
[[ -n "$ZSH_PLUGIN_DIR" ]] && __plug_roots+=("$ZSH_PLUGIN_DIR")
__plug_roots+=(
  "$MYGITHUB/Configs/Shells/oh-my-zsh/plugins"
  "$HOME/.zsh/plugins"
)

# Helper: join a plugin-relative path with the first existing root
__from_roots() {
  # Usage: __from_roots relative/path ...
  # Returns: first existing readable file under any root (in declared order)
  local rel="$1" root
  for root in "${__plug_roots[@]}"; do
    [[ -n "$root" ]] || continue
    local cand="$root/$rel"
    [[ -f "$cand" && -r "$cand" ]] && print -r -- "$cand" && return 0
  done
  return 1
}

# Homebrew prefix (if any), used for fallbacks
__brew_prefix=""
if command -v brew >/dev/null 2>&1; then
  __brew_prefix="$(brew --prefix 2>/dev/null)"
fi

# Safe source wrapper (idempotent by path)
typeset -gA __SOURCED_ONCE
__safe_source() {
  local f="$1"
  if [[ -f "$f" && -r "$f" ]]; then
    if [[ -z "${__SOURCED_ONCE[$f]-}" ]]; then
      (( MYZSH_DEBUG )) && print -u2 -- "[integrations] source: $f"
      # shellcheck disable=SC1090
      source "$f"
      __SOURCED_ONCE[$f]=1
    else
      (( MYZSH_DEBUG )) && print -u2 -- "[integrations] already: $f"
    fi
  elif (( MYZSH_DEBUG )); then
    print -u2 -- "[integrations] skip (not readable): $f"
  fi
}

# Ensure completion is initialized (harmless if already done elsewhere)
autoload -Uz compinit
if [[ -n "${ZDOTDIR:-}" && -d "$ZDOTDIR" ]]; then
  compinit -C -d "$ZDOTDIR/.zcompdump"
else
  compinit -C -d "$HOME/.zcompdump"
fi

# zsh-vi-mode (prefer repo copy; then Homebrew)
# Repo structures supported:
#   plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh
zvm_file="$(__from_roots "zsh-vi-mode/zsh-vi-mode.plugin.zsh")"
if [[ -z "$zvm_file" && -n "$__brew_prefix" ]]; then
  zvm_file="$(__first_readable \
    "$__brew_prefix/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh" \
    "$__brew_prefix/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh")"
fi
if [[ -n "$zvm_file" ]]; then
  __safe_source "$zvm_file"
  typeset -g _ZVM_LOADED=1
else
  bindkey -v  # fallback to vi keybindings
fi
unset zvm_file

# zsh-autosuggestions
# Repo structures supported:
#   plugins/zsh-autosuggestions.zsh
#   plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
zas_file="$(__from_roots "zsh-autosuggestions.zsh")"
[[ -z "$zas_file" ]] && zas_file="$(__from_roots "zsh-autosuggestions/zsh-autosuggestions.zsh")"
if [[ -z "$zas_file" && -n "$__brew_prefix" ]]; then
  zas_file="$(__first_readable \
    "$__brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh")"
fi
[[ -n "$zas_file" ]] && __safe_source "$zas_file"
unset zas_file

# zsh-syntax-highlighting (must be sourced last among highlighting engines)
# Repo structures supported:
#   plugins/zsh-syntax-highlighting.zsh
#   plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
zshs_file="$(__from_roots "zsh-syntax-highlighting.zsh")"
[[ -z "$zshs_file" ]] && zshs_file="$(__from_roots "zsh-syntax-highlighting/zsh-syntax-highlighting.zsh")"
if [[ -z "$zshs_file" && -n "$__brew_prefix" ]]; then
  zshs_file="$(__first_readable \
    "$__brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh")"
fi
[[ -n "$zshs_file" ]] && __safe_source "$zshs_file"
unset zshs_file

# fzf key bindings (installed by the fzf install script)
__safe_source "$HOME/.fzf.zsh"

# zoxide (smart cd)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# direnv (per-directory env)
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# NVM (Node Version Manager); prefer Homebrew path if available
if [[ -n "$__brew_prefix" && -d "$__brew_prefix/opt/nvm" ]]; then
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  __safe_source "$__brew_prefix/opt/nvm/nvm.sh"
elif [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  __safe_source "$HOME/.nvm/nvm.sh"
fi

# Cleanup local helper vars
unset __plug_roots __brew_prefix
