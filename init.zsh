# Portable, repo-based Zsh bootstrap with curated plugin order.
# Order: 1) secrets  2) env initializers  3) PATH  4) behavior  5) aliases  6) functions  7) plugins & integrations

# ------------------------------------------------------------------------------
# 0) Guards & paths
# ------------------------------------------------------------------------------
# Require REPOS_DIR (enforced already in ~/.zshrc, but guard again if sourced stand-alone)
: "${REPOS_DIR:?Please export repos, e.g. /mnt/steve/repos}"
export MY_ZSH_DIR="$REPOS_DIR/my-zsh"
export MYZ_ROOT="${MYZ_ROOT:-${${(%):-%N}:A:h}}"
export MYZ_PLUGINS_DIR="$MY_ZSH_DIR/plugins"

# Only do interactive setup for interactive shells
[[ -o interactive ]] || return 0

# Small logger (stderr)
_myz_log() { print -u2 -- "[myz] $*"; }

# Source-if-readable
_src() { local f="$1"; [[ -f "$f" && -r "$f" ]] && source "$f"; }

# Try to source a plugin directory by common entrypoints (first match wins)
# e.g.: fzf-tab.plugin.zsh, fzf-tab.zsh, plugin.zsh, *.plugin.zsh, *.zsh, init.zsh
_myz_source_plugin_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  local -a candidates=(
    "$dir/${dir:t}.plugin.zsh"
    "$dir/${dir:t}.zsh"
    "$dir/plugin.zsh"
    "$dir/init.zsh"
  )
  candidates+=("${(@f)$(print -l -- "$dir"/*.plugin.zsh(N))}")
  candidates+=("${(@f)$(print -l -- "$dir"/*.zsh(N))}")
  local c
  for c in "${candidates[@]}"; do
    [[ -r "$c" ]] && { source "$c"; return 0; }
  done
  return 0
}

# ------------------------------------------------------------------------------
# 1) Secrets, env, PATH
# ------------------------------------------------------------------------------
_src "$MY_ZSH_DIR/secrets.zsh"        # API keys etc.
_src "$MY_ZSH_DIR/env-sources.zsh"    # rustup, deno, brew … (idempotent)
_src "$MY_ZSH_DIR/paths.zsh"          # curated PATH

# ------------------------------------------------------------------------------
# 2) Behavior / aliases / functions / integrations (repo-local)
# ------------------------------------------------------------------------------
_src "$MY_ZSH_DIR/behavior.zsh"
_src "$MY_ZSH_DIR/aliases.zsh"
_src "$MY_ZSH_DIR/functions.zsh"
_src "$MY_ZSH_DIR/integrations.zsh"

# ------------------------------------------------------------------------------
# 3) Completion stack (zsh-completions → compinit → fzf-tab)
# ------------------------------------------------------------------------------
# Put zsh-completions on fpath BEFORE compinit
if [[ -d "$MYZ_PLUGINS_DIR/zsh-completions" ]]; then
  fpath=("$MYZ_PLUGINS_DIR/zsh-completions/src" $fpath)
fi

# Fast/robust compinit with cache
autoload -Uz compinit
# Use XDG cache if available
local compdump_base="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
local compdump_file="$compdump_base/.zcompdump-$ZSH_VERSION"
mkdir -p -- "$compdump_base" 2>/dev/null || true
# Only run once per session
if [[ -z "${MYZ_COMPINIT_DONE:-}" ]]; then
  # -C: skip security checks on insecure dirs; -d: dump file path
  compinit -d "$compdump_file"
  typeset -g MYZ_COMPINIT_DONE=1
fi

# fzf-tab (must be AFTER compinit)
if [[ -d "$MYZ_PLUGINS_DIR/fzf-tab" ]]; then
  # complist for nice menu-select
  zmodload -F zsh/complist +b:menuselect 2>/dev/null || zmodload zsh/complist 2>/dev/null
  _myz_source_plugin_dir "$MYZ_PLUGINS_DIR/fzf-tab"
  # sensible defaults; tweak to your liking
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  zstyle ':fzf-tab:*' switch-group ',' '.'
fi

# Extra: colored man pages early (no ZLE deps)
_src "$MYZ_PLUGINS_DIR/colored-man-pages.zsh"

