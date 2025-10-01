# =====================================================================
# integrations/30-autosuggestions.zsh
# zsh-autosuggestions (https://github.com/zsh-users/zsh-autosuggestions)
# Should be loaded after compinit; order with syntax-highlighting is flexible,
# but keep highlighting as the last plugin overall.
# =====================================================================

[[ -o interactive ]] || return 0
[[ -n ${MYZ_LOADED[int:30-autosuggest]-} ]] && return 0

local plug_dir
if plug_dir="$(find_plugin_dir zsh-autosuggestions)"; then
  source "$plug_dir/zsh-autosuggestions.zsh" || return 0

  # Subtle gray suggestions; adjust via env var if desired.
  # Example override before sourcing: export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
  : ${ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE:=fg=8}
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE"

  # Accept suggestion with End, or keep default (→ Right arrow accepts partially)
  bindkey '^E' autosuggest-accept 2>/dev/null || true

  MYZ_LOADED[int:30-autosuggest]=1
fi

