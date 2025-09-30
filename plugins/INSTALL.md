# Installationsbefehle für die verwendeten Plugins/Tools

Hinweis: Für Linux empfehlen sich entweder Linuxbrew (Homebrew auf Linux) oder Git-Submodule im Repo. APT ist nicht für alle Plugins verfügbar.

## macOS (Homebrew)

```sh
# Core tools
brew install zoxide direnv fzf nvm

# Zsh plugin formulas (install in in $REPOS_DIR/my-zsh/plugins or .zsh/plugins)
brew install zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode zsh-completions

# Activate fzf key bindings (one-time)
"$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-update-rc
```

## Ubuntu/WSL

### Variante A: Linuxbrew (empfohlen, wenn bereits vorhanden)

```sh
# Core tools
brew install zoxide direnv fzf nvm

# Zsh plugin formulas (install in in $REPOS_DIR/my-zsh/plugins or .zsh/plugins)
brew install zsh-autosuggestions zsh-syntax-highlighting zsh-vi-mode zsh-completions

# fzf bindings
"$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-update-rc
```

### Variante B: Repo-Plugins als Submodule (forge-agnostisch)

```sh
# Clone plugins under $REPOS_DIR/my-zsh/plugins
cd "$REPOS_DIR/my-zsh/plugins"

# Syntax highlighting
git submodule add https://github.com/zsh-users/zsh-syntax-highlighting.git zsh-syntax-highlighting

# Autosuggestions
git submodule add https://github.com/zsh-users/zsh-autosuggestions.git zsh-autosuggestions

# Vi mode
git submodule add https://github.com/jeffreytse/zsh-vi-mode.git zsh-vi-mode
# !!! copy plugins/indicator  to zsh-vi-mode folder !!!!

# Extra completions (optional but recommended)
git submodule add https://github.com/zsh-users/zsh-completions.git zsh-completions

# fzf-tab (fzf-driven completion UI)
git submodule add https://github.com/Aloxaf/fzf-tab.git fzf-tab
```

### Basis-Tools via APT (falls Brew nicht genutzt wird)

```sh
sudo apt update
sudo apt install -y zoxide direnv fzf

# nvm: per Brew ODER offizielles Install-Script
# Official script (review first):
# curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

## Optional: autojump (wenn man es statt zoxide nutzen möchte)

```sh
# macOS
brew install autojump

# Ubuntu
sudo apt install -y autojump
```

> Hinweis: autojump und zoxide nicht parallel aktivieren. Das Setup oben verwendet zoxide.

## Update-Workflow

```sh
# Brew-based plugins/tools
brew update && brew upgrade

# Repo plugins (Submodule)
cd "$REPOS_DIR"
git submodule update --remote --init --recursive
```

## Schnelltests

```sh
# Komplette Datei syntaktisch prüfen (führt nichts aus)
zsh -n "$REPOS_DIR/my-zsh/integrations.zsh"

# Live neu laden (Debug an)
export MYZSH_DEBUG=1
source "$REPOS_DIR/my-zsh/integrations.zsh"

# Prüfen, ob Funktionen/Plugins aktiv sind
typeset -f z | head -n1            # zoxide 'z' function
echo $fpath | tr ' ' '\n' | grep -E 'zsh-completions|share/zsh-completions'
```
