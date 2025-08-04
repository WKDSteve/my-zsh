#!/usr/bin/env bash
# @name      show_conflicts.sh
# @desc      Lists Git conflict files and displays all conflict sections with content
# @usage     ./show_conflicts.sh

show_conflicts() {
  # Fallback for mapfile in Zsh
  conflict_files=()
  while IFS= read -r line; do
    conflict_files+=("$line")
  done < <(git diff --name-only --diff-filter=U)

  if [[ ${#conflict_files[@]} -eq 0 ]]; then
    echo "✅ No unresolved conflicts found."
    return
  fi

  echo "❌ Conflict files detected:"
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
      echo "⚠️ File not found: $file"
    fi

    echo
  done
}