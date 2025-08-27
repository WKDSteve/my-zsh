# Instructions for `my-zsh`-repository

1) Load my-zsh repository to ~/REPO_DIR

2) Create the REPO_DIR environment variable in ~/.zshenv, like:
export REPOS_DIR="/mnt/e/repos"

3) Create a symlink from my-zsh/.zshrc to $HOME (force overwrite if ~/.zshrc exists)
ln -sf /mnt/e/repos/my-zsh/.zshrc "$HOME/.zshrc"

4) Optional: Create ~/personel_env/.somesecretfilename for secret keys, like
OPENAI_API_KEY=sk-proj-...