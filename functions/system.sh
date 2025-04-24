# === DIRECTORY HELPERS ===

# Create directory and immediately cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Change to given dir (or $HOME) and list contents sorted by time
cdl() {
  cd "${1:-$HOME}" && ls -thor
}

# Go up N directories (e.g. up 2 => ../../)
up() {
  local d=""
  for ((i=1; i<=$1; i++)); do d+="../"; done
  cd "$d" || return
}


# === FILE MANAGEMENT ===

# Make a .bak backup of a file
backup() {
  cp "$1" "${1}.bak"
}

# Touch all files to update their timestamp
retouch() {
  find "${1:-.}" -type f -exec touch {} +
}

# Recursively count all files in a directory
countfiles() {
  find "${1:-.}" -type f | wc -l
}


# === SEARCH UTILITIES ===

# Global case-insensitive find (requires sudo)
gfind() {
  find / -iname "$*" 2>/dev/null
}

# Local case-insensitive find
lfind() {
  find . -iname "$*" 2>/dev/null
}

# Quick man-page or web search fallback
rtfm() {
  help "$@" || man "$@" || ${BROWSER:-xdg-open} "https://www.google.com/search?q=$*"
}

# Grep through all files for a pattern
gg() {
  grep -rnI --color=auto "$1" "${2:-.}"
}


# === SYSTEM SHORTCUTS ===

# Show available disk space
disk() {
  df -h | grep -v loop
}

# Show IP address (local + public)
myip() {
  echo "Local:  $(hostname -I | awk '{print $1}')"
  echo "Public: $(curl -s ifconfig.me)"
}

# Start a Python HTTP server (port optional)
serve() {
  local port="${1:-8000}"
  echo "Serving HTTP on http://localhost:$port"
  python3 -m http.server "$port"
}

# Clear terminal and print working dir
cl() {
  clear && pwd
}
