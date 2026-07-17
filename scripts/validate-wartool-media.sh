#!/bin/zsh

set -eu

if (( $# != 1 )); then
  print -u2 "Usage: ./scripts/validate-wartool-media.sh /path/to/data.Wargus"
  exit 2
fi

DATA_DIR=${1:A}
CONFIG="$DATA_DIR/scripts/wc2-config.lua"

[[ -f "$CONFIG" ]] || {
  print -u2 "wartool media validation failed; missing scripts/wc2-config.lua"
  exit 1
}
grep -Fq 'wargus.music_extension = ".ogg"' "$CONFIG" || {
  print -u2 "wartool media validation failed; music was not configured for Ogg"
  exit 1
}

videos=(
  exp-1 gameintro human-1 human-2 human-3 human-4 human-exp-2 logo
  orc-1 orc-2 orc-3 orc-4 orc-exp-2
)
music=(
  'Human Battle 1' 'Human Battle 2' 'Human Battle 3' 'Human Battle 4'
  'Human Battle 5' 'Human Battle 6' 'Human Briefing' 'Human Defeat'
  'Human Victory' "I'm a Medieval Man" 'Orc Battle 1' 'Orc Battle 2'
  'Orc Battle 3' 'Orc Battle 4' 'Orc Battle 5' 'Orc Battle 6'
  'Orc Briefing' 'Orc Defeat' 'Orc Victory'
)

missing=()
invalid=()
FFPROBE=$(command -v ffprobe || true)
if [[ -z "$FFPROBE" ]]; then
  print -u2 "warning: ffprobe is unavailable; checking media presence only"
  print -u2 "ffprobe is included with the supported Homebrew ffmpeg package"
fi

probe_media() {
  local media_file=$1 kind=$2 format duration streams

  format=$("$FFPROBE" -v error -show_entries format=format_name \
    -of default=noprint_wrappers=1:nokey=1 "$media_file") || return 1
  [[ "$format" == ogg ]] || return 1

  duration=$("$FFPROBE" -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$media_file") || return 1
  awk -v duration="$duration" 'BEGIN { exit !(duration + 0 > 0) }' || return 1

  streams=$("$FFPROBE" -v error -show_entries stream=codec_name,codec_type \
    -of csv=p=0 "$media_file") || return 1
  if [[ "$kind" == video ]]; then
    grep -Fxq 'theora,video' <<< "$streams" || return 1
    grep -Fxq 'vorbis,audio' <<< "$streams" || return 1
  else
    grep -Eq '^[^,]+,audio$' <<< "$streams" || return 1
  fi
}

for name in $videos; do
  relative_media="videos/$name.ogv"
  if [[ ! -s "$DATA_DIR/$relative_media" ]]; then
    missing+=("$relative_media")
  elif [[ -n "$FFPROBE" ]] && ! probe_media "$DATA_DIR/$relative_media" video; then
    invalid+=("$relative_media")
  fi
done
for name in $music; do
  relative_media="music/$name.ogg"
  if [[ ! -s "$DATA_DIR/$relative_media" ]]; then
    missing+=("$relative_media")
  elif [[ -n "$FFPROBE" ]] && ! probe_media "$DATA_DIR/$relative_media" audio; then
    invalid+=("$relative_media")
  fi
done

if (( ${#missing} > 0 )); then
  print -u2 "wartool media validation failed; missing or empty converted files:"
  for relative_media in $missing; do
    print -u2 "  $relative_media"
  done
  exit 1
fi
if (( ${#invalid} > 0 )); then
  print -u2 "wartool media validation failed; unreadable or unexpected media:"
  for relative_media in $invalid; do
    print -u2 "  $relative_media"
  done
  exit 1
fi

print "Validated 13 Theora cinematics and 19 Ogg music tracks."
