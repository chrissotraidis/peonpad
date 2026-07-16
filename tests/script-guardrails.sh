#!/bin/zsh

set -eu

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
TEST_RUNTIME="$ROOT_DIR/build/test-runtime"
MODE=public

if (( $# > 1 )) || { (( $# == 1 )) && [[ "$1" != "--maintainer" ]]; }; then
  print -u2 "Usage: ./tests/script-guardrails.sh [--maintainer]"
  exit 2
fi
if (( $# == 1 )); then
  MODE=maintainer
fi

START_DIGEST=""
if [[ "$MODE" == maintainer ]]; then
  EXPECTED_DIGEST=$(awk -F ' *= *' \
    '$1 == "tree_sha256" {gsub(/"/, "", $2); print $2; exit}' \
    "$ROOT_DIR/config/inputs.lock")
  START_DIGEST=$($ROOT_DIR/scripts/reference-digest.sh)
  [[ "$START_DIGEST" == "$EXPECTED_DIGEST" ]] || {
    print -u2 "reference digest does not match the input lock"
    exit 1
  }

  if "$ROOT_DIR/scripts/audit-aleona-assets.sh" --strict >/dev/null 2>&1; then
    print -u2 "strict Aleona distribution audit unexpectedly passed"
    exit 1
  fi
  "$ROOT_DIR/scripts/audit-aleona-assets.sh" --local-test >/dev/null
fi

"$ROOT_DIR/scripts/prepare-ipad-build.sh" --help >/dev/null
if "$ROOT_DIR/scripts/prepare-ipad-build.sh" --installer missing.exe \
    --data missing-data >/dev/null 2>&1; then
  print -u2 "prepare script accepted multiple input modes"
  exit 1
fi

IOS_PLIST="$ROOT_DIR/platform/apple/ios/Info.plist.in"
plutil -lint "$IOS_PLIST" >/dev/null
[[ "$(plutil -extract UILaunchScreen.UIImageName raw "$IOS_PLIST")" == \
    "PeonPadLaunch" ]]
[[ "$(plutil -extract 'CFBundleIcons~ipad'.CFBundlePrimaryIcon.CFBundleIconFiles.0 raw \
    "$IOS_PLIST")" == "PeonPadIcon76" ]]

verify_png() {
  local file=$1 expected_width=$2 expected_height=$3
  local properties width height alpha
  properties=$(sips -g pixelWidth -g pixelHeight -g hasAlpha "$file")
  width=$(awk '$1 == "pixelWidth:" {print $2}' <<< "$properties")
  height=$(awk '$1 == "pixelHeight:" {print $2}' <<< "$properties")
  alpha=$(awk '$1 == "hasAlpha:" {print $2}' <<< "$properties")
  [[ "$width" == "$expected_width" && "$height" == "$expected_height" \
      && "$alpha" == "no" ]] || {
    print -u2 "invalid opaque iOS artwork: $file"
    exit 1
  }
}

verify_png "$ROOT_DIR/platform/apple/ios/PeonPadLaunch.png" 1024 1024
verify_png "$ROOT_DIR/platform/apple/ios/PeonPadIcon76.png" 76 76
verify_png "$ROOT_DIR/platform/apple/ios/PeonPadIcon76@2x.png" 152 152
verify_png "$ROOT_DIR/platform/apple/ios/PeonPadIcon83.5@2x.png" 167 167

RESOURCE_TEST_ROOT="$TEST_RUNTIME/xcode-resource-copy"
RESOURCE_DATA="$RESOURCE_TEST_ROOT/source-data"
RESOURCE_PRODUCTS="$RESOURCE_TEST_ROOT/products/Release-iphoneos"
cmake -E remove_directory "$RESOURCE_TEST_ROOT"
cmake -E make_directory "$RESOURCE_DATA/scripts"
cmake -E touch "$RESOURCE_DATA/scripts/stratagus.lua"
TARGET_BUILD_DIR="$RESOURCE_PRODUCTS" WRAPPER_NAME="PeonPad.app" \
  "$ROOT_DIR/platform/apple/ios/copy-xcode-bundle-resources.sh" \
  "$(command -v cmake)" "$RESOURCE_DATA" \
  "$ROOT_DIR/platform/apple/ios/PeonPadLaunch.png" \
  "$ROOT_DIR/platform/apple/ios"
RESOURCE_APP="$RESOURCE_PRODUCTS/PeonPad.app"
[[ -f "$RESOURCE_APP/Aleona/scripts/stratagus.lua" ]]
cmp -s "$ROOT_DIR/platform/apple/ios/PeonPadLaunch.png" \
  "$RESOURCE_APP/PeonPadLaunch.png"
cmp -s "$ROOT_DIR/platform/apple/ios/PeonPadIcon83.5@2x.png" \
  "$RESOURCE_APP/PeonPadIcon83.5@2x.png"
cmake -E remove_directory "$RESOURCE_TEST_ROOT"

if [[ "$MODE" == maintainer ]]; then
  if "$ROOT_DIR/scripts/run-macos.sh" \
      --binary "$ROOT_DIR/ref/Wargus.app/Contents/MacOS/stratagus" \
      --profile wc2 -- -h >/dev/null 2>&1; then
    print -u2 "runtime wrapper accepted a forbidden reference executable"
    exit 1
  fi
fi

FAKE_DATA="$TEST_RUNTIME/fake-data.Wargus"
cmake -E make_directory "$FAKE_DATA"
PEONPAD_RUNTIME_ROOT="$TEST_RUNTIME" \
  "$ROOT_DIR/scripts/run-macos.sh" \
    --binary "$ROOT_DIR/tests/fixtures/fake-stratagus.sh" \
    --profile wc2 --data "$FAKE_DATA" -- -W >/dev/null

OBSERVATION="$TEST_RUNTIME/wc2/user/fake-engine-observation.txt"
[[ -f "$OBSERVATION" ]] || {
  print -u2 "fake engine did not write to the isolated user path"
  exit 1
}

rg -q "^data=$FAKE_DATA$" "$OBSERVATION"
rg -q "^user=$TEST_RUNTIME/wc2/user$" "$OBSERVATION"
rg -q "^home=$TEST_RUNTIME/wc2/home$" "$OBSERVATION"
rg -q "^cache=$TEST_RUNTIME/wc2/cache$" "$OBSERVATION"
rg -q "^tmp=$TEST_RUNTIME/wc2/tmp$" "$OBSERVATION"

PATCH_CHAIN_ROOT="$TEST_RUNTIME/patch-chain"
PATCH_CHAIN_ENGINE="$PATCH_CHAIN_ROOT/stratagus"
cmake -E remove_directory "$PATCH_CHAIN_ROOT"
cmake -E make_directory "$PATCH_CHAIN_ROOT"
cp -cR "$ROOT_DIR/engine/stratagus" "$PATCH_CHAIN_ENGINE"

# The patches form an ordered series, so validate composition by reversing the
# complete staged series and then applying it again in the stage-script order.
for patch_file in \
  0008-ios-control-groups.patch \
  0007-build-host-toluapp.patch \
  0006-ios-launch-image-resource.patch \
  0005-ios-metal-safe-area-viewport.patch \
  0004-ios-xcode-external-generator.patch \
  0003-ios-arm64-static-dependencies.patch \
  0002-route-relative-editor-maps-to-user.patch \
  0001-xcode-26-apple-vendored-deps.patch; do
  patch --no-backup-if-mismatch -R -s -d "$PATCH_CHAIN_ENGINE" -p1 \
    < "$ROOT_DIR/patches/stratagus/$patch_file"
done
for patch_file in \
  0001-xcode-26-apple-vendored-deps.patch \
  0002-route-relative-editor-maps-to-user.patch \
  0003-ios-arm64-static-dependencies.patch \
  0004-ios-xcode-external-generator.patch \
  0005-ios-metal-safe-area-viewport.patch \
  0006-ios-launch-image-resource.patch; do
  patch --no-backup-if-mismatch -s -d "$PATCH_CHAIN_ENGINE" -p1 \
    < "$ROOT_DIR/patches/stratagus/$patch_file"
done
patch --no-backup-if-mismatch -s -d "$PATCH_CHAIN_ENGINE" -p1 \
  < "$ROOT_DIR/patches/stratagus/0007-build-host-toluapp.patch"
patch --no-backup-if-mismatch -s -d "$PATCH_CHAIN_ENGINE" -p1 \
  < "$ROOT_DIR/patches/stratagus/0008-ios-control-groups.patch"
diff --no-dereference -qr \
  "$ROOT_DIR/engine/stratagus" "$PATCH_CHAIN_ENGINE" >/dev/null
cmake -E remove_directory "$PATCH_CHAIN_ROOT"
if [[ "$MODE" == maintainer ]]; then
  patch --dry-run -s -d "$ROOT_DIR/ref/wargus" -p1 \
    < "$ROOT_DIR/patches/wargus/0001-xcode-26-apple-vendored-deps.patch"
  patch --dry-run -s -d "$ROOT_DIR/ref/wargus" -p1 \
    < "$ROOT_DIR/patches/wargus/0002-ios-data-layer-library.patch"

  END_DIGEST=$($ROOT_DIR/scripts/reference-digest.sh)
  [[ "$END_DIGEST" == "$START_DIGEST" ]] || {
    print -u2 "reference material changed during script guardrail tests"
    exit 1
  }
fi

print "script guardrails passed"
