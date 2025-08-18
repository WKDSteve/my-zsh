# === DIRECTORY HELPERS ===

# Cross-platform opener 'o' with solid WSL fallbacks
o() {
  # Default to current directory if no args
  local args=("$@")
  if [ ${#args[@]} -eq 0 ]; then
    args=(".")
  fi

  # WSL detection (Linux kernel string mentioning Microsoft)
  if grep -qi microsoft /proc/version 2>/dev/null; then
    # 1) Normal case: explorer.exe in PATH (Interop + appendWindowsPath)
    if command -v explorer.exe >/dev/null 2>&1; then
      explorer.exe "${args[@]}"
      return
    fi
    # 2) Absolute path to Windows explorer (Interop kann fehlen)
    if [ -x /mnt/c/Windows/explorer.exe ]; then
      # Convert the first path to Windows format to avoid surprises
      local win
      win="$(wslpath -w "${args[0]}")"
      "/mnt/c/Windows/explorer.exe" "$win"
      return
    fi
    # 3) wslview (aus dem Paket 'wslu') als eleganter Fallback
    if command -v wslview >/dev/null 2>&1; then
      wslview "${args[@]}"
      return
    fi
    # 4) cmd.exe /c start (funktioniert oft auch ohne explorer im PATH)
    if [ -x /mnt/c/Windows/System32/cmd.exe ]; then
      local win
      win="$(wslpath -w "${args[0]}")"
      "/mnt/c/Windows/System32/cmd.exe" /c start "" "$win"
      return
    fi
    printf '%s\n' "WSL: Kein Windows-Opener gefunden. Interop aktivieren oder 'wslu' installieren." >&2
    return 1
  fi

  # Non-WSL platforms
  case "$(uname -s)" in
    Darwin)
      open "${args[@]}"
      ;;
    Linux)
      if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "${args[@]}" >/dev/null 2>&1 &
      else
        printf '%s\n' "Linux: 'xdg-open' nicht gefunden." >&2
        return 1
      fi
      ;;
    CYGWIN*|MINGW*|MSYS*)
      # Git Bash / MSYS / Cygwin unter nativem Windows
      powershell.exe -NoProfile -Command "Start-Process -FilePath '$*'"
      ;;
    *)
      printf 'Unsupported OS: %s\n' "$(uname -s)" >&2
      return 1
      ;;
  esac
}

# Create directory and immediately cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Change to given dir (or $HOME) and list contents sorted by time
cdl() {
  cd "${1:-$HOME}" && ls -thor
}

# === FILE MANAGEMENT ===

# Recursively count all files in a directory
countfiles() {
  find "${1:-.}" -type f | wc -l
}


# === SEARCH UTILITIES ===

# Grep through all files for a pattern
gg() {
  grep -rnI --color=auto "$1" "${2:-.}"
}


# === SYSTEM SHORTCUTS ===

# Show IP address (local + public)
myip() {
  echo "Local:  $(hostname -I | awk '{print $1}')"
  echo "Public: $(curl -s ifconfig.me)"
}

# Start a Python HTTP server (port optional)
pythonserver() {
  local port="${1:-8000}"
  echo "Serving HTTP on http://localhost:$port"
  python3 -m http.server "$port"
}
