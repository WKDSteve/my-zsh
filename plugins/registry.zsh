#   Central plugin registry for MyZshConfig.
#   - Single source of truth for enabled plugins and their paths
#   - Stable, idempotent, safe to re-source
#   - Provides tiny helpers used by init.zsh
#
# Conventions:
#   - Toggle plugins via MYZ_PLUGINS_ENABLED[<name>]=on|off
#   - Set explicit paths in MYZ_PLUGINS_PATH[<name>] (file or directory)
#   - If path is a directory, loader will try common plugin entry files
#
# Example names:
#   zsh-vi-mode, zsh-autosuggestions, zsh-syntax-highlighting, fzf-tab

# ------------------------------------------------------------------------------
# Guard: interactive shells only
[[ -o interactive ]] || return 0

# Idempotent guard
if (( ${+MYZ_REGISTRY_INIT} )); then
  return 0
fi
typeset -g MYZ_REGISTRY_INIT=1

# ------------------------------------------------------------------------------
# Globals (associative arrays)
typeset -gA MYZ_PLUGINS_ENABLED
typeset -gA MYZ_PLUGINS_PATH

# Base repo directory guess (override before sourcing if needed)
# Try a few common roots; first existing wins.
: ${REPOS_DIR:=""}
if [[ -z "$REPOS_DIR" ]]; then
  for _d in "$HOME/repos" "$HOME/.local/share/repos" "$HOME/Code" "$HOME/Projects"; do
    [[ -d "$_d" ]] && REPOS_DIR="$_d" && break
  done
  : ${REPOS_DIR:="$HOME/repos"}  # fallback default
fi

# ------------------------------------------------------------------------------
# Helper: resolve a plugin path (file or dir). If dir, guess entry file.
_myz_resolve_plugin_file() {
  # $1 = path (file or dir)
  local p="$1"
  [[ -z "$p" ]] && return 1
  if [[ -f "$p" && -r "$p" ]]; then
    print -r -- "$p"
    return 0
  fi
  if [[ -d "$p" ]]; then
    # Try common entry names
    local try
    for try in \
      *.plugin.zsh \
      *.zsh \
      init.zsh \
      "${p##*/}.plugin.zsh" \
      "${p##*/}.zsh"
    do
      # shellcheck disable=SC2035
      for f in "$p"/$try; do
        [[ -f "$f" && -r "$f" ]] && { print -r -- "$f"; return 0; }
      done
    done
  fi
  return 1
}

# Helper: safe source (idempotent enough for plugins that guard themselves)
if (( ! ${+functions[_myz_source_if]} )); then
  _myz_source_if() {
    local p="$1"
    local f
    f="$(_myz_resolve_plugin_file "$p")" || { print -u2 -- "[registry] not found: $p"; return 1; }
    # shellcheck disable=SC1090
    source "$f"
  }
fi

# Helper: check flag
if (( ! ${+functions[_myz_plugin_should_load]} )); then
  _myz_plugin_should_load() {
    local name="$1"
    [[ "${MYZ_PLUGINS_ENABLED[$name]}" == on ]]
  }
fi

# ------------------------------------------------------------------------------
# Defaults: enable/disable
# (Set to 'on' for the plugins you actively use)
: ${MYZ_PLUGINS_ENABLED[zsh-vi-mode]:=on}
: ${MYZ_PLUGINS_ENABLED[zsh-autosuggestions]:=on}
: ${MYZ_PLUGINS_ENABLED[zsh-syntax-highlighting]:=off}  # optional; must load LAST
: ${MYZ_PLUGINS_ENABLED[fzf-tab]:=off}                  # optional

# ------------------------------------------------------------------------------
# Paths: set explicitly if you cloned the repos outside of REPOS_DIR
# You can set these to either the entry file or the directory of the clone.

# zsh-vi-mode
: ${MYZ_PLUGINS_PATH[zsh-vi-mode]:="$$MYZ_ROOT/zsh-vi-mode"}
# Common entry files we will discover automatically:
#   zsh-vi-mode.plugin.zsh  (preferred)

# zsh-autosuggestions
: ${MYZ_PLUGINS_PATH[zsh-autosuggestions]:="$MYZ_ROOT/zsh-autosuggestions"}
# Common entry files:
#   zsh-autosuggestions.zsh

# zsh-syntax-highlighting (optional; should be loaded last)
: ${MYZ_PLUGINS_PATH[zsh-syntax-highlighting]:="$MYZ_ROOT/zsh-syntax-highlighting"}
# Common entry files:
#   zsh-syntax-highlighting.zsh

# fzf-tab (optional)
: ${MYZ_PLUGINS_PATH[fzf-tab]:="$MYZ_ROOT/fzf-tab"}
# Common entry files:
#   fzf-tab.plugin.zsh  or  fzf-tab.zsh

# ------------------------------------------------------------------------------
# Sanity log (debug only)
if [[ -n "${MYZ_DEBUG_REGISTRY:-}" ]]; then
  print -r -- "[registry] MYZ_ROOT=$MYZ_ROOT"
  for n in zsh-vi-mode zsh-autosuggestions zsh-syntax-highlighting fzf-tab; do
    print -r -- "[registry] $n enabled=${MYZ_PLUGINS_ENABLED[$n]:-off} path=${MYZ_PLUGINS_PATH[$n]:-(unset)}"
  done
fi

# End of file
