#!/bin/zsh
# Fetch SDL 2.32.10 plus the Pad ports UIKit scene startup commit and print its
# path. iOS builds use it instead of the vendored SDL 2.0.22: apps built with
# the iOS 27 SDK must start through UIKit scenes or iOS 27 closes them at launch.
set -eu

ROOT_DIR=${0:A:h:h}
SDL_DIR="$ROOT_DIR/build/deps/sdl2-scenes"
SDL_PIN=$(awk -F ' *= *' '/^\[dependencies.sdl2_ios\]/{s=1;next} /^\[/{s=0} s && $1 == "revision" {gsub(/"/, "", $2); print $2; exit}' "$ROOT_DIR/config/inputs.lock")

if [[ "$(git -C "$SDL_DIR" rev-parse HEAD 2>/dev/null || true)" != "$SDL_PIN" ]]; then
  rm -rf "$SDL_DIR"
  git init -q "$SDL_DIR"
  git -C "$SDL_DIR" fetch -q --depth 1 https://github.com/chrissotraidis/SDL.git "$SDL_PIN"
  git -C "$SDL_DIR" checkout -q --detach FETCH_HEAD
fi
print -r -- "$SDL_DIR"
