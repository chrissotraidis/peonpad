#!/bin/zsh

set -eu

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
BUILD_DIR="$ROOT_DIR/build/tests/game-data-path"

cmake -E remove_directory "$BUILD_DIR"
cmake -E make_directory "$BUILD_DIR"
clang++ -std=c++17 -Wall -Wextra -Werror \
  -I "$ROOT_DIR/platform/apple/ios" \
  "$ROOT_DIR/tests/game_data_path_test.cpp" \
  "$ROOT_DIR/platform/apple/ios/PeonPadGameDataPath.cpp" \
  -o "$BUILD_DIR/game_data_path_test"
"$BUILD_DIR/game_data_path_test" "$BUILD_DIR/runtime"
print "iOS game-data path tests passed"
