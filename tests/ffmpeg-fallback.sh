#!/bin/zsh

set -eu

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
TEST_ROOT="$ROOT_DIR/build/test-runtime/ffmpeg-fallback"
FAKE_BIN="$TEST_ROOT/bin"
OUTPUT_DIR="$TEST_ROOT/output"
FFMPEG_LOG="$TEST_ROOT/ffmpeg.log"
THEORA_LOG="$TEST_ROOT/theora.log"

cmake -E remove_directory "$TEST_ROOT"
cmake -E make_directory "$FAKE_BIN" "$OUTPUT_DIR"
cmake -E create_symlink "$ROOT_DIR/tests/fixtures/fake-ffmpeg.sh" "$FAKE_BIN/ffmpeg"
cmake -E create_symlink "$ROOT_DIR/tests/fixtures/fake-ffprobe.sh" "$FAKE_BIN/ffprobe"

PEONPAD_FAKE_FFMPEG_MODE=native \
PEONPAD_FAKE_FFMPEG_LOG="$FFMPEG_LOG" \
PEONPAD_FAKE_WARTOOL_OUTPUT="$OUTPUT_DIR" \
PATH="$FAKE_BIN:$PATH" \
  "$ROOT_DIR/scripts/run-wartool-with-ffmpeg.sh" \
    "$ROOT_DIR/tests/fixtures/fake-wartool-media.sh" >/dev/null
[[ -s "$OUTPUT_DIR/intro.ogv" && -s "$OUTPUT_DIR/music.ogg" ]]
[[ ! -e "$THEORA_LOG" ]]

cmake -E remove_directory "$OUTPUT_DIR"
cmake -E make_directory "$OUTPUT_DIR"
: > "$FFMPEG_LOG"

PEONPAD_FAKE_FFMPEG_MODE=fallback \
PEONPAD_FAKE_FFMPEG_LOG="$FFMPEG_LOG" \
PEONPAD_FAKE_THEORA_LOG="$THEORA_LOG" \
PEONPAD_FAKE_WARTOOL_OUTPUT="$OUTPUT_DIR" \
PEONPAD_THEORA_ENCODER="$ROOT_DIR/tests/fixtures/fake-theora-encoder.sh" \
PATH="$FAKE_BIN:$PATH" \
  "$ROOT_DIR/scripts/run-wartool-with-ffmpeg.sh" \
    "$ROOT_DIR/tests/fixtures/fake-wartool-media.sh" >/dev/null

[[ -s "$OUTPUT_DIR/intro.ogv" && -s "$OUTPUT_DIR/music.ogg" ]]
[[ -s "$THEORA_LOG" ]]
grep -Fq 'video.y4m' "$FFMPEG_LOG"
grep -Fq 'audio.wav' "$FFMPEG_LOG"
grep -Fq "$OUTPUT_DIR/music.ogg" "$FFMPEG_LOG"

MEDIA_DIR="$TEST_ROOT/data.Wargus"
cmake -E make_directory "$MEDIA_DIR/scripts" "$MEDIA_DIR/videos" "$MEDIA_DIR/music"
print 'wargus.music_extension = ".ogg"' > "$MEDIA_DIR/scripts/wc2-config.lua"

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
for name in $videos; do
  print 'fake video' > "$MEDIA_DIR/videos/$name.ogv"
done
for name in $music; do
  print 'fake music' > "$MEDIA_DIR/music/$name.ogg"
done

PATH="$FAKE_BIN:$PATH" \
  "$ROOT_DIR/scripts/validate-wartool-media.sh" "$MEDIA_DIR" >/dev/null

if PEONPAD_FAKE_FFPROBE_MODE=invalid PATH="$FAKE_BIN:$PATH" \
    "$ROOT_DIR/scripts/validate-wartool-media.sh" "$MEDIA_DIR" >/dev/null 2>&1; then
  print -u2 "media validator accepted a malformed cinematic"
  exit 1
fi

warning=$(PATH=/usr/bin:/bin \
  "$ROOT_DIR/scripts/validate-wartool-media.sh" "$MEDIA_DIR" 2>&1 >/dev/null)
grep -Fq 'warning: ffprobe is unavailable; checking media presence only' <<< "$warning"

cmake -E remove -f "$MEDIA_DIR/videos/logo.ogv"
if PATH="$FAKE_BIN:$PATH" \
    "$ROOT_DIR/scripts/validate-wartool-media.sh" "$MEDIA_DIR" >/dev/null 2>&1; then
  print -u2 "media validator accepted a missing cinematic"
  exit 1
fi

cmake -E remove_directory "$TEST_ROOT"
print "FFmpeg fallback guardrails passed"
