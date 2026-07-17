#!/bin/zsh

set -eu

input=${@[-1]}
if [[ "${PEONPAD_FAKE_FFPROBE_MODE:-valid}" == invalid && \
    "${input:t}" == logo.ogv ]]; then
  exit 1
fi

if [[ " $* " == *' format=format_name '* ]]; then
  print ogg
elif [[ " $* " == *' format=duration '* ]]; then
  print 1.0
elif [[ " $* " == *' stream=codec_name,codec_type '* ]]; then
  if [[ "${input:l}" == *.ogv ]]; then
    print 'theora,video'
    print 'vorbis,audio'
  else
    print 'flac,audio'
  fi
else
  exit 2
fi
