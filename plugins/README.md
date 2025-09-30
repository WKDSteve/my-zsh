# my-zsh/plugins – Portable plugin management

This directory contains a minimal, deterministic, and repo-local plugin system for Zsh.
It is split into a data-only registry and a small, idempotent loader:

* `registry.zsh` defines which plugins exist, whether they are enabled, in which stage they load, and where they live.
* `init.zsh` executes the staged loading (pre-compinit → compinit → post-compinit → final), with guards and caching.

The goals are reproducibility, low startup overhead, and cross-platform behavior on Linux/macOS/WSL, without introducing external plugin managers unless you want to.

## Quick start

1. Ensure your `~/.zshrc` sources the repo entry point:

   ```sh
   # ~/.zshrc
   [[ -o interactive ]] || return
   : "${REPOS_DIR:?Please set repos (e.g., /mnt/steve/repos)}"
   [[ -r "$REPOS_DIR/my-zsh/init.zsh" ]] && source "$REPOS_DIR/my-zsh/init.zsh"
   ```

2. Ensure `my-zsh/init.zsh` loads plugins (one line):

   ```sh
   # my-zsh/init.zsh
   _src "$MY_ZSH_DIR/plugins/init.zsh"
   ```

3. Toggle plugins in `plugins/registry.zsh` by setting:

   ```sh
   # Enable/disable
   MYZ_PLUGINS_ENABLED[plugin-name]=on|off
   # Loading stage
   MYZ_PLUGINS_STAGE[plugin-name]=pre-compinit|post-compinit|final
   # Path to file or directory
   MYZ_PLUGINS_PATH[plugin-name]="/absolute/path/inside/plugins"
   # Optional binary condition (or 'always')
   MYZ_PLUGINS_COND[plugin-name]=always|fzf|git|...
   ```

4. Open a new interactive shell. No errors should appear.
   If you see skips on stderr, they are non-fatal diagnostics (missing binary, missing directory, etc.).

## Loading order and rationale

* `pre-compinit`: Only environment or `fpath` changes that must exist before `compinit` (e.g., `zsh-completions` directory).
* `compinit` once: Cached at `${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompdump` and optionally byte-compiled.
* `post-compinit`: Everything that relies on the completion system (e.g., `fzf-tab`, `zsh-autosuggestions`, `zsh-vi-mode`).
* `final`: Layers that must come last (e.g., `zsh-syntax-highlighting`) to avoid style overrides.

This order avoids re-initialization, reduces startup time, and prevents subtle breakage from late `fpath` mutations.

## Adding a new plugin

1. Place the plugin inside `plugins/`:

   * For a single file: `plugins/my-plugin/my-plugin.plugin.zsh` (or `init.zsh`).
   * For a directory with completions only: the directory itself is enough (it will be appended to `fpath`).

2. Edit `plugins/registry.zsh`:

   ```sh
   # Enable it
   MYZ_PLUGINS_ENABLED[my-plugin]=on

   # Choose a stage
   # - pre-compinit: directory for completions (fpath only)
   # - post-compinit: normal plugin after compinit
   # - final: needs to be the very last (e.g., syntax highlighting)
   MYZ_PLUGINS_STAGE[my-plugin]=post-compinit

   # Point to a file or directory (absolute inside the repo)
   MYZ_PLUGINS_PATH[my-plugin]="${MY_ZSH_DIR}/plugins/my-plugin/my-plugin.plugin.zsh"

   # Optional condition: only load if a binary exists (or 'always')
   MYZ_PLUGINS_COND[my-plugin]=always
   ```

3. Optional: create plugin-specific config file(s) under `plugins/my-plugin/*.zsh` and source them from your plugin file.

4. Start a new shell and verify:

   ```sh
   # Completion commands should work if your plugin registered them
   which some_plugin_function
   echo $fpath | tr ' ' '\n' | grep my-plugin
   ```

## Updating plugins

