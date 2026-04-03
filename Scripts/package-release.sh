#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
SWIFT_BIN="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift"
VERSION="${1:-$(awk -F'"' '/defaultVersion/ { print $2; exit }' "$ROOT_DIR/Sources/SyncByNameCore/Models/AppMetadata.swift")}"
SANITIZED_PREFIX="/SyncByName"

TMP_BASE="$(mktemp -d "${TMPDIR:-/tmp}/syncbyname-release.XXXXXX")"
BUILD_HOME="$TMP_BASE/home"
MODULE_CACHE="$TMP_BASE/module-cache"
SWIFTPM_CACHE="$TMP_BASE/swiftpm-cache"
APP_STAGING="$TMP_BASE/SyncByName.app"
CONTENTS_DIR="$APP_STAGING/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
OUTPUT_DIR="$ROOT_DIR/Artifacts/releases"
ZIP_PATH="$OUTPUT_DIR/SyncByName-${VERSION}-macOS-arm64.zip"
DMG_PATH="$OUTPUT_DIR/SyncByName-${VERSION}-macOS-arm64.dmg"
BUILD_ARGS=(
  -c release
  --disable-sandbox
  -Xswiftc -gnone
  -Xswiftc -file-prefix-map
  -Xswiftc "${ROOT_DIR}=${SANITIZED_PREFIX}"
  -Xswiftc -debug-prefix-map
  -Xswiftc "${ROOT_DIR}=${SANITIZED_PREFIX}"
  -Xswiftc -coverage-prefix-map
  -Xswiftc "${ROOT_DIR}=${SANITIZED_PREFIX}"
  -Xcc "-fdebug-prefix-map=${ROOT_DIR}=${SANITIZED_PREFIX}"
)

mkdir -p "$BUILD_HOME" "$MODULE_CACHE" "$SWIFTPM_CACHE" "$MACOS_DIR" "$OUTPUT_DIR"

export HOME="$BUILD_HOME"
export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE"
export SWIFTPM_MODULECACHE_OVERRIDE="$SWIFTPM_CACHE"
export DEVELOPER_DIR

"$SWIFT_BIN" package clean
"$SWIFT_BIN" build "${BUILD_ARGS[@]}"

RESOURCE_ACCESSOR="$(find "$ROOT_DIR/.build" -path '*DerivedSources/resource_bundle_accessor.swift' -print -quit || true)"
if [[ -n "$RESOURCE_ACCESSOR" && -f "$RESOURCE_ACCESSOR" ]]; then
  sed -i '' "s|$ROOT_DIR|$SANITIZED_PREFIX|g" "$RESOURCE_ACCESSOR"
fi

"$SWIFT_BIN" build "${BUILD_ARGS[@]}"

BIN_DIR="$("$SWIFT_BIN" build "${BUILD_ARGS[@]}" --show-bin-path)"
EXECUTABLE_PATH="$BIN_DIR/SyncByName"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
  echo "Missing executable at $EXECUTABLE_PATH" >&2
  exit 1
fi

cp "$EXECUTABLE_PATH" "$MACOS_DIR/SyncByName"
strip -S -x "$MACOS_DIR/SyncByName"

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>Sync by Name</string>
  <key>CFBundleExecutable</key>
  <string>SyncByName</string>
  <key>CFBundleIdentifier</key>
  <string>com.moontheripper.SyncByName</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>SyncByName</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${VERSION}</string>
  <key>CFBundleVersion</key>
  <string>${VERSION}</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

codesign --force --deep --sign - "$APP_STAGING" >/dev/null

rm -f "$ZIP_PATH" "$DMG_PATH"
(cd "$TMP_BASE" && COPYFILE_DISABLE=1 zip -qry "$ZIP_PATH" "SyncByName.app")
hdiutil create -volname "SyncByName" -srcfolder "$APP_STAGING" -ov -format UDZO "$DMG_PATH" >/dev/null

echo "Created:"
echo "  $ZIP_PATH"
echo "  $DMG_PATH"
