# =====================================================================
# integrations/10-completion.zsh
# Robust, cached completion setup. Must be loaded before completion plugins.
# =====================================================================

[[ -o interactive ]] || return 0
[[ -n ${MYZ_LOADED[int:10-completion]-} ]] && return 0
MYZ_LOADED[int:10-completion]=1

# Load completion system once
autoload -Uz compinit bashcompinit
# Fast init with rehash; use a user-writable cache directory
typeset -gU fpath
typeset -g MYZ_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compdump"
mkdir -p "${MYZ_COMPDUMP:h}"

# Limit compaudit noise by fixing insecure dirs if possible
# (Optional) One can review `compaudit` output manually in strict setups.

compinit -d "$MYZ_COMPDUMP"
# If bash completions are desired for some tools:
# bashcompinit
zmodload -i zsh/complist 2>/dev/null || true
setopt auto_menu complete_in_word always_to_end
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'

