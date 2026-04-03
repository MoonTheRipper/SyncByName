#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

HOME=/tmp/syncbyname-home \
CLANG_MODULE_CACHE_PATH=/tmp/syncbyname-modulecache \
SWIFTPM_MODULECACHE_OVERRIDE=/tmp/syncbyname-swiftpmcache \
DEVELOPER_DIR="$DEVELOPER_DIR" \
"$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift" build --disable-sandbox --package-path "$ROOT_DIR"
