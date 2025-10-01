# =====================================================================
# integrations/50-vi-mode.zsh
# zsh-vi-mode (https://github.com/jeffreytse/zsh-vi-mode) or similar forks.
# Initializes vi keymap safely and idempotently.
# =====================================================================

[[ -o interactive ]] || return 0
[[ -n ${MYZ_LOADED[int:50-vi]-} ]] && return 0

# Try common repo layouts; allow user to override via $MYZ_VI_MODE_DIR
local plug_dir
if [[ -n ${MYZ_VI_MODE_DIR-} && -d $MYZ_VI_MODE_DIR ]]; then
  plug_dir="$MYZ_VI_MODE_DIR"
else
  plug_dir="$(find_plugin_dir zsh-vi-mode)" || true
fi

if [[ -d "$plug_dir" ]]; then
  # Try known entry points; some repos provide multiple filenames
  source "$plug_dir/zsh-vi-mode.plugin.zsh" 2>/dev/null || \
  source "$plug_dir/zsh-vi-mode.zsh"        2>/dev/null || \
  source "$plug_dir/init.zsh"               2>/dev/null || true

  # Force vi keymap in this shell; safe even if already in vi.
  bindkey -v

  # Sanity: list a few widgets to confirm load (suppressed if not TTY)
  if [[ -t 1 ]]; then
    # Uncomment for debugging:
    # print -rl -- ${(k)widgets[(I)zvm-*]} 2>/dev/null || true
    :
  fi

  MYZ_LOADED[int:50-vi]=1
fi

