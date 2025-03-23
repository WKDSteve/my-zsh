# Ein Verzeichnis erstellen und sofort hineinwechseln
mkcd() {
  mkdir -p "$1" && cd "$1"
}
