#!/bin/zsh

set -eu
setopt PIPE_FAIL

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}

if (( $# == 0 )); then
  print -u2 "Usage: ./scripts/run-wartool-with-ffmpeg.sh /path/to/wartool [arguments...]"
  exit 2
fi

REAL_FFMPEG=$(command -v ffmpeg || true)
[[ -n "$REAL_FFMPEG" ]] || {
  print -u2 "missing extraction dependency: ffmpeg"
  print -u2 "install it with: brew install ffmpeg"
  exit 1
}

if "$REAL_FFMPEG" -hide_banner -encoders 2>/dev/null | \
    grep -Eq '(^|[[:space:]])libtheora([[:space:]]|$)'; then
  print "Using FFmpeg's libtheora encoder for Warcraft II cinematics."
  exec "$@"
fi

ENCODER=${PEONPAD_THEORA_ENCODER:-}
if [[ -z "$ENCODER" ]]; then
  MACOS_BUILD_DIR=${PEONPAD_MACOS_BUILD_DIR:-$ROOT_DIR/build/macos}
  ENCODER="${MACOS_BUILD_DIR:A}/theora-encoder/encoder_example"
  if [[ ! -x "$ENCODER" ]]; then
    "$SCRIPT_DIR/build-macos-theora-encoder.sh"
  fi
fi
[[ -x "$ENCODER" ]] || {
  print -u2 "Theora fallback encoder is missing or not executable: $ENCODER"
  exit 1
}

print "FFmpeg has no libtheora encoder; using PeonPad's bundled Theora fallback."
PATH="$ROOT_DIR/tools/wargus-theora:$PATH" \
  PEONPAD_REAL_FFMPEG="$REAL_FFMPEG" \
  PEONPAD_THEORA_ENCODER="$ENCODER" \
  "$@"