Because this setup is repo-local, there are two common plugin shapes:

* Git-based plugins vendored into `plugins/<name>` (the directory is a Git repo).
* File-based or submodule-based plugins (single files or directories tracked by your top-level repo).

Below are helper scripts in `plugins/actions/` to standardize updates.
All scripts are POSIX-shell, work on Linux/macOS, and are safe to call repeatedly.
If you do not need them, you can ignore or delete the entire `actions/` directory.

## actions scripts

Place the following files under `my-zsh/plugins/actions/`. Make them executable (`chmod +x`).

File: `plugins/actions/update-all.sh`

```sh
#!/usr/bin/env sh
# Purpose:
#   Update all vendored git-based plugins inside plugins/.
# Behavior:
#   - For each subdirectory that is a git repo, fetch+pull the default branch.
#   - Skips non-git directories and single-file plugins.
#   - Supports DRY-RUN via MYZ_DRYRUN=1 environment variable.
# Portability: POSIX sh; works on Linux/macOS.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PLUGDIR="$ROOT"

dryrun() { [ "${MYZ_DRYRUN:-0}" = "1" ]; }

info()  { printf '%s\n' "[update-all] $*" >&2; }
warn()  { printf '%s\n' "[update-all] WARN: $*" >&2; }
run()   { if dryrun; then info "DRY-RUN: $*"; else sh -c "$*"; fi; }

# Iterate directories only
find "$PLUGDIR" -mindepth 1 -maxdepth 1 -type d | while IFS= read -r dir; do
  # Skip actions/ and non-plugin meta
  case "$(basename "$dir")" in actions|__tests__|.git) continue ;; esac

  if [ -d "$dir/.git" ]; then
    info "Updating $(basename "$dir")"
    # Detect current branch
    branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD || printf 'master')
    run "git -C \"$dir\" fetch --all --prune"
    run "git -C \"$dir\" pull --ff-only origin \"$branch\"" || warn "fast-forward failed for $dir"
  else
    info "Skip (not a git repo): $(basename "$dir")"
  fi
done

info "Done."
```

File: `plugins/actions/update-one.sh`

```sh
#!/usr/bin/env sh
# Purpose:
#   Update a single vendored git-based plugin by name.
# Usage:
#   plugins/actions/update-one.sh zsh-vi-mode
# Notes:
#   - Honors MYZ_DRYRUN=1 for dry runs.

set -eu

[ "${1:-}" ] || { printf '%s\n' "usage: $0 <plugin-dir-name>" >&2; exit 2; }

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
DIR="$ROOT/$1"

dryrun() { [ "${MYZ_DRYRUN:-0}" = "1" ]; }
info()   { printf '%s\n' "[update-one] $*" >&2; }
warn()   { printf '%s\n' "[update-one] WARN: $*" >&2; }
run()    { if dryrun; then info "DRY-RUN: $*"; else sh -c "$*"; fi; }

[ -d "$DIR/.git" ] || { warn "not a git repo: $DIR"; exit 1; }

branch=$(git -C "$DIR" rev-parse --abbrev-ref HEAD || printf 'master')
run "git -C \"$DIR\" fetch --all --prune"
run "git -C \"$DIR\" pull --ff-only origin \"$branch\"" || warn "fast-forward failed"

info "Done."
```

File: `plugins/actions/list.sh`

```sh
#!/usr/bin/env sh
# Purpose:
#   List plugins and classify them as: git-repo, directory, single-file.
# Output:
#   <name>  <type>

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

for path in "$ROOT"/*; do
  base=$(basename "$path")
  [ "$base" = "actions" ] && continue
  [ "$base" = ".git" ] && continue

  if [ -d "$path/.git" ]; then
    printf '%s\t%s\n' "$base" "git-repo"
  elif [ -d "$path" ]; then
    printf '%s\t%s\n' "$base" "directory"
  elif [ -f "$path" ]; then
    printf '%s\t%s\n' "$base" "single-file"
  fi
done
```

