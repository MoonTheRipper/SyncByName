# Sync by Name

Sync by Name is a native macOS SwiftUI utility for one specific job: compare source folders or drives against other folders or drives by filename only, then copy only the files whose names are missing from the comparison set.

It is built for the workflow users keep describing on forums when general-purpose sync tools are too path-aware:

- compare files by name, not by folder structure
- filter by file extensions such as `mp4`, `mov`, or `mxf`
- preview the missing files before copying anything
- copy the missing files into a chosen output folder
- preserve source-root groupings by default to avoid collisions

## Why This Exists

A recurring request in macOS app discussions is a utility that can answer:

> "I don't care about modification date or pathnames. I just want to know which filenames are missing and copy those somewhere."

Most sync tools optimize for mirroring trees. Sync by Name optimizes for filename-only collection and recovery.

## MVP Features

- multiple source folders
- multiple comparison folders
- recursive scanning
- case-sensitive or case-insensitive filename matching
- hidden-file scan toggle
- extension filtering
- preview of missing files with size and source path details
- copy plan execution into a chosen output folder
- optional preservation of source-root folder structure
- one-time welcome window with quick-start guidance
- dedicated Tutorials & Help and Support & Feedback windows
- menu bar extra for reopen, hide-to-top-bar, donate, and quit actions

## Build

```bash
HOME=/tmp/syncbyname-home \
CLANG_MODULE_CACHE_PATH=/tmp/syncbyname-modulecache \
SWIFTPM_MODULECACHE_OVERRIDE=/tmp/syncbyname-swiftpmcache \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift build --disable-sandbox
```

## Test

```bash
HOME=/tmp/syncbyname-home \
CLANG_MODULE_CACHE_PATH=/tmp/syncbyname-modulecache \
SWIFTPM_MODULECACHE_OVERRIDE=/tmp/syncbyname-swiftpmcache \
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift test --disable-sandbox
```

## Package A Release Build

```bash
zsh Scripts/package-release.sh
```

This creates ZIP and DMG artifacts in `docs/downloads/`.
