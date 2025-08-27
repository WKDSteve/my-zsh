# Utility functions (portable across Linux/macOS).

# Cross-platform opener 'o' with solid WSL fallbacks
o() {
  local args=("$@")
  (( ${#args[@]} == 0 )) && args=(".")

  # WSL detection
  if grep -qi microsoft /proc/version 2>/dev/null; then
    if command -v explorer.exe >/dev/null 2>&1; then
      explorer.exe "${args[@]}"; return
    fi
    if [[ -x /mnt/c/Windows/explorer.exe ]]; then
      local win; win="$(wslpath -w "${args[0]}")"
      "/mnt/c/Windows/explorer.exe" "$win"; return
    fi
    if command -v wslview >/dev/null 2>&1; then
      wslview "${args[@]}"; return
    fi
    if [[ -x /mnt/c/Windows/System32/cmd.exe ]]; then
      local win; win="$(wslpath -w "${args[0]}")"
      "/mnt/c/Windows/System32/cmd.exe" /c start "" "$win"; return
    fi
    printf '%s\n' "WSL: No Windows opener found. Enable interop or install 'wslu'." >&2
    return 1
  fi

  case "$(uname -s)" in
    Darwin) open "${args[@]}" ;;
    Linux)
      if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "${args[@]}" >/dev/null 2>&1 &
      else
        printf '%s\n' "Linux: 'xdg-open' not found." >&2; return 1
      fi
      ;;
    CYGWIN*|MINGW*|MSYS*)
      powershell.exe -NoProfile -Command "Start-Process -FilePath '$*'"
      ;;
    *)
      printf 'Unsupported OS: %s\n' "$(uname -s)" >&2
      return 1
      ;;
  esac
}

# Create directory and immediately cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# Change to given dir (or $HOME) and list contents sorted by time
cdl() { cd "${1:-$HOME}" && ls -thor; }

# Recursively count all files in a directory
countfiles() { find "${1:-.}" -type f | wc -l; }

# Grep through all files for a pattern
gg() { grep -rnI --color=auto "$1" "${2:-.}"; }

# Show IP address (local + public)
myip() {
  local local_ip
  local_ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  echo "Local:  ${local_ip:-unavailable}"
  echo "Public: $(curl -fsSL ifconfig.me || echo unavailable)"
}

# Start a Python HTTP server (port optional)
pythonserver() {
  local port="${1:-8000}"
  echo "Serving HTTP on http://localhost:$port"
  python3 -m http.server "$port"
}

# List Git conflict files and display all conflict sections with content
show_conflicts() {
  conflict_files=()
  while IFS= read -r line; do conflict_files+=("$line"); done < <(git diff --name-only --diff-filter=U)

  if [[ ${#conflict_files[@]} -eq 0 ]]; then
    echo "No unresolved conflicts found."
    return
  fi

  echo "Conflict files detected:"
  echo "---------------------------"
  printf "%s\n" "${conflict_files[@]}"
  echo

  for file in "${conflict_files[@]}"; do
    if [[ -f "$file" ]]; then
      echo "### Conflicts in file: $file ###"
      echo
      awk '
        BEGIN { inside=0 }
        /^<<<<<<< / { inside=1; print FNR ":" $0; next }
        /^=======/  { if (inside) print FNR ":" $0; next }
        /^>>>>>>> / { if (inside) { print FNR ":" $0; inside=0; print "" } next }
        { if (inside) print FNR ":" $0 }
      ' "$file"
    else
      echo "File not found: $file"
    fi
    echo
  done
}
