#!/usr/bin/env bash
# generate_icons.sh – Generate .icns (macOS) and 256x256 PNG (Linux) icons
# for every game that has a screenshot in screenshots/.
#
# Usage:
#   ./generate_icons.sh [icons_dir]
#
# Outputs:
#   <icons_dir>/icns/<game>.icns   – macOS icon bundle
#   <icons_dir>/png/<game>.png     – 256×256 PNG for Linux .desktop files
#
# Requirements:
#   macOS: iconutil, sips  (both ship with Xcode Command Line Tools)
#   Optional: ImageMagick (convert) – used as a fallback / for cross-platform builds
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCREENSHOTS_DIR="$ROOT_DIR/screenshots"
ICONS_DIR="${1:-$ROOT_DIR/icons}"
ICNS_DIR="$ICONS_DIR/icns"
PNG_DIR="$ICONS_DIR/png"

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

have() { command -v "$1" &>/dev/null; }

log()  { echo "[$1] $2"; }

# Build an .icns from a source PNG using iconutil (macOS native)
build_icns_with_iconutil() {
  local src="$1"
  local dest="$2"
  local name
  name="$(basename "$dest" .icns)"

  local iconset
  iconset="$(mktemp -d "/tmp/${name}.XXXXXX.iconset")"
  trap 'rm -rf "$iconset"' RETURN

  # Sizes required by macOS iconset spec
  local -a sizes=(16 32 64 128 256 512 1024)
  for sz in "${sizes[@]}"; do
    sips -z "$sz" "$sz" "$src" --out "$iconset/icon_${sz}x${sz}.png" &>/dev/null
    # @2x variant (half the logical size)
    local half=$(( sz / 2 ))
    if (( half >= 16 )); then
      sips -z "$sz" "$sz" "$src" --out "$iconset/icon_${half}x${half}@2x.png" &>/dev/null
    fi
  done

  iconutil -c icns "$iconset" -o "$dest"
}

# Build an .icns using ImageMagick + iconutil as fallback helper
build_icns_with_imagemagick() {
  local src="$1"
  local dest="$2"
  local name
  name="$(basename "$dest" .icns)"

  local iconset
  iconset="$(mktemp -d "/tmp/${name}.XXXXXX.iconset")"
  trap 'rm -rf "$iconset"' RETURN

  local -a pairs=(
    "16 16x16"
    "32 16x16@2x"
    "32 32x32"
    "64 32x32@2x"
    "128 128x128"
    "256 128x128@2x"
    "256 256x256"
    "512 256x256@2x"
    "512 512x512"
    "1024 512x512@2x"
  )
  for pair in "${pairs[@]}"; do
    local sz="${pair%% *}"
    local label="${pair##* }"
    convert "$src" -resize "${sz}x${sz}" "$iconset/icon_${label}.png" 2>/dev/null
  done

  iconutil -c icns "$iconset" -o "$dest"
}

# Resize source PNG to 256×256 for Linux
build_png_256() {
  local src="$1"
  local dest="$2"
  if have sips; then
    sips -z 256 256 "$src" --out "$dest" &>/dev/null
  elif have convert; then
    convert "$src" -resize 256x256 "$dest"
  else
    cp "$src" "$dest"
    log "WARN" "Neither sips nor convert found – copied $src as-is"
  fi
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

mkdir -p "$ICNS_DIR" "$PNG_DIR"

# Step 1: Ensure default icon (default.icns & default.png) exists
DEFAULT_SRC="$SCREENSHOTS_DIR/clickarcade.png"
if [[ ! -f "$DEFAULT_SRC" ]]; then
  # Fallback to any screenshot if clickarcade.png isn't available
  DEFAULT_SRC="$(find "$SCREENSHOTS_DIR" -name '*.png' | head -n 1)"
fi

if [[ -f "$DEFAULT_SRC" ]]; then
  if [[ ! -f "$ICNS_DIR/default.icns" ]]; then
    if have iconutil && have sips; then
      log "icns" "Generating default.icns"
      build_icns_with_iconutil "$DEFAULT_SRC" "$ICNS_DIR/default.icns"
    elif have iconutil && have convert; then
      log "icns" "Generating default.icns"
      build_icns_with_imagemagick "$DEFAULT_SRC" "$ICNS_DIR/default.icns"
    fi
  fi

  if [[ ! -f "$PNG_DIR/default.png" ]]; then
    log "png " "Generating default.png"
    build_png_256 "$DEFAULT_SRC" "$PNG_DIR/default.png"
  fi
fi

processed=0

# Step 2: Process all game screenshots in screenshots/
for src_png in "$SCREENSHOTS_DIR"/*.png; do
  [[ -f "$src_png" ]] || continue
  game="$(basename "$src_png" .png)"

  # Skip composite / editor screenshots (e.g. lolo_editor, duke_sector2)
  [[ "$game" == *_editor* || "$game" == *_play* || "$game" == *_sector* ]] && continue

  icns_dest="$ICNS_DIR/${game}.icns"
  png_dest="$PNG_DIR/${game}.png"

  # ---- macOS .icns -------------------------------------------------------- #
  if [[ ! -f "$icns_dest" ]]; then
    if have iconutil && have sips; then
      log "icns" "Building $game.icns with sips+iconutil"
      build_icns_with_iconutil "$src_png" "$icns_dest"
    elif have iconutil && have convert; then
      log "icns" "Building $game.icns with ImageMagick+iconutil"
      build_icns_with_imagemagick "$src_png" "$icns_dest"
    else
      log "SKIP" "$game.icns – need iconutil (macOS only)"
    fi
  else
    log "SKIP" "$game.icns already exists"
  fi

  # ---- Linux 256×256 PNG -------------------------------------------------- #
  if [[ ! -f "$png_dest" ]]; then
    log "png " "Resizing $game.png → 256×256"
    build_png_256 "$src_png" "$png_dest"
  else
    log "SKIP" "$game.png already exists"
  fi

  (( processed++ )) || true
done

# Step 3: Handle games in the workspace that don't have screenshots
for game_dir in "$ROOT_DIR"/*; do
  [[ -d "$game_dir" ]] || continue
  game="$(basename "$game_dir")"

  # Skip non-game directories
  [[ "$game" == "assets" || "$game" == "screenshots" || "$game" == "icons" || "$game" == ".git" ]] && continue
  if [[ ! -f "$game_dir/v.mod" ]] && [[ ! -f "$game_dir/main.v" ]] && ! ls "$game_dir"/*.v &>/dev/null 2>&1; then
    continue
  fi

  icns_dest="$ICNS_DIR/${game}.icns"
  png_dest="$PNG_DIR/${game}.png"

  if [[ ! -f "$icns_dest" ]] && [[ -f "$ICNS_DIR/default.icns" ]]; then
    log "icns" "Using default icon for $game (no screenshot found)"
    cp "$ICNS_DIR/default.icns" "$icns_dest"
  fi

  if [[ ! -f "$png_dest" ]] && [[ -f "$PNG_DIR/default.png" ]]; then
    log "png " "Using default icon for $game (no screenshot found)"
    cp "$PNG_DIR/default.png" "$png_dest"
  fi
done

echo ""
echo "Done. Processed $processed game(s)."
echo "  macOS icons : $ICNS_DIR"
echo "  Linux icons : $PNG_DIR"
