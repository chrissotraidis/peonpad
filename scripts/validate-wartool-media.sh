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
for name in $videos; do
  [[ -s "$DATA_DIR/videos/$name.ogv" ]] || missing+=("videos/$name.ogv")
done
for name in $music; do
  [[ -s "$DATA_DIR/music/$name.ogg" ]] || missing+=("music/$name.ogg")
done

if (( ${#missing} > 0 )); then
  print -u2 "wartool media validation failed; missing or empty converted files:"
  for path in $missing; do
    print -u2 "  $path"
  done
  exit 1
fi

print "Validated 13 Theora cinematics and 19 Ogg music tracks."
