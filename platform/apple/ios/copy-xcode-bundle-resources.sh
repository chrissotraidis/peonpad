#!/bin/sh

set -eu

if [ "$#" -ne 4 ]; then
  echo "usage: $0 <cmake> <Aleona data> <launch PNG> <icon directory>" >&2
  exit 64
fi

: "${TARGET_BUILD_DIR:?Xcode did not provide TARGET_BUILD_DIR}"
: "${WRAPPER_NAME:?Xcode did not provide WRAPPER_NAME}"

CMAKE_COMMAND=$1
ALEONA_SOURCE=$2
LAUNCH_IMAGE=$3
ICON_DIR=$4
BUNDLE_PATH="$TARGET_BUILD_DIR/$WRAPPER_NAME"

[ -f "$ALEONA_SOURCE/scripts/stratagus.lua" ] || {
  echo "missing Aleona entry point: $ALEONA_SOURCE/scripts/stratagus.lua" >&2
  exit 1
}
[ -f "$LAUNCH_IMAGE" ] || {
  echo "missing PeonPad launch image: $LAUNCH_IMAGE" >&2
  exit 1
}

"$CMAKE_COMMAND" -E make_directory "$BUNDLE_PATH"
"$CMAKE_COMMAND" -E rm -rf "$BUNDLE_PATH/Aleona"
"$CMAKE_COMMAND" -E copy_directory "$ALEONA_SOURCE" "$BUNDLE_PATH/Aleona"
"$CMAKE_COMMAND" -E copy_if_different \
  "$LAUNCH_IMAGE" "$BUNDLE_PATH/PeonPadLaunch.png"

for icon in PeonPadIcon76.png PeonPadIcon76@2x.png PeonPadIcon83.5@2x.png; do
  [ -f "$ICON_DIR/$icon" ] || {
    echo "missing PeonPad iPad icon: $ICON_DIR/$icon" >&2
    exit 1
  }
  "$CMAKE_COMMAND" -E copy_if_different \
    "$ICON_DIR/$icon" "$BUNDLE_PATH/$icon"
done

# Finder and cloud-backed folders can attach metadata that codesign rejects.
if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$BUNDLE_PATH"
  xattr -d com.apple.FinderInfo "$BUNDLE_PATH" 2>/dev/null || true
  xattr -d 'com.apple.fileprovider.fpfs#P' "$BUNDLE_PATH" 2>/dev/null || true
fi