File: `plugins/actions/doctor.sh`

```sh
#!/usr/bin/env sh
# Purpose:
#   Basic health checks for the plugin system.
# Checks:
#   - registry/init presence
#   - compinit cache directory
#   - required binaries for enabled plugins (from MYZ_PLUGINS_COND) if running inside zsh

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
REG="$ROOT/registry.zsh"
INIT="$ROOT/init.zsh"

ok=1

[ -r "$REG" ] || { printf '%s\n' "[doctor] missing registry: $REG" >&2; ok=0; }
[ -r "$INIT" ] || { printf '%s\n' "[doctor] missing init: $INIT" >&2; ok=0; }

cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[ -d "$cache" ] || { printf '%s\n' "[doctor] cache dir not found (will be created at runtime): $cache" >&2; }

if command -v zsh >/dev/null 2>&1; then
  # Try to read enabled plugins and binary conditions by spawning zsh
  zsh -i -c '
    emulate -LR zsh
    : "${REPOS_DIR:?doctor needs REPOS_DIR}"
    source "$REPOS_DIR/my-zsh/init.zsh" >/dev/null 2>&1 || true
    source "$REPOS_DIR/my-zsh/plugins/registry.zsh" >/dev/null 2>&1 || true

    for name cond in "${(@kv)MYZ_PLUGINS_COND}"; do
      if [ "${MYZ_PLUGINS_ENABLED[$name]}" = "on" ]; then
        if [ "$cond" = "always" ]; then
          print -- "[doctor] ok: $name (no binary required)"
        else
          if command -v -- "$cond" >/dev/null 2>&1; then
            print -- "[doctor] ok: $name (found $cond)"
          else
            print -- "[doctor] warn: $name (missing $cond)"
          fi
        fi
      fi
    done
  ' || true
fi

[ $ok -eq 1 ] && printf '%s\n' "[doctor] checks completed." >&2 || exit 1
```

File: `plugins/actions/rebuild-compdump.sh`

```sh
#!/usr/bin/env sh
# Purpose:
#   Force a rebuild of the compinit dump to fix stale completions.
# Behavior:
#   - Removes cached .zcompdump and optional .zwc and triggers compinit once.

set -eu

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
DUMP="$CACHE/.zcompdump"

printf '%s\n' "[rebuild] removing: $DUMP*" >&2
rm -f -- "$DUMP" "$DUMP.zwc" 2>/dev/null || true

# Rebuild by spawning a login shell once
if command -v zsh >/dev/null 2>&1; then
  zsh -i -c 'autoload -Uz compinit; compinit -C' >/dev/null 2>&1 || true
  printf '%s\n' "[rebuild] compinit executed." >&2
else
  printf '%s\n' "[rebuild] zsh not found; nothing to do." >&2
fi
```

## Typical workflows

Update every vendored Git plugin:

```sh
MYZ_DRYRUN=1 my-zsh/plugins/actions/update-all.sh    # preview
my-zsh/plugins/actions/update-all.sh                 # execute
```

Update a single plugin:

```sh
my-zsh/plugins/actions/update-one.sh zsh-vi-mode
```

List all plugins and their type:

```sh
my-zsh/plugins/actions/list.sh
```

Rebuild completions cache:

```sh
my-zsh/plugins/actions/rebuild-compdump.sh
```

Run health checks:

```sh
REPOS_DIR=/path/to/repos my-zsh/plugins/actions/doctor.sh
```

## Enabling/disabling plugins

Toggle in `registry.zsh`:

```sh
# Enable
MYZ_PLUGINS_ENABLED[zsh-autosuggestions]=on
# Disable
MYZ_PLUGINS_ENABLED[zsh-autosuggestions]=off
```

Changes apply on the next interactive shell.
For on-the-fly testing, source the loader in a running shell:

```sh
# This is safe and idempotent; it won’t re-run compinit redundantly.
source "$REPOS_DIR/my-zsh/plugins/init.zsh"
```

