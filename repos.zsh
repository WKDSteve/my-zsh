# Repo-Sprung aus $REPOS_DIR
# ------------------------------------------------------------------------------
# Konzept und Begruendungen: Configs/docs/KONZEPT-REPO-SPRUNG.md
#
#   WKDBooks / wkdbooks    -> cd $REPOS_DIR/WKDBooks
#   spotlight              -> cd $REPOS_DIR/spotlight.nvim
#   spotlight-nvim         -> dito
#   repo wkdb              -> explizit, mit Completion und Auswahl bei Mehrdeutigkeit
#
# Es wird nichts vorberechnet und nichts generiert: die Aufloesung laeuft beim
# Tippen, nicht beim Shellstart. Ein frisch geklontes Repo funktioniert damit
# sofort, ohne dass hier etwas nachgepflegt werden muesste.

: "${REPOS_DIR:?repos.zsh: REPOS_DIR ist nicht gesetzt (siehe ~/.zshrc)}"

# ------------------------------------------------------------------------------
# 1) Kandidaten und Namensformen
# ------------------------------------------------------------------------------

# Alle Direktkinder von $REPOS_DIR, die ein .git tragen (Datei oder Verzeichnis —
# bei Worktrees und Submodulen ist .git eine Datei).
__repo_list() {
  emulate -L zsh
  local d
  for d in "$REPOS_DIR"/*(N/); do
    [[ -e "$d/.git" ]] && print -r -- "${d:t}"
  done
}

# Die drei akzeptierten Schreibweisen eines Repo-Namens:
# voll (spotlight.nvim), Punkt->Bindestrich (spotlight-nvim), Stamm (spotlight).
__repo_forms() {
  emulate -L zsh
  local n="$1"
  print -r -- "$n"
  if [[ "$n" == *.* ]]; then
    print -r -- "${n//./-}"
    print -r -- "${n%%.*}"
  fi
}

# ------------------------------------------------------------------------------
# 2) Aufloesung
# ------------------------------------------------------------------------------

# __repo_resolve <suchbegriff> [strict]
# Druckt die Namen aller Treffer, hoechste Trefferguete zuerst und nur diese:
# ein exakter Treffer verdraengt Praefix-Treffer, Praefix verdraengt Substring.
# Mit `strict` entfaellt die Substring-Stufe — das ist der Modus fuer den
# command-not-found-Hook, damit ein Tippfehler ein Fehler bleibt.
__repo_resolve() {
  emulate -L zsh
  local q="${1:l}" mode="${2:-loose}"
  local -a exact prefix substr forms
  local d n f

  for d in "$REPOS_DIR"/*(N/); do
    [[ -e "$d/.git" ]] || continue
    n="${d:t}"
    forms=("${(@f)$(__repo_forms "$n")}")
    for f in $forms; do
      f="${f:l}"
      if [[ "$f" == "$q" ]]; then
        exact+=("$n"); break
      elif [[ "$f" == "$q"* ]]; then
        prefix+=("$n")
      elif [[ "$mode" == loose && "$f" == *"$q"* ]]; then
        substr+=("$n")
      fi
    done
  done

  # (@u) dedupliziert: derselbe Name kann ueber mehrere Schreibweisen treffen.
  if   (( $#exact  )); then print -rl -- "${(@u)exact}"
  elif (( $#prefix )); then print -rl -- "${(@u)prefix}"
  elif (( $#substr )); then print -rl -- "${(@u)substr}"
  fi
}

# Wechselt ins Ziel und laesst zoxide mitlernen, damit `z` mit der Zeit von
# selbst richtig liegt.
__repo_cd() {
  builtin cd -- "$1" || return
  if (( $+commands[zoxide] )); then
    zoxide add "$PWD" 2>/dev/null
  fi
  return 0
}

# ------------------------------------------------------------------------------
# 3) Mehrdeutigkeit
# ------------------------------------------------------------------------------

# Auswahl aus mehreren Kandidaten. Steuerbar ueber $REPO_JUMP_PICKER:
#   (leer) = fzf falls vorhanden, sonst Liste | fzf | list | none
# Ohne Terminal gilt immer `none` — kein blockierender Prompt in Skripten.
__repo_pick() {
  emulate -L zsh
  local -a cands=("$@")
  local mode="${REPO_JUMP_PICKER:-}"

  if [[ ! -t 0 || ! -t 2 ]]; then
    mode=none
  elif [[ -z "$mode" ]]; then
    (( $+commands[fzf] )) && mode=fzf || mode=list
  fi

  case "$mode" in
    fzf)
      print -rl -- "${cands[@]}" | fzf --height 40% --layout=reverse --prompt='repo> '
      ;;
    list)
      local i sel
      for (( i = 1; i <= $#cands; i++ )); do
        print -u2 -r -- "  [$i] ${cands[i]}"
      done
      print -u2 -n -- 'Auswahl (leer = Abbruch): '
      read -r sel
      if [[ "$sel" == <-> ]] && (( sel >= 1 && sel <= $#cands )); then
        print -r -- "${cands[sel]}"
      fi
      ;;
    *)
      print -u2 -r -- "[repo] mehrdeutig: ${(j:, :)cands}"
      print -u2 -r -- "[repo] genauer tippen oder REPO_JUMP_PICKER=fzf setzen"
      return 1
      ;;
  esac
}

# ------------------------------------------------------------------------------
# 4) repo — der explizite Einstiegspunkt
# ------------------------------------------------------------------------------
# Nötig für alles, was der Hook aus Abschnitt 6 nicht erreichen kann: Namen, die
# echte Kommandos sind (`diff` aus diff.nvim), und mehrdeutige Begriffe.
# Ohne Argument: Auswahl über alle Repos.
repo() {
  emulate -L zsh
  local q="$1"

  if [[ ! -d "$REPOS_DIR" ]]; then
    print -u2 -r -- "[repo] Repos-Verzeichnis nicht gefunden: $REPOS_DIR (REPOS_DIR pruefen)"
    return 1
  fi

  local -a hits
  if [[ -z "$q" ]]; then
    hits=("${(@f)$(__repo_list)}")
  else
    # Direkter Treffer zuerst: zwei stat-Aufrufe statt eines Verzeichnis-Scans.
    local direct
    for direct in "$REPOS_DIR/$q" "$REPOS_DIR/$q.nvim"; do
      if [[ -d "$direct" && -e "$direct/.git" ]]; then
        __repo_cd "$direct"
        return
      fi
    done
    hits=("${(@f)$(__repo_resolve "$q" loose)}")
  fi
  hits=("${(@)hits:#}")   # leere Zeilen entfernen

  case $#hits in
    0)
      print -u2 -r -- "[repo] kein Repo gefunden fuer '${q}' in $REPOS_DIR"
      return 1
      ;;
    1)
      __repo_cd "$REPOS_DIR/${hits[1]}"
      ;;
    *)
      local pick
      pick="$(__repo_pick "${hits[@]}")" || return 1
      [[ -n "$pick" ]] || return 1
      __repo_cd "$REPOS_DIR/$pick"
      ;;
  esac
}

# Completion ueber alle drei Schreibweisen.
_repo() {
  local -a names
  names=("${(@f)$(__repo_list)}")
  local n
  local -a all
  for n in $names; do
    all+=("${(@f)$(__repo_forms "$n")}")
  done
  _describe -t repos 'repo' all
}
compdef _repo repo 2>/dev/null

# ------------------------------------------------------------------------------
# 5) cdpath — der native Schnellweg
# ------------------------------------------------------------------------------
# AUTO_CD ist in behavior.zsh gesetzt. Zusammen mit cdpath loest zsh bare
# Repo-Namen selbst auf, inklusive Completion und ohne jeden Aufruf hier.
# Lokale Verzeichnisse gewinnen weiterhin: cdpath wird erst nach ./ geprueft.
# Abschalten mit MYZ_REPO_CDPATH=0 vor dem Sourcen.
if [[ "${MYZ_REPO_CDPATH:-1}" == 1 ]]; then
  typeset -U cdpath
  cdpath+=("$REPOS_DIR")
fi

# ------------------------------------------------------------------------------
# 6) accept-line-Widget — die Schreibweisen, die cdpath nicht kann
# ------------------------------------------------------------------------------
# cdpath deckt nur den exakten Verzeichnisnamen ab: unter Linux
# gross-/kleinschreibungsgenau und ohne Kenntnis der .nvim-Endung. `wkdbooks`
# und `spotlight` braucht es also zusaetzlich.
#
# Warum kein command_not_found_handler: zsh forkt, BEVOR es ihn aufruft
# ($ZSH_SUBSHELL ist darin 1). Ein `cd` wirkt dort nur in der Subshell und ist
# nach der Rueckkehr wieder weg — der Handler waere ein stiller No-op. Getestet,
# nicht vermutet. In PowerShell verhaelt sich CommandNotFoundAction anders,
# deshalb ist der Hook dort das Mittel der Wahl und hier nicht.
#
# Das accept-line-Widget laeuft dagegen im Elternprozess. Es schreibt eine Zeile,
# die nur aus einem aufloesbaren Repo-Namen besteht, in `repo <name>` um — die
# Historie zeigt danach, was tatsaechlich passiert ist.
#
# Ueberschrieben wird das Widget accept-line selbst und nicht die Tastenbindung:
# so greift es auch, wenn fishify.zsh oder zsh-vi-mode ^M auf ein eigenes Widget
# legen, das seinerseits `zle accept-line` aufruft.
__repo_accept_line() {
  emulate -L zsh
  local word="${${BUFFER##[[:space:]]#}%%[[:space:]]#}"

  # Nur eine einzelne Zeile aus genau einem Wort ohne Pfadtrenner. Alles mit
  # Argumenten oder Pfad war nie als Repo-Name gemeint — und der Normalfall
  # verlaesst die Pruefung damit nach einem Stringvergleich.
  if [[ -n "$word" && "$word" != *[[:space:]]* && "$word" != */* && -d "$REPOS_DIR" ]]; then
    # Nichts anfassen, was die Shell selbst aufloesen kann: ein echtes Kommando,
    # ein lokales Verzeichnis, oder ein exakter Repo-Name (den erledigt cdpath).
    if ! command -v -- "$word" > /dev/null 2>&1 \
       && [[ ! -d "$word" && ! -d "$REPOS_DIR/$word" ]]; then
      local -a hits
      hits=("${(@f)$(__repo_resolve "$word" strict)}")
      hits=("${(@)hits:#}")
      # Nur bei genau einem Treffer umschreiben: mehrdeutig oder unbekannt soll
      # der normale Fehler bleiben, damit ein Tippfehler ein Tippfehler bleibt.
      (( $#hits == 1 )) && BUFFER="repo ${(q)word}"
    fi
  fi

  zle .accept-line
}
zle -N accept-line __repo_accept_line

# ------------------------------------------------------------------------------
# 7) zoxide-Seeding
# ------------------------------------------------------------------------------
# Damit `z wkdbooks` auch ein Repo findet, das noch nie besucht wurde: zoxide
# kennt nur, was in seiner DB steht, und hat keinen Hook fuer externe Quellen.
#
# Die Stempeldatei haelt die mtime von $REPOS_DIR fest. Die aendert sich beim
# Anlegen oder Loeschen eines Repos — also genau dann, wenn neu geseedet werden
# muss. Normaler Start: ein stat und ein Dateilesevorgang, kein Subprozess.
__repo_seed_zoxide() {
  emulate -L zsh
  (( $+commands[zoxide] )) || return 0
  [[ -d "$REPOS_DIR" ]] || return 0

  local stamp_dir="${XDG_CACHE_HOME:-$HOME/.cache}/my-zsh"
  local stamp="$stamp_dir/repos_seed.stamp"

  local now=''
  zmodload -F zsh/stat b:zstat 2>/dev/null
  if (( $+builtins[zstat] )); then
    now="$(zstat +mtime "$REPOS_DIR" 2>/dev/null)"
  else
    now="$(stat -c %Y "$REPOS_DIR" 2>/dev/null || stat -f %m "$REPOS_DIR" 2>/dev/null)"
  fi
  [[ -n "$now" ]] || return 0

  if [[ -r "$stamp" ]] && [[ "$(<"$stamp")" == "$now" ]]; then
    return 0
  fi

  local -a paths
  local d
  for d in "$REPOS_DIR"/*(N/); do
    [[ -e "$d/.git" ]] && paths+=("$d")
  done
  (( $#paths )) || return 0

  # Ein Subprozess fuer alle Pfade. Ohne --score: der Standard-Zuwachs von 1 ist
  # bereits der niedrigste sinnvolle Startwert, damit echte Besuche gewinnen.
  zoxide add "${paths[@]}" 2>/dev/null || return 0

  # Stempel erst NACH dem erfolgreichen Seeding schreiben.
  mkdir -p -- "$stamp_dir" 2>/dev/null || return 0
  print -r -- "$now" > "$stamp" 2>/dev/null
}

# Erzwingt ein Seeding, unabhaengig vom Stempel.
repo-reseed() {
  rm -f -- "${XDG_CACHE_HOME:-$HOME/.cache}/my-zsh/repos_seed.stamp" 2>/dev/null
  __repo_seed_zoxide
}

__repo_seed_zoxide
