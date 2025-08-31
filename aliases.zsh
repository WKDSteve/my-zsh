# Aliases

# Safer package update (only on Debian/Ubuntu)
if command -v apt-get >/dev/null 2>&1; then
  alias updateOS='sudo apt-get update && sudo apt-get -y dist-upgrade && sudo apt upgrade -y && sudo apt-get autoclean && sudo apt-get update'
fi

# man width hint
alias man="MANWIDTH=75 man"

# listings
alias ls='ls -l --hyperlink --color=auto'

# delta with file hyperlinks (compatible with many terminals)
if command -v delta >/dev/null 2>&1; then
  alias delta="delta --hyperlinks --hyperlinks-file-link-format='file://{path}#{line}'"
fi

# batcat
alias bat="batcat"

# eza integration (feature-detected flags)
if command -v eza >/dev/null 2>&1; then
  _eza_supports() { eza --help 2>&1 | grep -q -- "$1"; }

  eza_params=()
  _eza_supports '--group-directories-first' && eza_params+=(--group-directories-first)
  if _eza_supports '--icons'; then
    if eza --help 2>&1 | grep -q -- '--icons=auto'; then eza_params+=(--icons=auto); else eza_params+=(--icons); fi
  fi
  _eza_supports '--color' && eza_params+=(--color=auto)
  _EP() { printf '%s ' "${eza_params[@]}"; }

  alias els="eza $(_EP)"
  alias el="eza --git-ignore $(_EP)"
  alias ell="eza --all --header --long $(_EP)"
  alias elm="eza --all --header --long --sort=modified $(_EP)"
  alias ela="eza -lbhHigUmuSa"
  alias elx="eza -lbhHigUmuSa@"
  alias etree="eza --tree $(_EP)"
fi
