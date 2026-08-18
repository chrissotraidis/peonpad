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
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd)

[ -z "$ALEONA_SOURCE" ] || [ -f "$ALEONA_SOURCE/scripts/stratagus.lua" ] || {
  echo "missing local-test entry point: $ALEONA_SOURCE/scripts/stratagus.lua" >&2
  exit 1
}
[ -f "$LAUNCH_IMAGE" ] || {
  echo "missing PeonPad launch image: $LAUNCH_IMAGE" >&2
  exit 1
}

"$CMAKE_COMMAND" -E make_directory "$BUNDLE_PATH"
"$CMAKE_COMMAND" -E rm -rf "$BUNDLE_PATH/Aleona"
if [ -n "$ALEONA_SOURCE" ]; then
  "$CMAKE_COMMAND" -E copy_directory "$ALEONA_SOURCE" "$BUNDLE_PATH/Aleona"
fi
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

for legal in LICENSE NOTICE THIRD_PARTY_NOTICES.md; do
  [ -f "$ROOT_DIR/$legal" ] || {
    echo "missing PeonPad legal resource: $legal" >&2
    exit 1
  }
  "$CMAKE_COMMAND" -E copy_if_different "$ROOT_DIR/$legal" "$BUNDLE_PATH/$legal"
done

"$CMAKE_COMMAND" -E rm -rf "$BUNDLE_PATH/Licenses"
"$CMAKE_COMMAND" -E make_directory "$BUNDLE_PATH/Licenses"
copy_license() {
  source_path=$1
  output_name=$2
  [ -f "$ROOT_DIR/$source_path" ] || {
    echo "missing third-party license source: $source_path" >&2
    exit 1
  }
  "$CMAKE_COMMAND" -E copy_if_different \
    "$ROOT_DIR/$source_path" "$BUNDLE_PATH/Licenses/$output_name"
}

copy_license engine/stratagus/COPYING Stratagus-COPYING.txt
copy_license game/wargus/COPYING Wargus-COPYING.txt
copy_license game/wargus/COPYING-3rd Wargus-COPYING-3rd.txt
copy_license engine/stratagus/third-party/SDL/LICENSE.txt SDL2-LICENSE.txt
copy_license engine/stratagus/third-party/SDL_image/LICENSE.txt SDL2_image-LICENSE.txt
copy_license engine/stratagus/third-party/SDL_mixer/LICENSE.txt SDL2_mixer-LICENSE.txt
copy_license engine/stratagus/third-party/SDL_mixer/src/codecs/dr_libs/LICENSE dr_libs-LICENSE.txt
copy_license engine/stratagus/third-party/SDL_mixer/src/codecs/stb_vorbis/README.txt stb_vorbis-README.txt
copy_license engine/stratagus/third-party/SDL_mixer/src/codecs/timidity/COPYING timidity-COPYING.txt
copy_license engine/stratagus/third-party/lua-5.1.5/COPYRIGHT Lua-COPYRIGHT.txt
copy_license engine/stratagus/third-party/lua-5.1.5/toluapp-simple/COPYRIGHT toluapp-COPYRIGHT.txt
copy_license engine/stratagus/third-party/SDL_image/external/zlib/README zlib-README.txt
copy_license engine/stratagus/third-party/SDL_image/external/libpng/LICENSE libpng-LICENSE.txt
copy_license engine/stratagus/third-party/bzip2/LICENSE bzip2-LICENSE.txt
copy_license engine/stratagus/third-party/SDL_mixer/external/ogg/COPYING libogg-COPYING.txt
copy_license engine/stratagus/third-party/SDL_mixer/external/vorbis/COPYING libvorbis-COPYING.txt
copy_license engine/stratagus/third-party/theora/COPYING libtheora-COPYING.txt
copy_license engine/stratagus/third-party/SDL_image/external/jpeg/README jpeg-README.txt
copy_license engine/stratagus/third-party/lcms/COPYING lcms-COPYING.txt
copy_license engine/stratagus/third-party/libmng/LICENSE libmng-LICENSE.txt
copy_license engine/stratagus/third-party/guisan/COPYING guisan-COPYING.txt
copy_license engine/stratagus/third-party/unsf/LICENSE unsf-LICENSE.txt
copy_license engine/stratagus/third-party/mdns/LICENSE mdns-LICENSE.txt
copy_license engine/stratagus/third-party/spiritless_po/LICENSE spiritless_po-LICENSE.txt

# Finder and cloud-backed folders can attach metadata that codesign rejects.
if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$BUNDLE_PATH"
  xattr -d com.apple.FinderInfo "$BUNDLE_PATH" 2>/dev/null || true
  xattr -d 'com.apple.fileprovider.fpfs#P' "$BUNDLE_PATH" 2>/dev/null || true
fi
