#!/usr/bin/env bash
# build_mac_desktop_apps.sh – Compile V/SDL2 games and create macOS .app bundles
# with proper icons, Info.plist, and Desktop/Applications shortcuts.
#
# Usage:
#   ./build_mac_desktop_apps.sh [desktop_output_dir]
#
# What it does per game:
#   1. Compiles the game binary with `v -o <game> .`
#   2. Creates  <game>.app/
#                ├── Contents/
#                │    ├── Info.plist
#                │    ├── MacOS/<game>          ← compiled binary (wrapper script)
#                │    └── Resources/<game>.icns ← icon
#   3. Copies the .app bundle to ~/Desktop/VSDL_Games/ and /Applications/VSDL_Games/
#
# Requirements:
#   - V compiler  (https://vlang.io)
#   - SDL2 installed via Homebrew (brew install sdl2 sdl2_image sdl2_mixer sdl2_ttf)
#   - Icons pre-generated with generate_icons.sh (will auto-run if not present)
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_DIR="${1:-$HOME/Desktop/VSDL_Games}"
APPS_DIR="/Applications/VSDL_Games"
ICONS_DIR="$ROOT_DIR/icons/icns"
JOBS="${JOBS:-$(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)}"

# Homebrew prefix (handles Apple Silicon /opt/homebrew and Intel /usr/local)
BREW_PREFIX="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"

export PKG_CONFIG_PATH="${BREW_PREFIX}/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export LIBRARY_PATH="${BREW_PREFIX}/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
export DYLD_LIBRARY_PATH="${BREW_PREFIX}/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
export C_INCLUDE_PATH="${BREW_PREFIX}/include${C_INCLUDE_PATH:+:$C_INCLUDE_PATH}"

# --------------------------------------------------------------------------- #
# Ensure icons have been generated
# --------------------------------------------------------------------------- #

if [[ ! -d "$ICONS_DIR" ]] || [[ -z "$(ls -A "$ICONS_DIR" 2>/dev/null)" ]]; then
  echo "Icons not found – running generate_icons.sh first..."
  bash "$ROOT_DIR/generate_icons.sh"
fi

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

cleanup_old_apps() {
  for target_dir in "$DESKTOP_DIR" "$APPS_DIR"; do
    if [[ -d "$target_dir" ]]; then
      find "$target_dir" -maxdepth 1 -name '*.app' -exec rm -rf {} + 2>/dev/null || true
    else
      mkdir -p "$target_dir"
    fi
  done
}

make_app_bundle() {
  local game_dir="$1"
  local game_name="$2"
  local binary="$game_dir/$game_name"
  local bundle_root="$game_dir/${game_name}.app"
  local contents="$bundle_root/Contents"
  local macos_dir="$contents/MacOS"
  local resources_dir="$contents/Resources"

  rm -rf "$bundle_root"
  mkdir -p "$macos_dir" "$resources_dir"

  # ---- Launcher wrapper script ------------------------------------------- #
  # We use a wrapper so the binary inherits the correct DYLD_LIBRARY_PATH and
  # working directory (games load assets relative to their own directory).
  local launcher="$macos_dir/$game_name"
  cat > "$launcher" <<LAUNCHER
#!/usr/bin/env bash
export DYLD_LIBRARY_PATH="${BREW_PREFIX}/lib\${DYLD_LIBRARY_PATH:+:\$DYLD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="${BREW_PREFIX}/lib/pkgconfig\${PKG_CONFIG_PATH:+:\$PKG_CONFIG_PATH}"
cd "${game_dir}"
exec "${binary}" "\$@"
LAUNCHER
  chmod +x "$launcher"

  # ---- Icon -------------------------------------------------------------- #
  local icns="$ICONS_DIR/${game_name}.icns"
  if [[ -f "$icns" ]]; then
    cp "$icns" "$resources_dir/${game_name}.icns"
  elif [[ -f "$ICONS_DIR/default.icns" ]]; then
    cp "$ICONS_DIR/default.icns" "$resources_dir/${game_name}.icns"
  fi

  # ---- Info.plist -------------------------------------------------------- #
  local bundle_id
  bundle_id="com.vsdlgames.$(echo "$game_name" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')"
  cat > "$contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${game_name}</string>
  <key>CFBundleDisplayName</key>
  <string>${game_name}</string>
  <key>CFBundleIdentifier</key>
  <string>${bundle_id}</string>
  <key>CFBundleVersion</key>
  <string>1.0.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleSignature</key>
  <string>????</string>
  <key>CFBundleExecutable</key>
  <string>${game_name}</string>
  <key>CFBundleIconFile</key>
  <string>${game_name}</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.games</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST
}

# --------------------------------------------------------------------------- #
# Build a single game
# --------------------------------------------------------------------------- #

build_one() {
  local game_dir="$1"
  local game_name
  game_name="$(basename "$game_dir")"

  # Skip directories that aren't V games
  if [[ ! -f "$game_dir/v.mod" ]] && [[ ! -f "$game_dir/main.v" ]] \
     && ! ls "$game_dir"/*.v &>/dev/null 2>&1; then
    return 0
  fi

  echo "Building $game_name..."
  ( cd "$game_dir" && v -o "$game_name" . ) || {
    echo "  [WARN] Build failed for $game_name – skipping"
    return 0
  }

  echo "  Packaging $game_name.app..."
  make_app_bundle "$game_dir" "$game_name"

  # ---- Deploy .app bundles to Desktop and /Applications ------------------ #
  for target_dir in "$DESKTOP_DIR" "$APPS_DIR"; do
    mkdir -p "$target_dir"
    local dest="$target_dir/${game_name}.app"
    cp -R "$game_dir/${game_name}.app" "$dest"
    # Tell Finder to update its icon cache for this bundle
    touch "$dest"
    echo "  → $dest"
  done
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

cleanup_old_apps
mkdir -p "$DESKTOP_DIR" "$APPS_DIR"

mapfile -t game_dirs < <(
  find "$ROOT_DIR" -mindepth 1 -maxdepth 1 -type d \
    ! -name "assets" ! -name "screenshots" ! -name "icons" \
    ! -name ".git" -print | sort
)

export -f build_one make_app_bundle
export DESKTOP_DIR APPS_DIR ICONS_DIR ROOT_DIR BREW_PREFIX
export PKG_CONFIG_PATH LIBRARY_PATH DYLD_LIBRARY_PATH C_INCLUDE_PATH

printf '%s\n' "${game_dirs[@]}" \
  | xargs -P "$JOBS" -I{} bash -c 'build_one "$1"' _ {}

# Refresh Launch Services database so Spotlight / Launchpad picks up the apps
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -r "$APPS_DIR" 2>/dev/null || true

echo ""
echo "Done."
echo "  Desktop apps : $DESKTOP_DIR"
echo "  Applications : $APPS_DIR"
echo ""
echo "Tip: If Gatekeeper blocks an app, run:"
echo "  xattr -rd com.apple.quarantine <app>.app"
