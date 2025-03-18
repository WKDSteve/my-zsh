# Aliase for System-related tasks

alias source-zsh="source $HOME/.zshrc"
alias updateOS='sudo apt-get update && sudo apt-get -y dist-upgrade && sudo apt upgrade -y && sudo apt-get autoclean && sudo apt-get update'
alias o='/usr/bin/xdg-open'
alias downloads='cd ~/Downloads'
alias remove='rm -rf' # Alias für das sofortige Löschen ohne Bestätigung
alias rmLastHistory="fc -R; sed -i '' '$d' ~/.zsh_history && fc -W && source ~/.zshrc" # Löscht den letzten Eintrag in der History und updatet die History
alias man="MANWIDTH=75 man"
alias l.='ls -d .* --color=auto' # Creates a new command called l., which displays all directory entries that begin with a dot.
alias ll='ls -l --color=auto' # Creates a new command called ll, which display a long-format directory listing.