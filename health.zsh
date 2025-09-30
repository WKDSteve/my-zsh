#!/usr/bin/env zsh
# Purpose:
#   Health diagnostics for MyZshConfig (plugins, keymaps, prompts, cursor).
#   - Dual mode: can be "sourced" OR executed directly.
#   - Non-invasive, idempotent.
#
# Usage:
#   source ./health.zsh   # then: myz:health [full|quick|cursor|keymaps]
#   ./health.zsh          # runs: myz:health full

# Ensure zsh semantics
emulate -L zsh

# Detect interactive shell (some checks only make sense interactively)
IS_INTERACTIVE=0
if [[ -o interactive ]]; then
  IS_INTERACTIVE=1
fi

# Idempotent guard (only when sourcing)
if (( IS_INTERACTIVE )) && (( ${+MYZ_HEALTH_INIT} )); then
  return 0 2>/dev/null
fi
typeset -g MYZ_HEALTH_INIT=1

# Colors
c_green=$'%F{76}'; c_yellow=$'%F{178}'; c_red=$'%F{160}'; c_cyan=$'%F{45}'; c_mag=$'%F{135}'
c_grey=$'%F{246}'; c_reset=$'%f'

_ok()   { print -r -- "${c_green}OK${c_reset}  $*"; }
_warn() { print -r -- "${c_yellow}WARN${c_reset} $*"; }
_err()  { print -r -- "${c_red}ERR${c_reset}  $*"; }
_info() { print -r -- "${c_cyan}INFO${c_reset} $*"; }

_has_widget() { [[ -n ${+widgets[$1]} ]]; }
_has_func()   { [[ -n ${+functions[$1]} ]]; }
_has_cmd()    { command -v -- "$1" >/dev/null 2>&1; }
_sample_bind() {
  local map="$1" pat="$2"
  if (( IS_INTERACTIVE )); then
    bindkey -M "$map" | grep -E -- "$pat" || true
  else
    _warn "Keymap sample skipped (non-interactive shell)."
  fi
}
_cursor_capable() { [[ -t 1 && "$TERM" != "dumb" ]]; }
_ver_line() {
  local lbl="$1" cmd="$2" arg="${3:---version}"
  if _has_cmd "$cmd"; then
    local v; v="$("$cmd" $arg 2>/dev/null | head -n1)"
    _ok "$lbl: ${c_grey}${v}${c_reset}"
  else
    _warn "$lbl: not found"
  fi
}

myz:health() {
  local mode="${1:-full}"

  print -r -- ""
  print -r -- "${c_mag}=== MyZshConfig Health Report (${mode}) ===${c_reset}"

  _ok "Shell: ${c_grey}$ZSH_VERSION${c_reset}, TERM=${c_grey}${TERM:-n/a}${c_reset}, interactive=${c_grey}${IS_INTERACTIVE}${c_reset}"
  _ok "Keymap: ${c_grey}${KEYMAP:-n/a}${c_reset}"
  if (( IS_INTERACTIVE )) && (( ${+ZLE_STATE} )); then _info "ZLE_STATE: ${c_grey}${ZLE_STATE}${c_reset}"; fi

  if _has_cmd starship; then _ok "Starship present"; else _warn "Starship not found"; fi
  if _has_cmd oh-my-posh; then _ok "oh-my-posh present"; fi

  if _has_func _myz_plugin_should_load; then
    _ok "Registry helper _myz_plugin_should_load present"
  else
    _warn "Registry helper not found (ok if not using registry.zsh)"
  fi

  if _has_func zvm_info || _has_func zvm_widgets; then
    _ok "zsh-vi-mode appears loaded"
  else
    _warn "zsh-vi-mode not detected (check load order in init.zsh)"
  fi

  if _has_widget autosuggest-accept; then
    _ok "zsh-autosuggestions widgets present"
  else
    _warn "zsh-autosuggestions widgets missing"
  fi

  if [[ -n "${MYZ_VI_INDICATOR_INIT:-}" ]]; then
    _ok "vi-mode indicator sourced (MYZ_VI_INDICATOR_ON=${MYZ_VI_INDICATOR_ON:-?})"
  else
    _warn "vi-mode indicator not sourced"
  fi
  if [[ -n "${MYZ_VI_TAG:-}" ]]; then
    _ok "MYZ_VI_TAG exported: ${c_grey}${MYZ_VI_TAG}${c_reset}"
  else
    _warn "MYZ_VI_TAG empty (normal if indicator not sourced yet)"
  fi

  if [[ "$RPROMPT" == *"$MYZ_VI_TAG"* ]]; then
    _ok "RPROMPT contains mode tag"
  else
    if _has_cmd starship; then
      _warn "RPROMPT lacks tag (ok if Starship right_format shows \$MYZ_VI_TAG)"
      _info "If needed, starship.toml: right_format = \"\$env_var\"; [env_var] variable = \"MYZ_VI_TAG\""
    else
      _warn "RPROMPT lacks tag; ensure indicator is sourced AFTER prompt engine"
    fi
  fi

  if [[ "$mode" != "cursor" ]]; then
    print -r -- "${c_mag}--- Keymaps (viins) ---${c_reset}"
    _sample_bind viins 'autosuggest-(accept|accept-word|toggle|execute)'
    print -r -- "${c_mag}--- Keymaps (vicmd) ---${c_reset}"
    _sample_bind vicmd '.+'
  fi

  if _cursor_capable; then
    _ok "Terminal likely supports DECSCUSR cursor control"
  else
    _warn "Cursor control not available on this TTY/TERM"
  fi
  _info "MYZ_VI_CURSOR_ON=${c_grey}${MYZ_VI_CURSOR_ON:-0}${c_reset}"

  if [[ "$mode" = full ]]; then
    _ver_line "zsh" zsh --version
    _ver_line "fzf" fzf --version
    _ver_line "tmux" tmux -V
  fi

  print -r -- "${c_mag}=== End of report ===${c_reset}"
}

myz:health\ keymaps() {
  print -r -- "${c_mag}--- Keymaps (viins) ---${c_reset}"; _sample_bind viins 'autosuggest-(accept|accept-word|toggle|execute)'
  print -r -- "${c_mag}--- Keymaps (vicmd) ---${c_reset}"; _sample_bind vicmd '.+'
}

myz:health\ cursor() {
  if ! _cursor_capable; then _warn "TTY/TERM does not look cursor-capable"; return 0; fi
  _info "For ~3 seconds switching cursor: bar → block → underline (no permanent change)."
  printf '\e[6 q'; sleep 1; printf '\e[2 q'; sleep 1; printf '\e[4 q'; sleep 1; printf '\e[6 q'
  _ok "Cursor test done."
}

myz:health\ quick() { myz:health quick; }

# If executed as a script, run a default report.
# Detect "script vs sourced": if we can 'return', we are sourced; otherwise executed.
if ! (return 0 2>/dev/null); then
  myz:health full
fi
