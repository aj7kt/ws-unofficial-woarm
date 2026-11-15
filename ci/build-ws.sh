#!/usr/bin/env bash
# Configure, build and install WS with an MSYS2 CLANG* toolchain
# (clang + LLVM flang + Qt 6), e.g. for native arm64 Windows.
#
#   ci/build-ws.sh SRC_DIR BUILD_DIR INSTALL_PREFIX HAMLIB_PREFIX [cmake args...]
#
# Environment: WS_LAYOUT=standard|al|widescreen (default standard).
#
# Re-running it on the same BUILD_DIR with another WS_LAYOUT and
# INSTALL_PREFIX only rebuilds ws.exe: the layout affects that target alone,
# and the prefix is given at install time, not configure time.
#
# INSTALL_PREFIX must not be "install" inside the source tree: the sources
# have an INSTALL file, and Windows file names are case-insensitive.
set -euo pipefail

SRC=$(realpath "${1:?usage: build-ws.sh SRC_DIR BUILD_DIR INSTALL_PREFIX HAMLIB_PREFIX [cmake args]}")
BUILD=$(realpath -m "${2:?}"); PREFIX=$(realpath -m "${3:?}"); HAMLIB=$(realpath "${4:?}"); shift 4

# Native (non-MSYS) cmake.exe wants Windows-form paths; MSYS2 does not
# convert paths inside ;-separated lists.
w () { cygpath -m "$1"; }
mkdir -p "$BUILD"

cmake -S "$(w "$SRC")" -B "$(w "$BUILD")" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_Fortran_COMPILER=flang \
  "-DCMAKE_PREFIX_PATH=$(w "$HAMLIB");$(w "$MINGW_PREFIX")" \
  -DWSJT_GENERATE_DOCS=OFF \
  -DWS_LAYOUT="${WS_LAYOUT:-standard}" \
  "$@"

cmake --build "$(w "$BUILD")" -j"$(nproc)"
cmake --install "$(w "$BUILD")" --prefix "$(w "$PREFIX")"
