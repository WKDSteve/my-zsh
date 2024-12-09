# Deskhoppers
alias dcompose="cd ~/GitRepo/deskhoppers && docker compose up -d"
alias dbackend='docker exec -it deskhoppers-backend-1 sh -c "cd /workspace/packages/backend && exec sh"'
alias dfrontend='docker exec -it deskhoppers-frontend-1 sh -c "cd /workspace/packages/frontend && exec sh"'
alias dstart="~/start_deskhoppers.sh"
