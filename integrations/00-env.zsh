# =====================================================================
# integrations/00-env.zsh
# Shared environment helpers and path resolution for local plugins.
# Safe to source multiple times (guarded).
# =====================================================================

[[ -o interactive ]] || return 0
[[ -n ${MYZ_LOADED[int:00-env]-} ]] && return 0
MYZ_LOADED[int:00-env]=1

# find_plugin_dir <name> -> echoes first matching plugin directory
# Search order: repo plugins, ~/.zsh/plugins, Homebrew prefix (macOS)
find_plugin_dir() {
  local name="$1"
  local -a roots
  roots=(
    "$MYZ_PLUGINS/$name"
    "$HOME/.zsh/plugins/$name"
    "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh/plugins/$name"
    "/usr/local/share/zsh/plugins/$name"
    "/usr/share/zsh/plugins/$name"
  )
  local p
  for p in "${roots[@]}"; do
    [[ -d "$p" ]] && { print -r -- "$p"; return 0; }
  done
  return 1
}

