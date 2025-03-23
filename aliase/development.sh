# Aliase for Development related stuff
export GITHUB_DIR="/media/steve/Depot/MyGithub"
alias shortboard="nvim ~/$GITHUB_DIR/WKDBooks/wkdbook-OS/wkdbook-CLI/wkdbook-PosixShells/CLITools/Shortboard.md"
alias lsplog="Users/22bartls/.local/state/nvim/lsp.log"

alias kali="sudo docker run -it \
  --name kali-container \
  --network=host \
  --cap-add=NET_ADMIN \
  --privileged \
  --restart unless-stopped \
  -v ~/Dokumente/htb-academy-regular.ovpn:/root/htb.ovpn \
  kalilinux/kali-rolling \
  bash -c 'apt update && apt install -y openvpn kali-linux-large && exec bash'"
alias kali-throw="sudo docker run -it --rm \
  --name kali-container \
  --network=host \
  --cap-add=NET_ADMIN \
  -v ~/Dokumente/htb-academy-regular.ovpn:/root/htb.ovpn \
  kalilinux/kali-rolling \
  bash -c 'apt update && apt install -y openvpn kali-linux-large bash'"
