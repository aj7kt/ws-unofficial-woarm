#!/usr/bin/env bash
# Build the NSIS installer for the layout BUILD_DIR is configured for
# (WS-<version>-win-arm64-<layout>.exe on Windows on Arm).
#
#   ci/make-installer.sh BUILD_DIR OUTPUT_DIR
#
# makensis: $MAKENSIS, else makensis on PATH, else MSYS2's
# mingw-w64-x86_64-nsis (/mingw64/bin/makensis.exe). There is no ARM64
# build of NSIS; the x64 one runs emulated, and NSIS installers are 32-bit
# x86 programs whichever makensis builds them.
set -euo pipefail
BUILD=$(realpath "${1:?usage: make-installer.sh BUILD_DIR OUTPUT_DIR}")
OUT=$(realpath -m "${2:?}")
w () { cygpath -m "$1"; }

MAKENSIS=${MAKENSIS:-$(command -v makensis 2>/dev/null || echo /mingw64/bin/makensis.exe)}
[ -x "$MAKENSIS" ] || { echo "makensis not found (install mingw-w64-x86_64-nsis or set MAKENSIS)" >&2; exit 1; }

mkdir -p "$OUT"
cpack -G NSIS --config "$(w "$BUILD")/CPackConfig.cmake" -B "$(w "$OUT")" \
  -D CPACK_NSIS_EXECUTABLE="$(w "$MAKENSIS")"
# keep only the installers; drop CPack's staging tree
rm -rf "$OUT/_CPack_Packages"
ls -l "$OUT"/*.exe
