#!/usr/bin/env bash
set -euo pipefail

DESKTOP_DIR="${1:-$HOME/Desktop/VSDL_Games}"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications/VSDL_Games"

if [ -d "$DESKTOP_DIR" ]; then
  find "$DESKTOP_DIR" -maxdepth 1 -type f -name '*.desktop' -delete
  echo "Removed .desktop launchers from $DESKTOP_DIR"
else
  echo "Desktop dir not found: $DESKTOP_DIR"
fi

if [ -d "$APP_DIR" ]; then
  find "$APP_DIR" -maxdepth 1 -type f -name '*.desktop' -delete
  echo "Removed .desktop launchers from $APP_DIR"
else
  echo "App dir not found: $APP_DIR"
fi

for cache_dir in "$HOME/.cache/menus" "$HOME/.cache/gnome-software"; do
  if [ -d "$cache_dir" ]; then
    rm -rf "$cache_dir"
    echo "Cleared stale menu cache: $cache_dir"
  fi
done

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "Desktop database refreshed. Log out and back in if the app menu is still stale."
