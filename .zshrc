# -------------------------------
# ~/.zshrc — portable, repo-based
# -------------------------------
# This file keeps the login minimal and delegates configuration
# to $REPOS_DIR/my-zsh. It is safe for Linux/macOS and WSL.

# 0) Only proceed for interactive shells
[[ -o interactive ]] || return

# 1) Require repos (abort with a clear message if missing)
#    Examples:
#      Linux/Ubuntu:  /mnt/steve/repos  or  /home/<name>/repos
#      WSL:           /home/<name>/repos or  /mnt/e/repos
#      Windows POSIX: /e/repos  (convert with cygpath/wslpath if needed)
: "${REPOS_DIR:?Please set repos to your repo root, e.g. /mnt/steve/repos or /mnt/e/repos}"

# 1.a) Warn if the path does not exist (continue anyway; mounts may come later)
if [[ ! -d "$REPOS_DIR" ]]; then
  print -u2 -- "[zshrc] Warning: repos points to a non-existent directory: $REPOS_DIR"
fi

# 2) Single entry point: load your portable zsh config from the repo
#    Order within init.zsh: secrets → env-sources → paths → behavior → aliases → functions → integrations
if [[ -r "$REPOS_DIR/my-zsh/init.zsh" ]]; then
  # shellcheck disable=SC1090
  source "$REPOS_DIR/my-zsh/init.zsh"
else
  print -u2 -- "[zshrc] Notice: $REPOS_DIR/my-zsh/init.zsh not found or not readable."
fi

# 3) Prompt setup (with fallbacks)
#    a) Starship
if command -v starship >/dev/null 2>&1; then
   eval "$(starship init zsh)"

#    b) oh-my-posh  - make sure it is installed: brew install jandedobbeleer/oh-my-posh/oh-my-posh)
elif command -v oh-my-posh >/dev/null 2>&1; then
  # Example themes (uncomment one):
  # eval "$(oh-my-posh init zsh --config "$(brew --prefix 2>/dev/null)"/themes/tokyo.omp.json)"
  # eval "$(oh-my-posh init zsh --config "$(brew --prefix 2>/dev/null)"/themes/jandedobbeleer.omp.json)"
  eval "$(oh-my-posh init zsh)"

#    c) Custom prompt
else
   source "$REPOS_DIR/my-zsh/custom/prompt/my_prompt.zsh"
fi

# 4) Append vi-mode indicator AFTER the prompt engine (starship/oh-my-posh/custom)
if [[ -r "$REPOS_DIR/my-zsh/zsh-vi-mode-indicator.zsh" ]]; then
  # Optional toggles:
  # MYZ_VI_CURSOR_ON=0   # keep 0 unless du sicher bist, dass dein Terminal DECSCUSR sauber kann
  # MYZ_VI_TAG_STYLE=1   # 1=colored, 0=plain
  source "$REPOS_DIR/my-zsh/zsh-vi-mode-indicator.zsh"
fi

