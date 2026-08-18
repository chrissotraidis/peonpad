#!/bin/zsh

set -eu
setopt PIPE_FAIL

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
APP=${1:-$ROOT_DIR/build/ios-release-xcode/Release-iphoneos/PeonPad.app}
APP=${APP:A}
BINARY="$APP/PeonPad"

fail() {
  print -u2 "iOS app audit failed: $1"
  exit 1
}

[[ -d "$APP" && -x "$BINARY" ]] || fail "device app is missing: $APP"

BUILD_METADATA=$(xcrun vtool -show-build "$BINARY")
grep -Eq 'platform +IOS$' <<< "$BUILD_METADATA" || fail "binary is not iOS"
grep -Eq 'minos +16\.0$' <<< "$BUILD_METADATA" || fail "minimum iOS is not 16.0"
xcrun lipo -info "$BINARY" | grep -Eq 'architecture: arm64$' || \
  fail "binary is not arm64-only"

plutil -lint "$APP/Info.plist" >/dev/null || fail "Info.plist is invalid"
[[ "$(plutil -extract CFBundleIdentifier raw "$APP/Info.plist")" == \
    "org.peonpad.ios" ]] || fail "unexpected bundle identifier"
[[ "$(plutil -extract CFBundleShortVersionString raw "$APP/Info.plist")" == \
    "0.1.0" ]] || fail "unexpected bundle version"
[[ "$(plutil -extract CFBundleVersion raw "$APP/Info.plist")" == "4" ]] || \
  fail "unexpected bundle build"
for key in UIFileSharingEnabled LSSupportsOpeningDocumentsInPlace; do
  [[ "$(plutil -extract "$key" raw "$APP/Info.plist")" == "true" ]] || \
    fail "$key is not enabled"
done

for required in Info.plist PeonPad PeonPadLaunch.png PeonPadIcon76.png \
    PeonPadIcon76@2x.png PeonPadIcon83.5@2x.png LICENSE NOTICE \
    THIRD_PARTY_NOTICES.md; do
  [[ -f "$APP/$required" ]] || fail "required bundle file is missing: $required"
done
cmp -s "$ROOT_DIR/LICENSE" "$APP/LICENSE" || fail "bundled LICENSE differs"
cmp -s "$ROOT_DIR/NOTICE" "$APP/NOTICE" || fail "bundled NOTICE differs"
cmp -s "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$APP/THIRD_PARTY_NOTICES.md" || \
  fail "bundled third-party notice differs"

typeset -a license_files=(
  Stratagus-COPYING.txt Wargus-COPYING.txt Wargus-COPYING-3rd.txt
  SDL2-LICENSE.txt SDL2_image-LICENSE.txt SDL2_mixer-LICENSE.txt
  dr_libs-LICENSE.txt stb_vorbis-README.txt timidity-COPYING.txt
  Lua-COPYRIGHT.txt toluapp-COPYRIGHT.txt zlib-README.txt
  libpng-LICENSE.txt bzip2-LICENSE.txt libogg-COPYING.txt
  libvorbis-COPYING.txt libtheora-COPYING.txt jpeg-README.txt
  lcms-COPYING.txt libmng-LICENSE.txt guisan-COPYING.txt
  unsf-LICENSE.txt mdns-LICENSE.txt spiritless_po-LICENSE.txt
)
for license in $license_files; do
  [[ -s "$APP/Licenses/$license" ]] || fail "license is missing: $license"
done

while IFS= read -r top_level; do
  name=${top_level:t}
  case "$name" in
    PeonPad|Info.plist|PkgInfo|PeonPadLaunch.png|PeonPadIcon76.png|\
    PeonPadIcon76@2x.png|PeonPadIcon83.5@2x.png|LICENSE|NOTICE|\
    THIRD_PARTY_NOTICES.md|Licenses) ;;
    *) fail "unexpected top-level bundle entry: $name" ;;
  esac
done < <(find "$APP" -mindepth 1 -maxdepth 1 -print | LC_ALL=C sort)

FORBIDDEN=$(find "$APP" \
  \( -type d \( -iname Aleona -o -iname data.Wargus -o -iname campaigns \
      -o -iname graphics -o -iname maps -o -iname sounds -o -iname videos \) \
  -o -type f \( -iname '*.mpq' -o -iname '*.pud' -o -iname '*.sav' \
      -o -iname '*.save' -o -iname '*.p12' -o -iname '*.mobileprovision' \
      -o -iname '*.provisionprofile' -o -iname '*.cer' -o -iname '*.pem' \
      -o -iname 'extracted' -o -iname 'setup_warcraft_ii_*' \) \) \
  -print -quit)
[[ -z "$FORBIDDEN" ]] || fail "prohibited private/game data found: $FORBIDDEN"

[[ ! -d "$APP/_CodeSignature" && ! -f "$APP/embedded.mobileprovision" ]] || \
  fail "release app contains signing material"
if otool -l "$BINARY" | grep -q 'cmd LC_CODE_SIGNATURE'; then
  fail "release executable still contains a code signature"
fi

UNEXPECTED_RUNTIME=$(otool -L "$BINARY" | awk 'NR > 1 {print $1}' | \
  rg -v '^(/System/Library/|/usr/lib/)' || true)
[[ -z "$UNEXPECTED_RUNTIME" ]] || \
  fail "binary has an unbundled runtime dependency: $UNEXPECTED_RUNTIME"
if otool -l "$BINARY" | grep -q 'cmd LC_RPATH'; then
  fail "binary contains a runtime search path"
fi

LOCAL_PATH=$(strings -a "$BINARY" | \
  rg -m 1 '(/Users/|/private/tmp/|/var/folders/)' || true)
[[ -z "$LOCAL_PATH" ]] || fail "binary exposes a local build path: $LOCAL_PATH"

print "Data-free iOS app audit passed: $APP"
