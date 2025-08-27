# Purpose: Source well-known environment setup scripts (file-based).
# Notes:
#   - Only zsh is supported.
#   - Keep this file free of PATH order logic; PATH is curated in paths.zsh.
#   - Consolidates and replaces ad-hoc sourcing previously spread across rc files. :contentReference[oaicite:0]{index=0}

# Guard for zsh
[[ -n "${ZSH_VERSION-}" ]] || return 0

# Debug toggle: export MYZSH_DEBUG=1 for verbose logs
: "${MYZSH_DEBUG:=0}"

# Global map: prevents double sourcing
typeset -gA MYZSH_SOURCED

# Safe source wrapper
_safe_source() {
  local f="$1"
  if [[ -f "$f" && -r "$f" ]]; then
    if [[ -z "${MYZSH_SOURCED[$f]-}" ]]; then
      (( MYZSH_DEBUG )) && print -u2 -- "[my-zsh] sourcing: $f"
      # shellcheck disable=SC1090
      source "$f"
      MYZSH_SOURCED[$f]=1
    else
      (( MYZSH_DEBUG )) && print -u2 -- "[my-zsh] already sourced: $f"
    fi
  else
    (( MYZSH_DEBUG )) && print -u2 -- "[my-zsh] skip (not readable): $f"
  fi
}

# Canonical env initializers (minimal set; extend via MYZSH_EXTRA_SOURCES)
typeset -a _myzsh_sources
_myzsh_sources=(
  "$HOME/.cargo/env"  # Rust (cargo/rustup)
)

# Optional: user-provided extras (colon-separated absolute paths)
#   export MYZSH_EXTRA_SOURCES="/opt/foo/env.sh:/usr/local/share/bar/init.zsh"
if [[ -n "${MYZSH_EXTRA_SOURCES-}" ]]; then
  _myzsh_sources+=("${(ps,:,)MYZSH_EXTRA_SOURCES}")
fi

# Source all readable candidates
for f in "${_myzsh_sources[@]}"; do
  [[ -n "$f" ]] || continue
  _safe_source "$f"
done

# Homebrew / Linuxbrew: set HOMEBREW_* vars, MANPATH/INFOPATH, initial PATH
# (PATH order will be rebuilt by paths.zsh afterwards)
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi
