# Minimal, fast, flicker-free vi-mode indicator using ZLE hooks only.
# Appends a tiny mode tag to RPROMPT; keeps PROMPT untouched.
# Optional DECSCUSR cursor shapes (MYZ_VI_CURSOR_ON=1).

# ------------------------------------------------------------------------------
# Guards
# ------------------------------------------------------------------------------

# Interactive shells only
[[ -o interactive ]] || return 0

# Idempotent guard
if (( ${+MYZ_VI_INDICATOR_INIT} )); then
  return 0
fi
typeset -g MYZ_VI_INDICATOR_INIT=1

# ------------------------------------------------------------------------------
# Config toggles (env overrides allowed)
# ------------------------------------------------------------------------------

: ${MYZ_VI_INDICATOR_ON:=1}     # Master switch
: ${MYZ_VI_CURSOR_ON:=0}        # Use DECSCUSR cursor shapes
: ${MYZ_VI_TAG_STYLE:=1}        # 1=colored tag, 0=plain
: ${MYZ_VI_SPACE_BEFORE:=1}     # Add a space between original RPROMPT and tag

(( MYZ_VI_INDICATOR_ON )) || return 0

# ------------------------------------------------------------------------------
# Keep original RPROMPT only once (so we can append the tag)
# ------------------------------------------------------------------------------

typeset -g MYZ_RPROMPT_ORIG
if [[ -z ${MYZ_RPROMPT_ORIG+x} ]]; then
  MYZ_RPROMPT_ORIG=$RPROMPT
fi

# ------------------------------------------------------------------------------
# State
# ------------------------------------------------------------------------------

typeset -g MYZ_VI_TAG=""
typeset -g _MYZ_LAST_TAG=""
typeset -g _MYZ_LAST_KEYMAP=""

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

_myz_vi_compute_tag() {
  local raw
  if [[ $ZLE_STATE = *isearch* ]]; then
    raw="[/]"
  elif [[ $ZLE_STATE = *overwrite* ]]; then
    raw="[R]"
  elif (( ${REGION_ACTIVE:-0} )); then
    raw="[V]"
  elif [[ $KEYMAP = vicmd ]]; then
    raw="[N]"
  else
    raw="[I]"
  fi

  if (( MYZ_VI_TAG_STYLE )); then
    case "$raw" in
      "[I]") MYZ_VI_TAG="%F{green}${raw}%f" ;;
      "[N]") MYZ_VI_TAG="%F{yellow}${raw}%f" ;;
      "[V]") MYZ_VI_TAG="%F{magenta}${raw}%f" ;;
      "[R]") MYZ_VI_TAG="%F{red}${raw}%f" ;;
      "[/]") MYZ_VI_TAG="%F{cyan}${raw}%f" ;;
      *)     MYZ_VI_TAG="${raw}" ;;
    esac
  else
    MYZ_VI_TAG="${raw}"
  fi
}

_myz_vi_apply_cursor() {
  (( MYZ_VI_CURSOR_ON )) || return 0
  [[ -t 1 && "$TERM" != "dumb" ]] || return 0
  if [[ $KEYMAP = vicmd ]]; then
    printf '\e[2 q'      # block
  elif (( ${REGION_ACTIVE:-0} )); then
    printf '\e[4 q'      # underline
  else
    printf '\e[6 q'      # bar
  fi
}

_myz_vi_set_rprompt_from_state() {
  # IMPORTANT: Do NOT wrap %F..%f in %{…%}; they are printing characters.
  local sep=""
  (( MYZ_VI_SPACE_BEFORE )) && sep=" "
  if [[ -n "$MYZ_RPROMPT_ORIG" ]]; then
    RPROMPT="${MYZ_RPROMPT_ORIG}${sep}${MYZ_VI_TAG}"
  else
    RPROMPT="${MYZ_VI_TAG}"
  fi
}

# ------------------------------------------------------------------------------
# Core refresh (only calls zle when ZLE is active)
# ------------------------------------------------------------------------------

_myz_vi_refresh_rprompt() {
  _myz_vi_compute_tag

  # Skip if nothing changed
  if [[ "$MYZ_VI_TAG" == "$_MYZ_LAST_TAG" && "$KEYMAP" == "$_MYZ_LAST_KEYMAP" ]]; then
    return 0
  fi
  _MYZ_LAST_TAG="$MYZ_VI_TAG"
  _MYZ_LAST_KEYMAP="$KEYMAP"

  _myz_vi_set_rprompt_from_state
  _myz_vi_apply_cursor

  # Refresh only inside an active ZLE context
  # $ZLE_STATE exists only during widget execution; safe indicator.
  if [[ -n ${ZLE_STATE-} ]]; then
    zle -R
  fi
}

# ------------------------------------------------------------------------------
# Hook wiring
# ------------------------------------------------------------------------------

# Define widgets (safe even if ZLE not active *yet*)
zle -N zle-keymap-select _myz_vi_refresh_rprompt
zle -N zle-line-init     _myz_vi_refresh_rprompt
zle -N zle-line-finish   _myz_vi_refresh_rprompt

# First-time setup just before the first prompt render; no zle calls here.
autoload -Uz add-zsh-hook
_myz_vi_precmd_boot() {
  add-zsh-hook -d precmd _myz_vi_precmd_boot 2>/dev/null || true
  _myz_vi_compute_tag
  _myz_vi_set_rprompt_from_state
}

if [[ -n ${ZLE_STATE-} ]]; then
  # Extremely rare when sourced from inside an active widget
  _myz_vi_refresh_rprompt
else
  add-zsh-hook precmd _myz_vi_precmd_boot
fi

# End of file