## Conditions and portability

If a plugin depends on a binary or toolchain, set a condition:

```sh
MYZ_PLUGINS_COND[git]=git        # only load if `git` exists
MYZ_PLUGINS_COND[fzf-tab]=fzf    # only load if `fzf` exists
MYZ_PLUGINS_COND[my-plugin]=always
```

This keeps startup fast and reduces noisy errors on systems without the dependency (e.g., minimal servers, fresh containers).

## Conventions for paths

* Always use absolute paths anchored at `${MY_ZSH_DIR}` so the loader can remain independent from `$PWD`.
* For completion-only plugins, point `MYZ_PLUGINS_PATH[name]` to the directory; the loader will append it to `fpath` in `pre-compinit`.
* For file-based plugins, point to the `.plugin.zsh` (or `.zsh`) file; the loader will `source` it in the correct stage.

## Debugging

Enable lightweight diagnostics by exporting `MYZ_PLUGINS_DEBUG=1` (optional, if you add such logic) and/or review stderr messages printed by the loader.
Common issues:

* Plugin path points to a non-existing file/directory → fix `MYZ_PLUGINS_PATH`.
* Stage mismatch (e.g., `zsh-syntax-highlighting` not last) → set `final`.
* Missing binary for a conditioned plugin → install it or change `MYZ_PLUGINS_COND[name]=always`.

## Safety, performance, and idempotency

* The loader checks interactivity and avoids hard failures; missing plugins are skipped with a short message.
* `compinit` is executed once with a cache dump under XDG cache; optional `zcompile` can speed up parsing.
* Staged loading gives deterministic order, reducing subtle conflicts.
* Small, testable surface: registry is declarative; the loader is a tiny executor.

## FAQ

Q: Can I keep using an external plugin manager (e.g., zinit, antibody)?
A: Yes. This system is independent. If you mix, keep external managers either entirely before or after this loader and be mindful of `compinit` duplication.

Q: Where should I add plugin-specific key bindings?
A: Prefer plugin-local files under `plugins/<name>/keybinds.zsh` sourced by the plugin itself, or add them in your `functions.zsh` after the plugin’s stage to ensure widgets exist.

Q: How do I vendor a plugin as a Git submodule?
A: Add a submodule under `plugins/<name>`. The `update-all.sh` script will still treat it as a git repo and attempt `fetch/pull`. If you pin to a commit, keep `--ff-only` to avoid accidental merges.

## Minimal example plugin file

File: `plugins/example/example.plugin.zsh`

```sh
# Purpose:
#   Example skeleton for a simple plugin file.
# Notes:
#   Sourced in the stage you configured in MYZ_PLUGINS_STAGE.
#   Keep side effects minimal and guard on interactivity.

# Only affect interactive shells
[[ -o interactive ]] || return 0

# Define a small function
example_hello() {
  # Print a message to stdout
  printf '%s\n' "hello from example plugin"
}

# Optional key binding:
# Create a widget and bind it to Alt-h (macOS Terminal may differ)
zle -N example_hello_widget example_hello
bindkey '^[h' example_hello_widget
```

## Test checklist

1. Open a new interactive shell: no errors on startup.
2. `my-zsh/plugins/actions/list.sh` prints your plugins with correct types.
3. `echo $fpath` includes `zsh-completions` if enabled.
4. `which _fzf_tab_widget` returns a path if `fzf-tab` is enabled.
5. Typing shows highlighting only if `zsh-syntax-highlighting` is enabled and loaded last.
6. Toggle a plugin off, restart shell, verify it is gone.

## De-installation

* To remove a plugin: disable it in `registry.zsh`, delete its directory/file, and (optionally) run `rebuild-compdump.sh`.
* To remove the entire system: delete `plugins/` and the single `_src "$MY_ZSH_DIR/plugins/init.zsh"` line from `my-zsh/init.zsh`.

