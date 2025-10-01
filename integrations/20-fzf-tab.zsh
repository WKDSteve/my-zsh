# =====================================================================
# integrations/20-fzf-tab.zsh
# fzf-tab integration (https://github.com/Aloxaf/fzf-tab)
# Requires compinit to be initialized beforehand.
# =====================================================================

[[ -o interactive ]] || return 0
[[ -n ${MYZ_LOADED[int:20-fzf-tab]-} ]] && return 0

local plug_dir
if plug_dir="$(find_plugin_dir fzf-tab)"; then
  source "$plug_dir/fzf-tab.plugin.zsh" 2>/dev/null || \
  source "$plug_dir/fzf-tab.zsh" 2>/dev/null || return 0

  # Basic styles; adjust to taste. Keep minimal to avoid collisions.
  zstyle ':fzf-tab:*' switch-group '<' '>'
  zstyle ':fzf-tab:*' fzf-pad 4
  zstyle ':fzf-tab:*' prefix ''
  zstyle ':fzf-tab:*' continuous-trigger 'tab'
  zstyle ':completion:*:descriptions' format '[%d]'
  zstyle ':completion:*' menu no
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

  MYZ_LOADED[int:20-fzf-tab]=1
fi

