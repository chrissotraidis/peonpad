#!/bin/zsh

set -eu
setopt PIPE_FAIL

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
BUILD_ROOT=${PEONPAD_IOS_BUILD_DIR:-$ROOT_DIR/build/ios-arm64}
ENGINE_BUILD="$BUILD_ROOT/engine"
TOOLCHAIN="$ROOT_DIR/cmake/toolchains/ios-arm64.cmake"
INFO_PLIST="$ROOT_DIR/platform/apple/ios/Info.plist.in"
ALEONA_DATA="$ROOT_DIR/assets/aleonas-tales/source"
LAUNCH_IMAGE="$ROOT_DIR/platform/apple/ios/PeonPadLaunch.png"
ICON_DIR="$ROOT_DIR/platform/apple/ios"
HOST_TOLUA=${STRATAGUS_HOST_TOLUAPP:-$ROOT_DIR/build/macos/engine/lua/src/lua-build/toluapp}
JOBS=${PEONPAD_BUILD_JOBS:-8}

EXPECTED_DIGEST=$(awk -F ' *= *' \
  '$1 == "tree_sha256" {gsub(/"/, "", $2); print $2; exit}' \
  "$ROOT_DIR/config/inputs.lock")
START_DIGEST=$($SCRIPT_DIR/reference-digest.sh)
[[ "$START_DIGEST" == "$EXPECTED_DIGEST" ]] || {
  print -u2 "ref/ does not match config/inputs.lock; refusing iOS app build"
  exit 1
}

[[ -f "$TOOLCHAIN" ]] || {
  print -u2 "missing iOS device toolchain: $TOOLCHAIN"
  exit 1
}
[[ -f "$INFO_PLIST" ]] || {
  print -u2 "missing iOS Info.plist template: $INFO_PLIST"
  exit 1
}
[[ -f "$LAUNCH_IMAGE" ]] || {
  print -u2 "missing PeonPad launch image: $LAUNCH_IMAGE"
  exit 1
}
for icon in PeonPadIcon76.png PeonPadIcon76@2x.png PeonPadIcon83.5@2x.png; do
  [[ -f "$ICON_DIR/$icon" ]] || {
    print -u2 "missing PeonPad iPad icon: $ICON_DIR/$icon"
    exit 1
  }
done
[[ -f "$ALEONA_DATA/scripts/stratagus.lua" ]] || {
  print -u2 "missing staged Aleona game data: $ALEONA_DATA"
  exit 1
}
[[ -x "$HOST_TOLUA" ]] || {
  print -u2 "missing host tolua generator: $HOST_TOLUA"
  print -u2 "run ./scripts/build-macos.sh first"
  exit 1
}

if [[ "${PEONPAD_DISTRIBUTION_BUILD:-0}" == 1 ]]; then
  "$SCRIPT_DIR/audit-aleona-assets.sh" --strict
else
  "$SCRIPT_DIR/audit-aleona-assets.sh" --local-test
fi
"$SCRIPT_DIR/test-ios-viewport.sh"
"$SCRIPT_DIR/test-ios-control-groups.sh"

cmake --fresh -S "$ROOT_DIR/engine/stratagus" -B "$ENGINE_BUILD" \
  -G "Unix Makefiles" \
  -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
  -DCMAKE_BUILD_TYPE=Release \
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
  -DPEONPAD_IOS_INFO_PLIST="$INFO_PLIST" \
  -DPEONPAD_IOS_DATA_DIR="$ALEONA_DATA" \
  -DPEONPAD_IOS_LAUNCH_IMAGE="$LAUNCH_IMAGE" \
  -DPEONPAD_IOS_ICON_DIR="$ICON_DIR" \
  -DPEONPAD_APPLE_PLATFORM_DIR="$ROOT_DIR/platform/apple"
cmake --build "$ENGINE_BUILD" --target stratagus -j "$JOBS"

APP="$ENGINE_BUILD/PeonPad.app"
EXECUTABLE="$APP/PeonPad"

