# --- Centralized PATH management (zsh) ---
# Build a clean, deduplicated PATH in a well-defined order.

# Require repos (abort if missing); warn if directory not present
: "${REPOS_DIR:?Please set repos to your repo root, e.g. /mnt/steve/repos}"
if [[ ! -d "$REPOS_DIR" ]]; then
  print -u2 "Warning: repos points to a non-existent directory: $REPOS_DIR"
fi

# Ensure 'path' is a unique array and export PATH
typeset -U path
export PATH

# Preserve original path entries (for opt-in re-append)
typeset -a orig_path
orig_path=("${path[@]}")

# Build curated list (existing dirs only)
typeset -a wanted
wanted=()

add_if_dir() {
  local d="$1"
  [[ -d "$d" ]] && wanted+="$d"
}

# User bins (highest priority)
add_if_dir "$HOME/.local/bin"
add_if_dir "$HOME/bin"
add_if_dir "$REPOS_DIR/bin"
add_if_dir "$HOME/nvim-linux64/bin"
add_if_dir "$HOME/perl5/bin"

# Language/toolchain user bins
add_if_dir "$HOME/.cargo/bin"
add_if_dir "$HOME/.deno/bin"
add_if_dir "$HOME/go/bin"

# Application-specific / SDKs
add_if_dir "$HOME/lua-language-server/bin"
add_if_dir "$HOME/Development/lua-language-server/bin"

# Tools (including specific Zig build)
add_if_dir "$HOME/tools"
add_if_dir "$HOME/tools/zig-x86_64-linux-0.15.0-dev.1380+e98aeeb73"

# Package ecosystems
add_if_dir "/snap/bin"

# Homebrew prefixes (user-local, global, Apple Silicon, generic)
add_if_dir "$HOME/.linuxbrew/bin"
add_if_dir "$HOME/.linuxbrew/sbin"
for pfx in "/home/linuxbrew/.linuxbrew" "/opt/homebrew" "/usr/local"; do
  add_if_dir "$pfx/bin"
  add_if_dir "$pfx/sbin"
done

# System-wide toolchains
add_if_dir "/usr/local/go/bin"

# System bins (canonical order)
add_if_dir "/usr/local/sbin"
add_if_dir "/usr/local/bin"
add_if_dir "/usr/sbin"
add_if_dir "/usr/bin"
add_if_dir "/sbin"
add_if_dir "/bin"

# Apply curated list
path=("${wanted[@]}")

# Re-append unknown original entries (preserve rare paths)
for d in "${orig_path[@]}"; do
  [[ -n "$d" && -d "$d" ]] || continue
  if (( ${path[(Ie)$d]} == 0 )); then
    path+="$d"
  fi
done

# Export and refresh hash
export PATH
hash -r
