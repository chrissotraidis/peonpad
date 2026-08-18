#!/bin/zsh

set -eu
setopt PIPE_FAIL

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
BUILD_DIR=${PEONPAD_IOS_RELEASE_BUILD_DIR:-$ROOT_DIR/build/ios-release-xcode}
BUILD_DIR=${BUILD_DIR:A}
HOST_TOLUA=${STRATAGUS_HOST_TOLUAPP:-$ROOT_DIR/build/macos/engine/lua/src/lua-build/toluapp}
JOBS=${PEONPAD_BUILD_JOBS:-8}

case "$BUILD_DIR/" in
  "$ROOT_DIR/build/"*) ;;
  *)
    print -u2 "release build directory must be inside $ROOT_DIR/build: $BUILD_DIR"
    exit 1
    ;;
esac

"$SCRIPT_DIR/preflight.sh"
if [[ ! -x "$HOST_TOLUA" ]]; then
  "$SCRIPT_DIR/build-macos.sh"
fi

PEONPAD_IOS_XCODE_DIR="$BUILD_DIR" \
  "$SCRIPT_DIR/generate-ios-xcode.sh" --distribution

xcodebuild \
  -project "$BUILD_DIR/stratagus.xcodeproj" \
  -scheme stratagus \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  -jobs "$JOBS" \
  build

APP="$BUILD_DIR/Release-iphoneos/PeonPad.app"
"$SCRIPT_DIR/audit-ios-app.sh" "$APP"
print "Unsigned data-free release app built successfully: $APP"
