#!/bin/zsh

set -eu

output=""
while (( $# > 0 )); do
  if [[ "$1" == -o ]]; then
    output=$2
    shift 2
  else
    shift
  fi
done

[[ -n "$output" ]] || exit 2
[[ -n "${PEONPAD_FAKE_THEORA_LOG:-}" ]] && print -r -- "$output" >> "$PEONPAD_FAKE_THEORA_LOG"
mkdir -p "${output:h}"
print 'fake theora media' > "$output"
