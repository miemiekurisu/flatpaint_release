#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PROJECT_FILE="$ROOT_DIR/flatpaint.lpi"
DEFAULT_BINARY="$ROOT_DIR/flatpaint"
LOCAL_APP_BUNDLE="$ROOT_DIR/flatpaint.app"
DIST_APP_BUNDLE="$ROOT_DIR/dist/FlatPaint.app"
RELEASE_DIR="$ROOT_DIR/dist/release"
RELEASE_BINARY="$RELEASE_DIR/flatpaint"
APP_BUNDLE_IDENTIFIER="${FLATPAINT_BUNDLE_ID:-com.flatpaint.app}"
APP_VERSION="${FLATPAINT_VERSION:-0.1.0}"
APP_BUILD="${FLATPAINT_BUILD:-1}"
APP_MIN_MACOS="${FLATPAINT_MIN_MACOS:-11.0}"
APP_ICON_SOURCE="${FLATPAINT_APP_ICON_SOURCE:-$ROOT_DIR/assets/app_icon/source.png}"
APP_ICON_BORDER_INSET="${FLATPAINT_APP_ICON_BORDER_INSET:-24}"
APP_ICON_BUILD_DIR="$ROOT_DIR/tmp/app_icon"
APP_ICON_TRIMMED_SOURCE="$APP_ICON_BUILD_DIR/AppIcon.source.trimmed.png"
APP_ICONSET_DIR="$APP_ICON_BUILD_DIR/AppIcon.iconset"
APP_ICON_ICNS="$APP_ICON_BUILD_DIR/AppIcon.icns"

log() {
  printf '==> %s\n' "$*"
}

find_lazbuild() {
  local candidate

  if [[ -n "${LAZBUILD:-}" && -x "${LAZBUILD}" ]]; then
    printf '%s\n' "${LAZBUILD}"
    return 0
  fi

  if command -v lazbuild >/dev/null 2>&1; then
    command -v lazbuild
    return 0
  fi

  # Resolve lazarus checkout relative to workspace (two levels up from project root)
  local workspace_lazarus
  workspace_lazarus="$(cd "$ROOT_DIR/../.." 2>/dev/null && pwd)/lazarus/lazbuild"

  for candidate in \
    "$workspace_lazarus" \
    "/opt/homebrew/bin/lazbuild" \
    "/usr/local/bin/lazbuild" \
    "/Applications/Lazarus/lazbuild"
  do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  printf 'Unable to find lazbuild. Set LAZBUILD=/absolute/path/to/lazbuild and retry.\n' >&2
  return 1
}

kill_running_flatpaint() {
  local killed=0
  local pattern

  for pattern in \
    "$DEFAULT_BINARY" \
    "$LOCAL_APP_BUNDLE/Contents/MacOS/flatpaint" \
    "$DIST_APP_BUNDLE/Contents/MacOS/FlatPaint" \
    "$ROOT_DIR/.build/debug/FlatPaintApp"
  do
    if pkill -f -- "$pattern" >/dev/null 2>&1; then
      log "Killed running process: $pattern"
      killed=1
    fi
  done

  if pkill -x flatpaint >/dev/null 2>&1; then
    log "Killed running process by name: flatpaint"
    killed=1
  fi

  if pkill -x FlatPaint >/dev/null 2>&1; then
    log "Killed running process by name: FlatPaint"
    killed=1
  fi

  if [[ "$killed" -eq 1 ]]; then
    sleep 1
  fi
}

copy_with_retry() {
  local source_path="$1"
  local destination_path="$2"

  mkdir -p -- "$(dirname -- "$destination_path")"
  if [[ -e "$destination_path" && "$source_path" -ef "$destination_path" ]]; then
    log "Skipping copy for $destination_path; it already resolves to $source_path"
    return 0
  fi
  if ! cp -f -- "$source_path" "$destination_path" 2>/dev/null; then
    log "Copy blocked for $destination_path; killing running FlatPaint processes and retrying"
    kill_running_flatpaint
    cp -f -- "$source_path" "$destination_path"
  fi
  chmod +x "$destination_path"
}

