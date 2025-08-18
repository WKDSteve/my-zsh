# Aliase for System-related tasks

alias updateOS='sudo apt-get update && sudo apt-get -y dist-upgrade && sudo apt upgrade -y && sudo apt-get autoclean && sudo apt-get update'
#alias o='/usr/bin/xdg-open' # replaced from `o`-function (see /functions/system.sh)
alias man="MANWIDTH=75 man"
alias ls='ls -l --hyperlink --color=auto'
alias delta="delta --hyperlinks --hyperlinks-file-link-format='file://{path}#{line}'"
alias rg='rg --hyperlink-format=kitty'

# Aliases
alias fzf="fzf --style full --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}'"

# Guard: define aliases only if 'eza' is available
if command -v eza >/dev/null 2>&1; then
  # Helper: check if a long option is supported by this eza build
  # Uses help text to avoid running eza with unsupported flags.
  _eza_supports() {
    # $1 is the long option (e.g. --icons)
    eza --help 2>&1 | grep -q -- "$1"
  }

  # Build an array of safe default parameters based on feature detection.
  # Works in bash and zsh (both support arrays).
  eza_params=()

  # Prefer grouped directories first (if supported)
  if _eza_supports '--group-directories-first'; then
    eza_params+=(--group-directories-first)
  fi

  # Icons (only if this build supports it)
  if _eza_supports '--icons'; then
    # Some builds accept values: auto|always|never; fallback to plain --icons if =auto not found
    if eza --help 2>&1 | grep -q -- '--icons=auto'; then
      eza_params+=(--icons=auto)
    else
      eza_params+=(--icons)
    fi
  fi

  # Color handling (most builds have this; check anyway)
  if _eza_supports '--color'; then
    eza_params+=(--color=auto)
  fi

  # Header flag is widely supported; specific aliases may add it below.

  # Use quotes to keep spaces intact when expanding the array
  _EP() { printf '%s ' "${eza_params[@]}"; }

  # Aliases with inline comments (English, as requested)

  alias els="eza $(_EP)"                                # Short listing with safe defaults
  alias el="eza --git-ignore $(_EP)"                    # Listing that respects .gitignore
  alias ell="eza --all --header --long $(_EP)"          # Long listing of all entries with header
  alias elm="eza --all --header --long --sort=modified $(_EP)"  # Long listing sorted by modification time
  alias ela="eza -lbhHigUmuSa"                          # Rich long format (human sizes, inode, groups, etc.)
  alias elx="eza -lbhHigUmuSa@"                         # Rich long format + extended attributes (@)
  alias etree="eza --tree $(_EP)"                       # Tree view with safe defaults
fi
