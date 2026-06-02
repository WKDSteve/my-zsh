# Modulares WSL-Symlink-Skript für Zsh

# 1) Prüfen, ob wir uns überhaupt in WSL befinden
if [[ -f /proc/version ]] && grep -qEi "(Microsoft|WSL)" /proc/version; then

    # 2) Prüfen, ob das Mount-Verzeichnis existiert
    if [[ -d "/mnt" ]]; then
        local drive_path drive_name symlink_target

        # Schleife durch alle gemounteten Windows-Laufwerke
        for drive_path in /mnt/*(N); do
            # Extrahiere den Laufwerksbuchstaben (z.B. "c")
            drive_name="${drive_path:t}"

            # Verhindere, dass WSL-Sonderordner (wie wslg) gelinkt werden
            # Es werden nur Ordner mit genau einem Buchstaben gemountet
            if [[ "$drive_name" =~ ^[a-zA-Z]$ ]]; then
                symlink_target="$HOME/$drive_name"

                # Wenn am Zielort weder Datei, Ordner noch ein Symlink existiert
                if [[ ! -e "$symlink_target" && ! -L "$symlink_target" ]]; then
                    ln -s "$drive_path" "$symlink_target" 2>/dev/null
                    # Optionaler Log-Eintrag (nutzt deine Log-Funktion aus der init.zsh)
                    _myz_log "Symlink erstellt: ~/$drive_name -> $drive_path"
                fi
            fi
        done
    fi
fi