# ------------------------------------------------------------------------------
# 4) Suggestions / Syntax highlighting (ORDER MATTERS)
# ------------------------------------------------------------------------------
# zsh-autosuggestions (load BEFORE zsh-syntax-highlighting; both before vi-mode)
if [[ -d "$MYZ_PLUGINS_DIR/zsh-autosuggestions" ]]; then
  : ${ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE:=fg=8}

  # Strategie sanieren: Strings -> Array
  if [[ ${(t)ZSH_AUTOSUGGEST_STRATEGY} != *array* ]]; then
    _myz__s="${ZSH_AUTOSUGGEST_STRATEGY}"
    _myz__s="${_myz__s//\(/}"; _myz__s="${_myz__s//\)/}"
    if [[ -z "${_myz__s// }" ]]; then
      typeset -ga ZSH_AUTOSUGGEST_STRATEGY=(history)
    else
      # ⬇️ HIER die korrigierte Zeile
      typeset -ga ZSH_AUTOSUGGEST_STRATEGY=(${(z)_myz__s})
    fi
    unset _myz__s
  fi

  # Niemals automatisch beim Tippen akzeptieren
  typeset -ga ZSH_AUTOSUGGEST_ACCEPT_WIDGETS
  ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(${ZSH_AUTOSUGGEST_ACCEPT_WIDGETS:#self-insert})
  typeset -ga ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS
  ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=(${ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS:#self-insert})

  source "$MYZ_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi


# ------------------------------------------------------------------------------
# 5) Vi mode core + deferred indicator (after prompt engines)
# ------------------------------------------------------------------------------
# Load vi-mode after completion/suggestions/highlighting
if [[ -d "$MYZ_PLUGINS_DIR/zsh-vi-mode" ]]; then
  # Safe defaults (avoid tricky cursor sequences on some terminals)
  : ${ZVM_VI_ESCAPE_BINDKEY:=jk}     # quick escape in insert-mode
  : ${ZVM_LINE_INIT_MODE:=viins}     # start in insert
  _myz_source_plugin_dir "$MYZ_PLUGINS_DIR/zsh-vi-mode"
fi

# Defer the indicator until AFTER the prompt engine (starship/oh-my-posh/custom) is initialized.
# We'll hook precmd once and source the indicator then.
autoload -Uz add-zsh-hook
__myz_vi_indicator_setup_once() {
  [[ -n "${MYZ_VI_INDICATOR_DONE:-}" ]] && return 0
  if [[ -r "$MYZ_PLUGINS_DIR/zsh-vi-mode-indicator.zsh" ]]; then
    source "$MYZ_PLUGINS_DIR/zsh-vi-mode-indicator.zsh"
  fi
  typeset -g MYZ_VI_INDICATOR_DONE=1
}
add-zsh-hook -U precmd __myz_vi_indicator_setup_once

# ------------------------------------------------------------------------------
# 6) zsh-syntax-highlighting
# ------------------------------------------------------------------------------

# zsh-syntax-highlighting MUST be the last thing affecting highlighting
if [[ -d "$MYZ_PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
  _myz_source_plugin_dir "$MYZ_PLUGINS_DIR/zsh-syntax-highlighting"
fi

# ------------------------------------------------------------------------------
# 7) Language/tool shims (optional, gated by availability)
# ------------------------------------------------------------------------------
# autojump
if [[ -r "$MYZ_PLUGINS_DIR/autojump.zsh" && -x "$(command -v autojump 2>/dev/null)" ]]; then
  source "$MYZ_PLUGINS_DIR/autojump.zsh"
fi

# sudo goodness (e.g., !!, fix-dirty perms helpers)
_src "$MYZ_PLUGINS_DIR/sudo.zsh"

# Ruby / RVM (only if present)
if [[ -r "$MYZ_PLUGINS_DIR/rvm.zsh" && -x "$(command -v rvm 2>/dev/null)" ]]; then
  source "$MYZ_PLUGINS_DIR/rvm.zsh"
fi
_src "$MYZ_PLUGINS_DIR/ruby.zsh"

# Rust (rustup/cargo – file can be lightweight env glue)
_src "$MYZ_PLUGINS_DIR/rust.zsh"

# ------------------------------------------------------------------------------
# 8) Final niceties
# ------------------------------------------------------------------------------

# _src "$MY_ZSH_DIR/fishify.zsh"

# Make sure $KEYTIMEOUT is reasonable for vi-mode sequences
: ${KEYTIMEOUT:=15}

# Quiet completion errors
setopt no_list_beep

# Optional: recompile dumped files to speed up sourcing (best-effort)
if command -v zrecompile >/dev/null 2>&1; then
  for f in "$compdump_file" "$MY_ZSH_DIR"/*.zsh(N) "$MYZ_PLUGINS_DIR"/*.zsh(N); do
    [[ -e "$f" && (! -e "${f}.zwc" || "$f" -nt "${f}.zwc") ]] && zrecompile -q "$f" 2>/dev/null || true
  done
fi

# _myz_log "init complete (plugins: completions→compinit→fzf-tab→autosuggest→syntax-highlighting→vi-mode→indicator)"
