# Load secret environment variables from a directory with ".env"-style files.
#   - Only zsh (uses glob qualifiers).
#   - Each file should contain simple KEY=VALUE lines (no spaces around "="; comments via '#').
#   - Files are sourced with "allexport" so that assignments become exported automatically.
#   - Hidden files (e.g., ".openai") are included without requiring global GLOB_DOTS.

# Directory containing per-file secrets
: "${MYZSH_SECRETS_DIR:="$HOME/personel_env"}"

# Nothing to do if the directory is missing
[[ -d "$MYZSH_SECRETS_DIR" ]] || return 0

# Iterate readable regular files inside the secrets dir, including dotfiles:
#   (N)  -> nullglob (no error if empty)
#   (.)  -> regular files
#   (D)  -> include dotfiles (but not '.' or '..')
for file in "$MYZSH_SECRETS_DIR"/*(.ND); do
  # Enable "allexport" temporarily so assignments become exported automatically
  setopt localoptions allexport

  # Source the file in the current shell (sourcing the same file twice just overwrites)
  # Security note: only source files you trust.
  source "$file"
done

# Important key checks
if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  print -u2 -- "Warning: OPENAI_API_KEY not set."
fi
