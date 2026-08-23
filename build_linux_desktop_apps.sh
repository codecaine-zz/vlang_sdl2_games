#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_DIR="${1:-$HOME/Desktop/VSDL_Games}"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications/VSDL_Games"
ICONS_DIR="$ROOT_DIR/icons/png"
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 4)}"

export PKG_CONFIG_PATH="/home/linuxbrew/.linuxbrew/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH="/home/linuxbrew/.linuxbrew/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Ensure icons have been generated
if [[ ! -d "$ICONS_DIR" ]] || [[ -z "$(ls -A "$ICONS_DIR" 2>/dev/null)" ]]; then
  echo "Icons not found – running generate_icons.sh first..."
  bash "$ROOT_DIR/generate_icons.sh"
fi

cleanup_old_desktop_files() {
  for target in "$DESKTOP_DIR" "$APP_DIR"; do
    if [ -d "$target" ]; then
      find "$target" -maxdepth 1 -type f -name '*.desktop' -delete
    else
      mkdir -p "$target"
    fi
  done
}

cleanup_old_desktop_files
mkdir -p "$DESKTOP_DIR" "$APP_DIR"

mapfile -t game_dirs < <(
  find "$ROOT_DIR" -mindepth 1 -maxdepth 1 -type d \
    ! -name "assets" ! -name "screenshots" -print | sort
)

build_one() {
  game_dir="$1"
  game_name="$(basename "$game_dir")"

  if [ ! -f "$game_dir/v.mod" ] && [ ! -f "$game_dir/main.v" ] && ! ls "$game_dir"/*.v >/dev/null 2>&1; then
    return 0
  fi

  echo "Building $game_name..."
  (cd "$game_dir" && v -o "$game_name" .)

  for target_dir in "$DESKTOP_DIR" "$APP_DIR"; do
    desktop_file="$target_dir/${game_name}.desktop"
    cat > "$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=$game_name
Comment=Play $game_name
Exec=/bin/bash -lc 'export PKG_CONFIG_PATH="/home/linuxbrew/.linuxbrew/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"; export LD_LIBRARY_PATH="/home/linuxbrew/.linuxbrew/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"; cd "$game_dir"; exec "$game_dir/$game_name"'
Path=$game_dir
Terminal=false
Categories=Game;
StartupNotify=true
Icon=${ICONS_DIR}/${game_name}.png
EOF
    chmod +x "$desktop_file"
    echo "Created $desktop_file"
  done
}

export -f build_one
export DESKTOP_DIR APP_DIR ROOT_DIR ICONS_DIR PKG_CONFIG_PATH LD_LIBRARY_PATH

printf '%s\n' "${game_dirs[@]}" | xargs -P "$JOBS" -I{} bash -c 'build_one "$1"' _ {}

update-desktop-database "$APP_DIR" 2>/dev/null || true

echo "Done. Desktop launchers are in $DESKTOP_DIR and $APP_DIR"
