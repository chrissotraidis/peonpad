#!/bin/zsh

set -eu
setopt PIPE_FAIL

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
BUILD_ROOT=${PEONPAD_IOS_BUILD_DIR:-$ROOT_DIR/build/ios-arm64}
ENGINE_BUILD="$BUILD_ROOT/engine"
WARGUS_BUILD="$BUILD_ROOT/wargus"
TOOLCHAIN="$ROOT_DIR/cmake/toolchains/ios-arm64.cmake"
HOST_TOLUA=${STRATAGUS_HOST_TOLUAPP:-$ROOT_DIR/build/macos/engine/lua/src/lua-build/toluapp}
JOBS=${PEONPAD_BUILD_JOBS:-8}

EXPECTED_DIGEST=$(awk -F ' *= *' \
  '$1 == "tree_sha256" {gsub(/"/, "", $2); print $2; exit}' \
  "$ROOT_DIR/config/inputs.lock")
START_DIGEST=$($SCRIPT_DIR/reference-digest.sh)
[[ "$START_DIGEST" == "$EXPECTED_DIGEST" ]] || {
  print -u2 "ref/ does not match config/inputs.lock; refusing iOS build"
  exit 1
}

[[ -f "$TOOLCHAIN" ]] || {
  print -u2 "missing iOS device toolchain: $TOOLCHAIN"
  exit 1
}
[[ -x "$HOST_TOLUA" ]] || {
  print -u2 "missing host tolua generator: $HOST_TOLUA"
  print -u2 "run ./scripts/build-macos.sh first"
  exit 1
}

cmake --fresh -S "$ROOT_DIR/engine/stratagus" -B "$ENGINE_BUILD" \
  -G "Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_VENDORED_LUA=ON \
  -DBUILD_VENDORED_SDL=ON \
  -DSTRATAGUS_SDL_SOURCE_DIR="$("$ROOT_DIR/scripts/fetch-scene-sdl.sh")" \
  -DBUILD_VENDORED_MEDIA_LIBS=ON \
  -DBUILD_TESTING=OFF \
  -DDOWNLOAD_FREEPATS=OFF \
  -DENABLE_DEV=OFF \
  -DENABLE_DOC=OFF \
  -DWITH_OPENMP=OFF \
  -DWITH_STACKTRACE=OFF \
  -DHAVE_STRCPYS=OFF \
  -DHAVE_STRNCPYS=OFF \
  -DSTRATAGUS_HOST_TOLUAPP="$HOST_TOLUA"
cmake --build "$ENGINE_BUILD" --target stratagus_lib -j "$JOBS"

cmake --fresh -S "$ROOT_DIR/game/wargus" -B "$WARGUS_BUILD" \
  -G "Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
  -DCMAKE_BUILD_TYPE=Release \
  -DPEONPAD_IOS_DATA_LIBRARY=ON \
  -DSTRATAGUS_INCLUDE_DIR="$ROOT_DIR/engine/stratagus/gameheaders"
cmake --build "$WARGUS_BUILD" --target wargus_data -j "$JOBS"

ENGINE_ARCHIVE="$ENGINE_BUILD/libstratagus_lib.a"
WARGUS_ARCHIVE="$WARGUS_BUILD/libwargus_data.a"

verify_ios_archive() {
  local archive=$1
  [[ -f "$archive" ]] || {
    print -u2 "missing iOS archive: $archive"
    return 1
  }
  lipo -info "$archive" | grep -q 'architecture: arm64' || {
    print -u2 "archive is not a device arm64 slice: $archive"
    return 1
  }
  otool -l "$archive" | awk '
    $1 == "platform" {count++; if ($2 != 2) bad = 1}
    END {exit count == 0 || bad}
  ' || {
    print -u2 "archive contains a non-iOS object: $archive"
    return 1
  }
}

verify_ios_archive "$ENGINE_ARCHIVE"
verify_ios_archive "$WARGUS_ARCHIVE"

END_DIGEST=$($SCRIPT_DIR/reference-digest.sh)
[[ "$END_DIGEST" == "$START_DIGEST" ]] || {
  print -u2 "FATAL: ref/ changed during the iOS library build"
  exit 70
}

print "PeonPad iOS arm64 libraries built successfully:"
print "  engine:    $ENGINE_ARCHIVE"
print "  data:      $WARGUS_ARCHIVE"
print "  deployment: iOS/iPadOS 16.0"
print "  reference: unchanged ($END_DIGEST)"