write_info_plist() {
  local plist_path="$1"
  local executable_name="$2"
  local bundle_name="$3"

  cat >"$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>English</string>
  <key>CFBundleExecutable</key>
  <string>${executable_name}</string>
  <key>CFBundleName</key>
  <string>${bundle_name}</string>
  <key>CFBundleIdentifier</key>
  <string>${APP_BUNDLE_IDENTIFIER}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleSignature</key>
  <string>flat</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${APP_BUILD}</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>LSMinimumSystemVersion</key>
  <string>${APP_MIN_MACOS}</string>
  <key>CSResourcesFileMapped</key>
  <true/>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeName</key>
      <string>FlatPaint Document</string>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>LSHandlerRank</key>
      <string>Owner</string>
      <key>CFBundleTypeExtensions</key>
      <array>
        <string>fpd</string>
      </array>
    </dict>
  </array>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF
}

stage_app_bundle() {
  local bundle_dir="$1"
  local executable_name="$2"
  local bundle_name="$3"
  local source_binary="$4"
  local icon_source_dir="$ROOT_DIR/assets/icons/rendered"
  local icon_dest_dir="$bundle_dir/Contents/Resources/icons/rendered"

  mkdir -p -- "$bundle_dir/Contents/MacOS" "$bundle_dir/Contents/Resources"
  write_info_plist "$bundle_dir/Contents/Info.plist" "$executable_name" "$bundle_name"
  printf 'APPLflat' >"$bundle_dir/Contents/PkgInfo"
  copy_with_retry "$source_binary" "$bundle_dir/Contents/MacOS/$executable_name"
  if [[ -f "$APP_ICON_ICNS" ]]; then
    cp -f -- "$APP_ICON_ICNS" "$bundle_dir/Contents/Resources/AppIcon.icns"
  fi
  if [[ -d "$icon_source_dir" ]]; then
    mkdir -p -- "$(dirname -- "$icon_dest_dir")"
    rm -rf -- "$icon_dest_dir"
    cp -R -- "$icon_source_dir" "$icon_dest_dir"
  fi
}

trim_app_icon_source() {
  local source_image="$1"
  local trimmed_image="$2"
  local tool_source="$SCRIPT_DIR/icon_crop_rgba.m"
  local tool_binary="$APP_ICON_BUILD_DIR/icon_crop_rgba"

  if [[ ! -f "$tool_source" ]]; then
    printf 'Missing icon crop tool source: %s\n' "$tool_source" >&2
    return 1
  fi

  if [[ ! -x "$tool_binary" || "$tool_source" -nt "$tool_binary" ]]; then
    clang -O2 -fobjc-arc \
      -framework AppKit \
      -framework Foundation \
      -framework CoreGraphics \
      -o "$tool_binary" \
      "$tool_source"
  fi

  "$tool_binary" "$source_image" "$trimmed_image" "$APP_ICON_BORDER_INSET"
}

generate_app_icon_assets() {
  local source_image="$APP_ICON_SOURCE"
  local trimmed_image="$APP_ICON_TRIMMED_SOURCE"
  local iconset_dir="$APP_ICONSET_DIR"
  local icon_icns="$APP_ICON_ICNS"
  local icon_tiff="$APP_ICON_BUILD_DIR/AppIcon.tiff"
  local icon_spec
  local icon_name
  local icon_size

  if [[ ! -f "$source_image" ]]; then
    log "No app icon source found at $source_image; app bundle icon will not be generated"
    return 0
  fi

  if ! command -v sips >/dev/null 2>&1; then
    log "sips unavailable; app bundle icon will not be generated"
    return 0
  fi

  rm -rf -- "$APP_ICON_BUILD_DIR"
  mkdir -p -- "$iconset_dir"

  trim_app_icon_source "$source_image" "$trimmed_image"

  for icon_spec in \
    "icon_16x16.png:16" \
    "icon_16x16@2x.png:32" \
    "icon_32x32.png:32" \
    "icon_32x32@2x.png:64" \
    "icon_128x128.png:128" \
    "icon_128x128@2x.png:256" \
    "icon_256x256.png:256" \
    "icon_256x256@2x.png:512" \
    "icon_512x512.png:512" \
    "icon_512x512@2x.png:1024"
  do
    IFS=':' read -r icon_name icon_size <<<"$icon_spec"
    sips -s format png -z "$icon_size" "$icon_size" "$trimmed_image" --out "$iconset_dir/$icon_name" >/dev/null
  done

  if command -v tiffutil >/dev/null 2>&1 && command -v tiff2icns >/dev/null 2>&1; then
    tiffutil -catnosizecheck \
      "$iconset_dir/icon_16x16.png" \
      "$iconset_dir/icon_16x16@2x.png" \
      "$iconset_dir/icon_32x32.png" \
      "$iconset_dir/icon_32x32@2x.png" \
      "$iconset_dir/icon_128x128.png" \
      "$iconset_dir/icon_128x128@2x.png" \
      "$iconset_dir/icon_256x256.png" \
      "$iconset_dir/icon_256x256@2x.png" \
      "$iconset_dir/icon_512x512.png" \
      "$iconset_dir/icon_512x512@2x.png" \
      -out "$icon_tiff" >/dev/null 2>&1
    tiff2icns "$icon_tiff" "$icon_icns" >/dev/null 2>&1
    return 0
  fi

  if command -v iconutil >/dev/null 2>&1; then
    iconutil -c icns "$iconset_dir" -o "$icon_icns"
    return 0
  fi

  log "No icon compiler available (tiff2icns/iconutil); app bundle icon will not be generated"
  return 0
}

