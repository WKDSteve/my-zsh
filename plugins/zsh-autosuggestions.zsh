#   Reliable, fast zsh-autosuggestions in vi mode.
#   - Async suggestions
#   - Safe defaults and subtle styling
#   - Works with vi keymaps; rebinds automatically on keymap changes
#
# Usage:
#   Source after compinit and after zsh-vi-mode.
#   Optionally set MYZ_AUTOSUGGEST_STYLE before sourcing to override the style.

# ------------------------------------------------------------------------------

# Guard: interactive shells only
[[ -o interactive ]] || return 0

# Guard: avoid duplicate setup when re-sourcing
if (( ${+MYZ_AUTOSUGGEST_INIT} )); then
  return 0
fi
typeset -g MYZ_AUTOSUGGEST_INIT=1

# Defaults (override via env before sourcing)
: ${MYZ_AUTOSUGGEST_STYLE:=fg=8}    # subtle grey; adjust to fg=7 if too dark
: ${ZSH_AUTOSUGGEST_USE_ASYNC:=1}
: ${ZSH_AUTOSUGGEST_STRATEGY:="(history completion)"}  # fast-first fallback
: ${ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE:=200}
: ${ZSH_AUTOSUGGEST_MANUAL_REBIND:=1}

# Try to source the plugin if not already loaded.
# Works with our registry helper if present; otherwise no-op.
if [[ -z ${+widgets[autosuggest-accept]} ]]; then
  if (( ${+functions[_myz_source_if]} )) && [[ -n ${MYZ_PLUGINS_PATH[zsh-autosuggestions]} ]]; then
    _myz_source_if "${MYZ_PLUGINS_PATH[zsh-autosuggestions]}"
  elif [[ -r "${ZDOTDIR:-$HOME}/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    # Fallback common location
    source "${ZDOTDIR:-$HOME}/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi
fi

# Style (color)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="$MYZ_AUTOSUGGEST_STYLE"

# --- Sanity: ensure widgets exist; if not, bail gracefully
if [[ -z ${+widgets[autosuggest-accept]} ]]; then
  print -u2 -- "[autosuggestions] plugin not found; skipping config."
  return 0
fi

# Optional helper: toggle if widget exists; otherwise emulate
if [[ -z ${+widgets[autosuggest-toggle]} ]]; then
  _myz_autosuggest_toggle() {
    # Use plugin built-ins if present
    if [[ -n ${+widgets[autosuggest-enable]} && -n ${+widgets[autosuggest-disable]} ]]; then
      if [[ ${ZSH_AUTOSUGGEST_DISABLED:-0} -eq 1 ]]; then
        zle autosuggest-enable
      else
        zle autosuggest-disable
      fi
    else
      # Soft toggle via env flag
      if [[ ${ZSH_AUTOSUGGEST_DISABLED:-0} -eq 1 ]]; then
        unset ZSH_AUTOSUGGEST_DISABLED
      else
        ZSH_AUTOSUGGEST_DISABLED=1
      fi
    fi
  }
  zle -N autosuggest-toggle _myz_autosuggest_toggle
fi

# (Re)bind keys for vi insert map.
# - Accept: Ctrl-Space and Ctrl-F
# - Accept by word: Alt-f (Meta-f)
# - Toggle: Alt-s
_myz_autosuggest_bind_viins() {
  # Ensure map exists
  bindkey -M viins >/dev/null 2>&1 || return 0

  bindkey -M viins '^ '  autosuggest-accept         # Ctrl-Space
  bindkey -M viins '^F'  autosuggest-accept         # Ctrl-F
  bindkey -M viins '^[f' autosuggest-accept-word    # Alt-f
  bindkey -M viins '^[s' autosuggest-toggle         # Alt-s
}

# Initial bind
_myz_autosuggest_bind_viins

# Rebind when keymap changes (e.g., vicmd <-> viins)
_myz_autosuggest_rebind_on_keymap() {
  [[ $KEYMAP = viins ]] || return 0
  _myz_autosuggest_bind_viins
}
zle -N zle-keymap-select _myz_autosuggest_rebind_on_keymap
zle -N zle-line-init     _myz_autosuggest_rebind_on_keymap

# Quick health log (one-time, quiet if everything is fine)
if [[ -n ${+widgets[autosuggest-accept]} ]]; then
  : # all good; stay silent
else
  print -u2 -- "[autosuggestions] widgets missing after load."
fi

# End of file
