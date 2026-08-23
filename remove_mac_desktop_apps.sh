#!/usr/bin/env bash
# remove_mac_desktop_apps.sh – Remove macOS .app bundles created by build_mac_desktop_apps.sh
#
# Usage:
#   ./remove_mac_desktop_apps.sh [desktop_dir]
#
# Removes:
#   - All *.app bundles from ~/Desktop/VSDL_Games (or the provided dir)
#   - All *.app bundles from /Applications/VSDL_Games
#   - Refreshes the Launch Services database
set -euo pipefail

DESKTOP_DIR="${1:-$HOME/Desktop/VSDL_Games}"
APPS_DIR="/Applications/VSDL_Games"

removed=0

remove_apps_from() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    local count
    count="$(find "$dir" -maxdepth 1 -name '*.app' | wc -l | tr -d ' ')"
    if (( count > 0 )); then
      find "$dir" -maxdepth 1 -name '*.app' -exec rm -rf {} +
      echo "Removed $count .app bundle(s) from $dir"
    else
      echo "No .app bundles found in $dir"
    fi
    # Remove the directory itself if it's now empty
    if [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
      rmdir "$dir" && echo "Removed empty directory: $dir"
    fi
  else
    echo "Directory not found (skipped): $dir"
  fi
}

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

remove_apps_from "$DESKTOP_DIR"
remove_apps_from "$APPS_DIR"

# Clean up local .app bundles built inside game folders
echo "Cleaning up local .app bundles inside repository..."
find "$ROOT_DIR" -mindepth 2 -maxdepth 2 -name '*.app' -exec rm -rf {} + 2>/dev/null || true

# Refresh Launch Services so removed apps disappear from Launchpad/Spotlight
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -kill -r -domain local -domain system -domain user 2>/dev/null || true

echo ""
echo "Done. Launch Services database refreshed."
echo "Log out and back in if apps still appear in Launchpad."