run_lazbuild() {
  local lazbuild_path

  lazbuild_path="$(find_lazbuild)"
  if ! "$lazbuild_path" "$@"; then
    log "lazbuild failed once; retrying after killing running FlatPaint processes"
    kill_running_flatpaint
    "$lazbuild_path" "$@"
  fi
}

strip_binary_if_possible() {
  local binary_path="$1"

  if [[ ! -f "$binary_path" ]]; then
    return 0
  fi

  if ! command -v strip >/dev/null 2>&1; then
    log "strip not found; leaving $binary_path unstripped"
    return 0
  fi

  if [[ "$(uname -s)" == "Darwin" ]]; then
    strip -x "$binary_path" >/dev/null 2>&1 || strip "$binary_path" >/dev/null 2>&1 || true
  else
    strip --strip-unneeded "$binary_path" >/dev/null 2>&1 || strip "$binary_path" >/dev/null 2>&1 || true
  fi
}

compile_native_modules() {
  local arch
  local output_dir
  local src_dir="$ROOT_DIR/src/native"
  local min_macos="$APP_MIN_MACOS"

  # Determine target architecture
  arch="$(uname -m)"
  if [[ "$arch" == "arm64" ]]; then
    arch="aarch64"
  fi
  output_dir="$ROOT_DIR/lib/${arch}-darwin"
  mkdir -p "$output_dir"

  if [[ -f "$src_dir/fp_magnify.m" ]]; then
    log "Compiling native module: fp_magnify.m"
    clang -c -O2 \
      -arch "$(uname -m)" \
      -mmacosx-version-min="$min_macos" \
      -fobjc-arc \
      -framework Cocoa \
      -o "$output_dir/fp_magnify.o" \
      "$src_dir/fp_magnify.m"
  fi

  if [[ -f "$src_dir/fp_alpha.m" ]]; then
    log "Compiling native module: fp_alpha.m"
    clang -c -O2 \
      -arch "$(uname -m)" \
      -mmacosx-version-min="$min_macos" \
      -fobjc-arc \
      -framework Cocoa \
      -o "$output_dir/fp_alpha.o" \
      "$src_dir/fp_alpha.m"
  fi

  if [[ -f "$src_dir/fp_listbg.m" ]]; then
    log "Compiling native module: fp_listbg.m"
    clang -c -O2 \
      -arch "$(uname -m)" \
      -mmacosx-version-min="$min_macos" \
      -fobjc-arc \
      -framework Cocoa \
      -o "$output_dir/fp_listbg.o" \
      "$src_dir/fp_listbg.m"
  fi

  if [[ -f "$src_dir/fp_appearance.m" ]]; then
    log "Compiling native module: fp_appearance.m"
    clang -c -O2 \
      -arch "$(uname -m)" \
      -mmacosx-version-min="$min_macos" \
      -fobjc-arc \
      -framework Cocoa \
      -o "$output_dir/fp_appearance.o" \
      "$src_dir/fp_appearance.m"
  fi

  if [[ -f "$src_dir/fp_scrollview.m" ]]; then
    log "Compiling native module: fp_scrollview.m"
    clang -c -O2 \
      -arch "$(uname -m)" \
      -mmacosx-version-min="$min_macos" \
      -fobjc-arc \
      -framework Cocoa \
      -o "$output_dir/fp_scrollview.o" \
      "$src_dir/fp_scrollview.m"
  fi

  if [[ -f "$src_dir/fp_cgrender.m" ]]; then
    log "Compiling native module: fp_cgrender.m"
    clang -c -O2 \
      -arch "$(uname -m)" \
      -mmacosx-version-min="$min_macos" \
      -fobjc-arc \
      -framework Cocoa -framework CoreGraphics \
      -o "$output_dir/fp_cgrender.o" \
      "$src_dir/fp_cgrender.m"
  fi
}

