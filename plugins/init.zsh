#   Central, idempotent initialization for interactive shells:
#   - Fast, cached compinit
#   - Deterministic plugin load order
#   - Optional fzf/fzf-tab hooks
#   - Plays well with custom registry helpers (_myz_source_if / _myz_plugin_should_load)
#
# Load order (critical):
#   1) compinit
#   2) fzf / fzf-tab (if used)
#   3) zsh-vi-mode
#   4) zsh-autosuggestions
#   5) zsh-syntax-highlighting (OPTIONAL, last)

# ------------------------------------------------------------------------------

# Guard: only interactive shells
[[ -o interactive ]] || return 0

# Avoid heavy re-init if re-sourced; keep idempotent behavior for the rest
if (( ${+MYZ_INIT_DONE} )); then
  return 0
fi
typeset -g MYZ_INIT_DONE=1

# XDG cache default
: ${XDG_CACHE_HOME:="$HOME/.cache"}

# --- Stage 1: compinit (cached, tolerant to insecure dirs)
autoload -Uz compinit
# Use default .zcompdump in $ZDOTDIR (good compatibility with other tools)
typeset -g _myz_compdump="${ZDOTDIR:-$HOME}/.zcompdump"
# -C: trust cache mtime; -i: continue on insecure perms; -d: custom dump file
compinit -C -i -d "$_myz_compdump" >/dev/null 2>&1 || compinit -i -d "$_myz_compdump"

# (Optional) Completion niceties: only if you rely on fzf-tab menu-select
# We don't force options; just ensure complist is available if needed later.
zmodload -F zsh/complist +b:menuselect >/dev/null 2>&1 || true

# --- Stage 2: fzf / fzf-tab (if enabled elsewhere)
# Place your existing fzf setup here or in a separate file sourced before plugins.
# Example (pseudo):
#   if [[ "${MYZ_PLUGINS_ENABLED[fzf-tab]}" == on ]]; then
#     _myz_source_if "${MYZ_PLUGINS_PATH[fzf-tab]}"
#   fi

# Helper shims if registry helpers are not present (degrade gracefully)
if (( ! ${+functions[_myz_source_if]} )); then
  _myz_source_if() {
    local f="$1"
    [[ -r "$f" ]] || { print -u2 -- "[myz:init] not found: $f"; return 1; }
    # shellcheck disable=SC1090
    source "$f"
  }
fi
if (( ! ${+functions[_myz_plugin_should_load]} )); then
  _myz_plugin_should_load() {
    local name="$1"
    [[ "${MYZ_PLUGINS_ENABLED[$name]}" == on ]]
  }
fi

# --- Stage 3: zsh-vi-mode (before autosuggestions)
if _myz_plugin_should_load "zsh-vi-mode"; then
  # Accept both file path or directory with *.plugin.zsh
  local zvm_path="${MYZ_PLUGINS_PATH[zsh-vi-mode]}"
  if [[ -d "$zvm_path" ]]; then
    zvm_path="${zvm_path%/}/zsh-vi-mode.plugin.zsh"
  fi
  _myz_source_if "$zvm_path"
fi

# --- Stage 4: zsh-autosuggestions (after vi-mode)
if _myz_plugin_should_load "zsh-autosuggestions"; then
  local zas_path="${MYZ_PLUGINS_PATH[zsh-autosuggestions]}"
  if [[ -d "$zas_path" ]]; then
    zas_path="${zas_path%/}/zsh-autosuggestions.zsh"
  fi
  _myz_source_if "$zas_path"
  # Then source our hardening config (keybinds, async, viins rebinds)
  if [[ -r "${REPOS_DIR}/my-zsh/zsh-autosuggestions.zsh" ]]; then
    source "${REPOS_DIR}/my-zsh/zsh-autosuggestions.zsh"
  fi
fi

# --- Stage 5: (optional) syntax-highlighting LAST
if _myz_plugin_should_load "zsh-syntax-highlighting"; then
  local zshsh_path="${MYZ_PLUGINS_PATH[zsh-syntax-highlighting]}"
  if [[ -d "$zshsh_path" ]]; then
    zshsh_path="${zshsh_path%/}/zsh-syntax-highlighting.zsh"
  fi
  _myz_source_if "$zshsh_path"
fi

# --- Stage 6: vi-mode indicator (RPROMPT tag + optional cursor)
# Keep this AFTER zsh-vi-mode so $KEYMAP transitions occur correctly.
if [[ -r "${REPOS_DIR}/my-zsh/zsh-vi-mode-indicator.zsh" ]]; then
  source "${REPOS_DIR}/my-zsh/zsh-vi-mode-indicator.zsh"
fi

# --- Health (quiet by default)
if [[ -n "${MYZ_DEBUG_INIT:-}" ]]; then
  print -r -- "[myz:init] compinit=$(which compinit 2>/dev/null)"
  print -r -- "[myz:init] zvm loaded=${+functions[zvm_info]}"
  print -r -- "[myz:init] autosuggest widgets=${+widgets[autosuggest-accept]}"
  print -r -- "[myz:init] RPROMPT='$RPROMPT'"
fi

# End of file
