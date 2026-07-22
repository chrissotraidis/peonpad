#!/bin/zsh

set -eu

if [[ " $* " == *' -encoders '* ]]; then
  print 'Encoders:'
  if [[ "${PEONPAD_FAKE_FFMPEG_MODE:-fallback}" == native ]]; then
    print ' V....D libtheora            libtheora Theora'
  fi
  exit 0
fi

[[ -n "${PEONPAD_FAKE_FFMPEG_LOG:-}" ]] && print -r -- "$*" >> "$PEONPAD_FAKE_FFMPEG_LOG"
output=${@[-1]}
mkdir -p "${output:h}"
print 'fake media' > "$output"
