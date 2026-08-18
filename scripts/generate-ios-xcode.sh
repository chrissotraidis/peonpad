#!/bin/zsh

set -eu

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
TOOLCHAIN="$ROOT_DIR/cmake/toolchains/ios-arm64.cmake"
HOST_TOLUA=${STRATAGUS_HOST_TOLUAPP:-$ROOT_DIR/build/macos/engine/lua/src/lua-build/toluapp}
MODE=public
BUILD_MODE=""
DATA_DIR=""

usage() {
  cat <<'EOF'
Usage:
  ./scripts/generate-ios-xcode.sh --distribution [--maintainer]
  ./scripts/generate-ios-xcode.sh --local-data /path/to/data.Wargus [--maintainer]

--distribution  Generate an unsigned-capable, data-free release project.
--local-data    Generate the signed local-device project with explicit game data.
--maintainer    Also verify the immutable local ref/ fixture.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --distribution)
      [[ -z "$BUILD_MODE" ]] || { usage >&2; exit 2; }
      BUILD_MODE=distribution
      shift
      ;;
    --local-data)
      (( $# >= 2 )) || { print -u2 "--local-data requires a path"; exit 2; }
      [[ -z "$BUILD_MODE" ]] || { usage >&2; exit 2; }
      BUILD_MODE=local-data
      DATA_DIR=${2:A}
      shift 2
      ;;
    --maintainer)
      MODE=maintainer
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      print -u2 "unexpected argument: $1"
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "$BUILD_MODE" ]] || { usage >&2; exit 2; }
if [[ "$BUILD_MODE" == distribution ]]; then
  BUILD_DIR=${PEONPAD_IOS_XCODE_DIR:-$ROOT_DIR/build/ios-release-xcode}
  ENABLE_SIGNING=OFF
else
  BUILD_DIR=${PEONPAD_IOS_XCODE_DIR:-$ROOT_DIR/build/ios-xcode}
  ENABLE_SIGNING=ON
fi
BUILD_DIR=${BUILD_DIR:A}

START_DIGEST=""
if [[ "$MODE" == maintainer ]]; then
  EXPECTED_DIGEST=$(awk -F ' *= *' \
    '$1 == "tree_sha256" {gsub(/"/, "", $2); print $2; exit}' \
    "$ROOT_DIR/config/inputs.lock")
  START_DIGEST=$($SCRIPT_DIR/reference-digest.sh)
  [[ "$START_DIGEST" == "$EXPECTED_DIGEST" ]] || {
    print -u2 "ref/ does not match config/inputs.lock; refusing Xcode generation"
    exit 1
  }
fi
[[ -x "$HOST_TOLUA" ]] || {
  print -u2 "missing host tolua generator; run ./scripts/build-macos.sh first"
  exit 1
}
if [[ "$BUILD_MODE" == local-data ]]; then
  [[ -f "$DATA_DIR/scripts/stratagus.lua" ]] || {
    print -u2 "missing iOS data payload: $DATA_DIR"
    print -u2 "stage owned Warcraft II data with ./scripts/stage-ios-wc2-test-data.sh"
    exit 1
  }
fi
case "$BUILD_DIR/" in
  "$ROOT_DIR/build/"*) ;;
  *)
    print -u2 "iOS Xcode build directory must be inside $ROOT_DIR/build: $BUILD_DIR"
    exit 1
    ;;
esac

if [[ "$BUILD_MODE" == local-data \
      && "$DATA_DIR" == "$ROOT_DIR/assets/aleonas-tales/source" ]]; then
  "$SCRIPT_DIR/audit-aleona-assets.sh" --local-test
fi

# CMake --fresh resets only the top-level cache. ExternalProject dependency
# caches retain their original generator, so remove the script-owned build
# tree to guarantee every vendored dependency is configured consistently.
cmake -E remove_directory "$BUILD_DIR"

cmake --fresh -S "$ROOT_DIR/engine/stratagus" -B "$BUILD_DIR" \
  -G Xcode \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
  -DPEONPAD_IOS_ENABLE_SIGNING="$ENABLE_SIGNING" \
  -DBUILD_VENDORED_LUA=ON \
  -DBUILD_VENDORED_SDL=ON \
  -DBUILD_VENDORED_MEDIA_LIBS=ON \
  -DBUILD_TESTING=OFF \
  -DDOWNLOAD_FREEPATS=OFF \
  -DENABLE_DEV=OFF \
  -DENABLE_DOC=OFF \
  -DWITH_OPENMP=OFF \
  -DWITH_STACKTRACE=OFF \
  -DHAVE_STRCPYS=OFF \
  -DHAVE_STRNCPYS=OFF \
  -DSTRATAGUS_HOST_TOLUAPP="$HOST_TOLUA" \
  -DPEONPAD_IOS_INFO_PLIST="$ROOT_DIR/platform/apple/ios/Info.plist.in" \
  -DPEONPAD_IOS_DATA_DIR="$DATA_DIR" \
  -DPEONPAD_IOS_LAUNCH_IMAGE="$ROOT_DIR/platform/apple/ios/PeonPadLaunch.png" \
  -DPEONPAD_IOS_ICON_DIR="$ROOT_DIR/platform/apple/ios" \
  -DPEONPAD_APPLE_PLATFORM_DIR="$ROOT_DIR/platform/apple" \
  -DPEONPAD_SOURCE_PREFIX_MAP="$ROOT_DIR"

if [[ "$MODE" == maintainer ]]; then
  END_DIGEST=$($SCRIPT_DIR/reference-digest.sh)
  [[ "$END_DIGEST" == "$START_DIGEST" ]] || {
    print -u2 "FATAL: ref/ changed during Xcode project generation"
    exit 70
  }
fi

print "PeonPad native Xcode project generated:"
print "  $BUILD_DIR/stratagus.xcodeproj"
if [[ "$BUILD_MODE" == distribution ]]; then
  print "  content: data-free distribution build"
  print "  signing: disabled"
else
  print "  data: $DATA_DIR"
  print "  signing: Xcode automatic signing enabled"
fi
print
if [[ "$BUILD_MODE" == local-data ]]; then
  print "Open it in Xcode, select the stratagus target, choose your Personal Team"
  print "under Signing & Capabilities, select the connected iPad, then press Run."
  print "Apple ID credentials remain in Xcode; no third-party signing tool is used."
fi
