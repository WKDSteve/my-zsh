# Aliase for work in 3-S IT

## npm
alias npm-set-npm="npm config set registry https://registry.npmjs.org/"
alias npm-set-3s="npm config set registry https://registry.3sit.at/repository/gems-privat"

## Deskhoppers
alias deskhoppers-backend="cd ~/GitRepo/deskhoppers/packages/backend"
alias deskhoppers-frontend="cd ~/GitRepo/deskhoppers/packages/frontend"
alias deskhoppers="cd ~/GitRepo/deskhoppers"

### Deskhoppers Docker
alias dcompose="cd ~/GitRepo/deskhoppers && docker compose up -d"
alias dbackend='docker exec -it deskhoppers-backend-1 sh -c "cd /workspace/packages/backend && exec sh"'
alias dfrontend='docker exec -it deskhoppers-frontend-1 sh -c "cd /workspace/packages/frontend && exec sh"'
alias dstart="~/start_deskhoppers.sh"


