#!/bin/zsh

set -eu

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
MACOS_BUILD_DIR=${PEONPAD_MACOS_BUILD_DIR:-$ROOT_DIR/build/macos}
MACOS_BUILD_DIR=${MACOS_BUILD_DIR:A}
ENCODER_BUILD_DIR="$MACOS_BUILD_DIR/theora-encoder"

case "$MACOS_BUILD_DIR/" in
  "$ROOT_DIR/build/"*) ;;
  *)
    print -u2 "macOS build directory must be inside $ROOT_DIR/build: $MACOS_BUILD_DIR"
    exit 1
    ;;
esac

OGG_LIBRARY="$MACOS_BUILD_DIR/engine/ogg/src/ogg-build/libogg.a"
VORBIS_LIBRARY="$MACOS_BUILD_DIR/engine/vorbis/src/vorbis-build/lib/libvorbis.a"
VORBISENC_LIBRARY="$MACOS_BUILD_DIR/engine/vorbis/src/vorbis-build/lib/libvorbisenc.a"

for library in "$OGG_LIBRARY" "$VORBIS_LIBRARY" "$VORBISENC_LIBRARY"; do
  [[ -f "$library" ]] || {
    print -u2 "Theora fallback dependency is missing: $library"
    print -u2 "Run ./scripts/build-macos.sh before building the fallback encoder."
    exit 1
  }
done

cmake --fresh -S "$ROOT_DIR/tools/wargus-theora" -B "$ENCODER_BUILD_DIR" \
  -DPEONPAD_ROOT="$ROOT_DIR" \
  -DOGG_LIBRARY="$OGG_LIBRARY" \
  -DVORBIS_LIBRARY="$VORBIS_LIBRARY" \
  -DVORBISENC_LIBRARY="$VORBISENC_LIBRARY" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0
cmake --build "$ENCODER_BUILD_DIR" --parallel

ENCODER="$ENCODER_BUILD_DIR/encoder_example"
[[ -x "$ENCODER" ]] || {
  print -u2 "Theora fallback encoder was not built: $ENCODER"
  exit 1
}
file "$ENCODER" | grep -q 'arm64' || {
  print -u2 "expected arm64 Theora fallback encoder: $ENCODER"
  exit 1
}

print "$ENCODER"
