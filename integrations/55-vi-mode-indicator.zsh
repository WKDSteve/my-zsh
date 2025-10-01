# =====================================================================
# integrations/55-vi-mode-indicator.zsh
# Optional right-prompt mode indicator for vi-mode.
# Keep separate so it can be toggled off without disabling vi-mode itself.
# =====================================================================

[[ -o interactive ]] || return 0
[[ -n ${MYZ_LOADED[int:55-vi-indicator]-} ]] && return 0

# Lightweight indicator; respects prompt engines loaded earlier.
# One can set MYZ_VI_INDICATOR_FMT to customize the display text.

: ${MYZ_VI_INDICATOR_FMT:='[V: ${KEYMAP:-?}]'}

# Refresh hook bound to zle-line-init and keymap changes
_myz_vi_refresh_rprompt() {
  # This function runs inside ZLE; use prompt expansion safely.
  local mode="${KEYMAP:-?}"
  # Right prompt; leave left prompt to user's theme (starship/oh-my-posh/custom)
  RPROMPT="${MYZ_VI_INDICATOR_FMT//\$\{KEYMAP:-?\}/$mode}"
}
zle -N _myz_vi_refresh_rprompt

# Tie into ZLE lifecycle; guards avoid "widgets can only be called..." errors.
autoload -Uz add-zsh-hook
add-zsh-hook zle-keymap-select _myz_vi_refresh_rprompt 2>/dev/null || true
add-zsh-hook zle-line-init     _myz_vi_refresh_rprompt 2>/dev/null || true

# Initial refresh when ZLE starts
[[ -n ${ZLE-} ]] && _myz_vi_refresh_rprompt

MYZ_LOADED[int:55-vi-indicator]=1

