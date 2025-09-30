# File: $REPOS_DIR/my-zsh/integrations.zsh
# Purpose: Load shell integrations/plugins from a portable repo location (no oh-my-zsh dependency).
#          Also supports Homebrew installs as a fallback. Pure zsh, idempotent sourcing.

# Guard: need zsh and repos
[[ -n "${ZSH_VERSION-}" ]] || return 0
: "${REPOS_DIR:?Please export repos (e.g., /mnt/steve/repos)}"

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
# 2) Repo path under $REPOS_DIR
# 3) User-local fallback
: "${ZSH_PLUGIN_DIR:=}"
typeset -a __plug_roots
__plug_roots=()
[[ -n "$ZSH_PLUGIN_DIR" ]] && __plug_roots+=("$ZSH_PLUGIN_DIR")
__plug_roots+=(
  "$REPOS_DIR/my-zsh/plugins"   # fixed: was "my-zhs"
  "$HOME/.zsh/plugins"
)

# Helper: join a plugin-relative path with the first existing root
__from_roots() {
  # Usage: __from_roots relative/path
  # Returns: first existing readable file under any root (in declared order)
  local rel="$1" root cand
  for root in "${__plug_roots[@]}"; do
    [[ -n "$root" ]] || continue
    cand="$root/$rel"
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

# ---------------------------------------
# Completions before compinit (zsh-completions)
# ---------------------------------------
# Repo copy
if [[ -d "$REPOS_DIR/my-zsh/plugins/zsh-completions/src" ]]; then
  fpath=("$REPOS_DIR/my-zsh/plugins/zsh-completions/src" $fpath)
# Brew fallback
elif [[ -n "$__brew_prefix" && -d "$__brew_prefix/share/zsh-completions" ]]; then
  fpath=("$__brew_prefix/share/zsh-completions" $fpath)
fi

# (Re)initialize completion cache (safe if done earlier)
autoload -Uz compinit
if [[ -n "${ZDOTDIR:-}" && -d "$ZDOTDIR" ]]; then
  compinit -C -d "$ZDOTDIR/.zcompdump"
else
  compinit -C -d "$HOME/.zcompdump"
fi

# ---------------------------------------
# fzf-tab (repo plugin; Brew package usually not available)
# ---------------------------------------
if [[ -r "$REPOS_DIR/my-zsh/plugins/fzf-tab/fzf-tab.zsh" ]]; then
  __safe_source "$REPOS_DIR/my-zsh/plugins/fzf-tab/fzf-tab.zsh"
  # Recommended styles: avoid auto "menu select" because fzf-tab takes over
  zstyle ':completion:*' menu no-select
  zstyle ':fzf-tab:*' switch-group 'Alt-h' 'Alt-l'
  zstyle ':fzf-tab:*' fzf-bindings 'space:toggle'
fi

# ---------------------------------------
# fzf integtration
# ---------------------------------------
# Candidate shells in priority order:
typeset -a _fzf_shells
_fzf_shells=(
  "$HOME/.fzf/shell"                 # user git install (Linux/macOS/WSL)
  "/usr/share/fzf"                   # Debian/Ubuntu/Arch (key-bindings.zsh, completion.zsh)
  "/usr/share/doc/fzf/examples"      # some distros put examples here
)

# Homebrew fallback (macOS or Linuxbrew)
if command -v brew >/dev/null 2>&1; then
  _fzf_shells=(
    "$(brew --prefix fzf 2>/dev/null)/shell"
    "${_fzf_shells[@]}"
  )
fi

# Source completion before key-bindings; guard by readability/interactive
for _d in "${_fzf_shells[@]}"; do
  if [[ -r "$_d/completion.zsh" && $- == *i* ]]; then
    __safe_source "$_d/completion.zsh"
    _fzf_comp_loaded=1
  fi
  if [[ -r "$_d/key-bindings.zsh" ]]; then
    __safe_source "$_d/key-bindings.zsh"
    _fzf_bind_loaded=1
  fi
  [[ -n "${_fzf_bind_loaded}${_fzf_comp_loaded}" ]] && break
done

unset _fzf_shells _fzf_bind_loaded _fzf_comp_loaded

# ---------------------------------------
# zsh-vi-mode (prefer repo copy; then Homebrew)
# ---------------------------------------
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

# ---------------------------------------
# zsh-autosuggestions
# ---------------------------------------
zas_file="$(__from_roots "zsh-autosuggestions.zsh")"
[[ -z "$zas_file" ]] && zas_file="$(__from_roots "zsh-autosuggestions/zsh-autosuggestions.zsh")"
if [[ -z "$zas_file" && -n "$__brew_prefix" ]]; then
  zas_file="$(__first_readable \
    "$__brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh")"
fi
[[ -n "$zas_file" ]] && __safe_source "$zas_file"
unset zas_file

# ---------------------------------------
# zsh-syntax-highlighting (must be LAST among highlighters)
# ---------------------------------------
zshs_file="$(__from_roots "zsh-syntax-highlighting.zsh")"
[[ -z "$zshs_file" ]] && zshs_file="$(__from_roots "zsh-syntax-highlighting/zsh-syntax-highlighting.zsh")"
if [[ -z "$zshs_file" && -n "$__brew_prefix" ]]; then
  zshs_file="$(__first_readable \
    "$__brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh")"
fi
[[ -n "$zshs_file" ]] && __safe_source "$zshs_file"
unset zshs_file

# ---------------------------------------
# Other tool integrations
# ---------------------------------------

# Ensure completion function and compdef are present even if init script changed names
# 1) prefer _zoxide_z (historical), else try any _zoxide* match
if (( $+functions[_zoxide_z] )); then
  compdef _zoxide_z z 2>/dev/null
else
  # Fallback: try to find a zoxide completion function by pattern
  for __zf in ${(k)functions}; do
    case "$__zf" in
      _zoxide(|_z|_cd) )
        compdef "$__zf" z 2>/dev/null
        break
        ;;
    esac
  done
fi
unset __zf

# zoxide (smart cd)
if command -v zoxide >/dev/null 2>&1; then
  # robust init with fallbacks
  if ! eval "$(zoxide init zsh 2>/dev/null)"; then
    if [[ -x "/home/linuxbrew/.linuxbrew/bin/zoxide" ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/zoxide init zsh 2>/dev/null)" || true
    elif [[ -x "/opt/homebrew/bin/zoxide" ]]; then
      eval "$(/opt/homebrew/bin/zoxide init zsh 2>/dev/null)" || true
    fi
  fi

  # ensure completion for alias `z`
  if (( $+functions[_zoxide_z] )); then
    compdef _zoxide_z z 2>/dev/null
  else
    for __zf in ${(k)functions}; do
      case "$__zf" in
        _zoxide(|_z|_cd) )
          compdef "$__zf" z 2>/dev/null
          break
          ;;
      esac
    done
    unset __zf
  fi
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
