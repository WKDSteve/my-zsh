# =====================================================================
# integrations/40-syntax-highlighting.zsh
# zsh-syntax-highlighting (https://github.com/zsh-users/zsh-syntax-highlighting)
# Must be the LAST plugin sourced to avoid being overridden.
# =====================================================================

[[ -o interactive ]] || return 0
[[ -n ${MYZ_LOADED[int:40-syntax]-} ]] && return 0

local plug_dir
if plug_dir="$(find_plugin_dir zsh-syntax-highlighting)"; then
  # Source *last*
  source "$plug_dir/zsh-syntax-highlighting.zsh" || return 0

  # Optional: speed vs. accuracy trade-offs
  # ZSH_HIGHLIGHT_MAXLENGTH=0   # 0 = unlimited (default); set to limit for very long lines
  # ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

  MYZ_LOADED[int:40-syntax]=1
fi

