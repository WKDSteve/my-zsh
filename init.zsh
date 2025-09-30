# Entry point to load repo-based zsh config on any machine.
# Order: 1) secrets  2) env initializers  3) PATH  4) behavior  5) aliases  6) functions  7) integrations

# Guard: require repos (set this in ~/.zshenv)
: "${REPOS_DIR:?Please export repos, e.g. /mnt/steve/repos}"
MY_ZSH_DIR="$REPOS_DIR/my-zsh"

# Derive repository root (MYZ_ROOT) once, robust to symlinks and $REPOS_DIR
emulate -L zsh
typeset -g MYZ_ROOT
if [[ -z "${MYZ_ROOT:-}" ]]; then
  # %N = path of current file when sourced; :A = absolute; :h = dirname
  MYZ_ROOT="${${(%):-%N}:A:h}"
fi

# Helper: source-if-readable
_src() {
  # $1 = absolute path to a file to source if readable
  local f="$1"
  [[ -f "$f" && -r "$f" ]] || return 0
  # shellcheck disable=SC1090
  source "$f"
}

# 1) Secrets (API keys, tokens). Keep this early so env is ready for later steps.
_src "$MY_ZSH_DIR/secrets.zsh"

# 2) Env scripts (Rust/Deno/Brew/etc.), idempotent and PATH-agnostic
_src "$MY_ZSH_DIR/env-sources.zsh"

# 3) Curated PATH (user bins → toolchains → brew → system)
_src "$MY_ZSH_DIR/paths.zsh"

# 4..7) Behavior, aliases, functions, integrations, fishify
_src "$MY_ZSH_DIR/behavior.zsh"
_src "$MY_ZSH_DIR/aliases.zsh"
_src "$MY_ZSH_DIR/functions.zsh"
_src "$MY_ZSH_DIR/plugins/init.zsh"
_src "$MY_ZSH_DIR/integrations.zsh"
_src "$MY_ZSH_DIR/fishify.zsh"
