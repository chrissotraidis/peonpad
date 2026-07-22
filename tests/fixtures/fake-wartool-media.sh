#!/bin/zsh

set -eu

OUTPUT_DIR=${PEONPAD_FAKE_WARTOOL_OUTPUT:?PEONPAD_FAKE_WARTOOL_OUTPUT is not set}
mkdir -p "$OUTPUT_DIR"
ffmpeg -y -i "$OUTPUT_DIR/intro.smk" -codec:v libtheora \
  -codec:a libvorbis "$OUTPUT_DIR/intro.ogv"
ffmpeg -y -i "$OUTPUT_DIR/music.wav" "$OUTPUT_DIR/music.ogg"