[[ -f "$EXECUTABLE" ]] || {
  print -u2 "missing iOS app executable: $EXECUTABLE"
  exit 1
}
[[ -f "$APP/Info.plist" ]] || {
  print -u2 "missing generated app Info.plist"
  exit 1
}
[[ -f "$APP/Aleona/scripts/stratagus.lua" ]] || {
  print -u2 "Aleona data was not copied into the app"
  exit 1
}
[[ -f "$APP/PeonPadLaunch.png" ]] || {
  print -u2 "PeonPad launch image was not copied into the app"
  exit 1
}
cmp -s "$LAUNCH_IMAGE" "$APP/PeonPadLaunch.png" || {
  print -u2 "bundled PeonPad launch image differs from the project source"
  exit 1
}
for icon in PeonPadIcon76.png PeonPadIcon76@2x.png PeonPadIcon83.5@2x.png; do
  cmp -s "$ICON_DIR/$icon" "$APP/$icon" || {
    print -u2 "missing or stale bundled PeonPad iPad icon: $icon"
    exit 1
  }
done
nm "$EXECUTABLE" | grep 'PeonPadIOSApplySafeAreaViewport' >/dev/null || {
  print -u2 "iOS safe-area viewport bridge is missing from the app"
  exit 1
}

lipo -info "$EXECUTABLE" | grep -q 'architecture: arm64' || {
  print -u2 "app executable is not a physical-device arm64 slice"
  exit 1
}
otool -l "$EXECUTABLE" | awk '
  $1 == "platform" {platform = $2}
  $1 == "minos" {minos = $2}
  END {exit platform != 2 || minos != "16.0"}
' || {
  print -u2 "app executable is not an iOS 16.0 device binary"
  exit 1
}

[[ "$(plutil -extract CFBundleIdentifier raw "$APP/Info.plist")" == \
    "org.peonpad.ios" ]] || {
  print -u2 "unexpected iOS bundle identifier"
  exit 1
}
[[ "$(plutil -extract UIApplicationSupportsIndirectInputEvents raw \
    "$APP/Info.plist")" == "true" ]] || {
  print -u2 "indirect pointer input is not enabled"
  exit 1
}
[[ "$(plutil -extract UILaunchScreen.UIImageName raw "$APP/Info.plist")" == \
    "PeonPadLaunch" ]] || {
  print -u2 "PeonPad launch image is not declared in Info.plist"
  exit 1
}
[[ "$(plutil -extract 'CFBundleIcons~ipad'.CFBundlePrimaryIcon.CFBundleIconFiles.0 raw \
    "$APP/Info.plist")" == "PeonPadIcon76" ]] || {
  print -u2 "PeonPad iPad icon is not declared in Info.plist"
  exit 1
}

PROPRIETARY_HIT=$(find "$APP" \
  \( -type d -iname 'data.Wargus' \
  -o -type f \( -iname '*.mpq' -o -iname 'INSTALL.EXE' \
  -o -iname 'WAR2DAT.MPQ' \) \) -print -quit)
[[ -z "$PROPRIETARY_HIT" ]] || {
  print -u2 "proprietary Warcraft II data found in app: $PROPRIETARY_HIT"
  exit 1
}

END_DIGEST=$($SCRIPT_DIR/reference-digest.sh)
[[ "$END_DIGEST" == "$START_DIGEST" ]] || {
  print -u2 "FATAL: ref/ changed during the iOS app build"
  exit 70
}

print "PeonPad unsigned iOS device app built successfully:"
print "  app:        $APP"
print "  executable: arm64 iOS 16.0"
print "  content:    Aleona local-test snapshot; no Blizzard data"
print "  signing:    intentionally unsigned"
print "  reference:  unchanged ($END_DIGEST)"
print
print "LEGAL GATE: Aleona asset licensing is REVIEW_REQUIRED_BEFORE_BUNDLING."
print "This bundle is for local device testing, not release distribution."