clean_generated_artifacts() {
  log "Removing generated outputs"
  rm -rf -- \
    "$ROOT_DIR/dist" \
    "$ROOT_DIR/lib" \
    "$ROOT_DIR/tmp/app_icon" \
    "$ROOT_DIR/flatpaint" \
    "$ROOT_DIR/flatpaint.app" \
    "$ROOT_DIR/src/cli/flatpaint_cli"

  # Remove stale object files / debug symbols / session files in project root
  find "$ROOT_DIR" -maxdepth 1 \( -name '*.o' -o -name '*.ppu' -o -name '*.lps' \) -delete 2>/dev/null || true
  find "$ROOT_DIR" -maxdepth 1 -name '*.dSYM' -type d -exec rm -rf {} + 2>/dev/null || true

  mkdir -p -- "$ROOT_DIR/dist" "$ROOT_DIR/lib"
}

prepare_icon_assets() {
  local rendered_dir="$ROOT_DIR/assets/icons/rendered"

  if compgen -G "$rendered_dir/*.svg.png" >/dev/null 2>&1; then
    return 0
  fi

  printf 'Pre-rendered Lucide icon assets were not found under %s.\n' "$rendered_dir" >&2
  printf 'This build now expects checked-in icon assets and will fall back to generated glyphs until the assets are refreshed manually.\n' >&2
  return 0
}

refresh_about_content() {
  local generator_script="$SCRIPT_DIR/generate_about_content.sh"

  if [[ ! -f "$generator_script" ]]; then
    printf 'Missing required about-content generator: %s\n' "$generator_script" >&2
    return 1
  fi

  log "Refreshing compiled About content from assets/about"
  bash "$generator_script"
}

build_default_artifacts() {
  clean_generated_artifacts
  kill_running_flatpaint
  compile_native_modules
  prepare_icon_assets
  generate_app_icon_assets
  refresh_about_content
  run_lazbuild -B "$PROJECT_FILE"

  if [[ ! -f "$DEFAULT_BINARY" ]]; then
    printf 'Expected build output %s was not produced.\n' "$DEFAULT_BINARY" >&2
    return 1
  fi

  stage_app_bundle "$DIST_APP_BUNDLE" "FlatPaint" "FlatPaint" "$DEFAULT_BINARY"
}

build_release_artifacts() {
  clean_generated_artifacts
  kill_running_flatpaint
  compile_native_modules
  prepare_icon_assets
  generate_app_icon_assets
  refresh_about_content
  # -CX: smartlink each compiled unit (FPC guide: dead-code removal at unit level)
  # -XX: smartlink the final linked program
  # -O2 is already set in the project file; listed here explicitly for release traceability
  run_lazbuild -B "$PROJECT_FILE" --opt="-O2 -CX -XX"

  if [[ ! -f "$DEFAULT_BINARY" ]]; then
    printf 'Expected build output %s was not produced.\n' "$DEFAULT_BINARY" >&2
    return 1
  fi

  mkdir -p -- "$RELEASE_DIR"
  copy_with_retry "$DEFAULT_BINARY" "$RELEASE_BINARY"
  strip_binary_if_possible "$RELEASE_BINARY"

  stage_app_bundle "$LOCAL_APP_BUNDLE" "flatpaint" "FlatPaint" "$DEFAULT_BINARY"
  stage_app_bundle "$DIST_APP_BUNDLE" "FlatPaint" "FlatPaint" "$RELEASE_BINARY"
  strip_binary_if_possible "$DIST_APP_BUNDLE/Contents/MacOS/FlatPaint"
}
