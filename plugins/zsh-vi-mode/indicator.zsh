# Purpose:
#   Minimal, fast, and flicker-free mode indicator + cursor styling for zsh-vi-mode.
# Requirements:
#   - zsh-vi-mode is loaded (post-compinit stage).
#   - Terminal supports DECSCUSR for cursor style changes (optional part).
# Notes:
#   - Keeps PROMPT structure intact; only prefixes a short mode tag.
#   - Uses RPROMPT to avoid shifting the main prompt; change to PROMPT if preferred.

# Guard: interactive shells only
[[ -o interactive ]] || return 0

# Keep original prompts so this file can be sourced multiple times without stacking
typeset -g ZVM_PROMPT_ORIG="${ZVM_PROMPT_ORIG:-$PROMPT}"
typeset -g ZVM_RPROMPT_ORIG="${ZVM_RPROMPT_ORIG:-$RPROMPT}"

# Map ZVM_MODE to a short label and color
_zvm_mode_label() {
  # Prints a small colored tag, e.g., [N], [I], [V], [VL], [R]
  case "$ZVM_MODE" in
    "$ZVM_MODE_INSERT")       print -r -- "%F{green}[I]%f" ;;
    "$ZVM_MODE_NORMAL")       print -r -- "%F{yellow}[N]%f" ;;
    "$ZVM_MODE_VISUAL")       print -r -- "%F{magenta}[V]%f" ;;
    "$ZVM_MODE_VISUAL_LINE")  print -r -- "%F{magenta}[VL]%f" ;;
    "$ZVM_MODE_REPLACE")      print -r -- "%F{red}[R]%f" ;;
    *)                        print -r -- "[?]" ;;
  esac
}

# Optional: adjust cursor per mode using DECSCUSR + xterm color OSC 12
# Many terminals support: 1=blinking block, 2=steady block, 3=blinking underline, 4=steady underline, 5=blinking bar, 6=steady bar
# Here: steady block in NORMAL (green), steady bar in INSERT (white)
_zvm_apply_cursor_style() {
  # Detect support heuristically (best-effort); skip in dumb terminals
  [[ -t 1 && "$TERM" != "dumb" ]] || return 0

  case "$ZVM_MODE" in
    "$ZVM_MODE_NORMAL")
      # steady block + cursor color green
      printf '\e[2 q\e]12;#00ff00\a' ;;
    "$ZVM_MODE_INSERT")
      # steady bar + cursor color white
      printf '\e[6 q\e]12;white\a' ;;
    "$ZVM_MODE_VISUAL" | "$ZVM_MODE_VISUAL_LINE")
      # underline + cursor color magenta
      printf '\e[4 q\e]12;magenta\a' ;;
    "$ZVM_MODE_REPLACE")
      # block + cursor color red
      printf '\e[2 q\e]12;red\a' ;;
    *)
      # fallback
      printf '\e[2 q' ;;
  esac
}

# Hook invoked by zsh-vi-mode whenever mode changes.
# Many versions of zsh-vi-mode call this function name if present.
zvm_after_select_vi_mode() {
  # Update RPROMPT with the live mode label; leave PROMPT untouched
  RPROMPT="%{$(_zvm_mode_label)%}${ZVM_RPROMPT_ORIG:+ $ZVM_RPROMPT_ORIG}"
  _zvm_apply_cursor_style
}

# Initialize once (when plugin is ready). Some versions expose an array hook; degrade gracefully.
if whence -w zvm_after_init >/dev/null 2>&1; then
  # If the plugin offers post-init command hooks, use them
  zvm_after_init_commands+=('zvm_after_select_vi_mode')
else
  # Otherwise, trigger once now; further updates happen via zvm_after_select_vi_mode()
  zvm_after_select_vi_mode
fi

