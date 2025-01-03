# Aliase for Git-related stuff

alias updateRepo="git fetch && git pull && git status"
alias pushRepo="git add . && git commit -m \'Default\'"

## Git-Hooks
alias gfetch="git fetch"
alias gadd="git add ."
alias gcommit="git commit -m 'Default commit'"
alias gpush="git add . && git commit -m 'Default commit' && git push"
alias gamend="git commit --ammend"
alias gamendf="git commit --amend --no-edit && git push --force-with-lease"
