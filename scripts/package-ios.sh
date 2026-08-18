#!/bin/zsh

set -eu
setopt PIPE_FAIL

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
APP=${1:-$ROOT_DIR/build/ios-release-xcode/Release-iphoneos/PeonPad.app}
APP=${APP:A}
RELEASE_NAME=${PEONPAD_RELEASE_NAME:-0.1.0-preview.1}
OUTPUT=${2:-$ROOT_DIR/artifacts/PeonPad-$RELEASE_NAME-unsigned.ipa}
OUTPUT=${OUTPUT:A}

"$SCRIPT_DIR/audit-ios-app.sh" "$APP"

PACKAGE_ROOT=$(mktemp -d /tmp/peonpad-package.XXXXXX)
cleanup() {
  rm -rf "$PACKAGE_ROOT"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$PACKAGE_ROOT/Payload"
ditto "$APP" "$PACKAGE_ROOT/Payload/PeonPad.app"
find "$PACKAGE_ROOT/Payload" -exec touch -h -t 202001010000 {} +

ARCHIVE="$PACKAGE_ROOT/PeonPad-unsigned.ipa"
(
  cd "$PACKAGE_ROOT"
  export COPYFILE_DISABLE=1
  find Payload -print | LC_ALL=C sort | zip -X -q "$ARCHIVE" -@
)

unzip -tq "$ARCHIVE" >/dev/null
ENTRIES=$(unzip -Z1 "$ARCHIVE")
grep -Fxq 'Payload/PeonPad.app/PeonPad' <<< "$ENTRIES" || {
  print -u2 "IPA payload executable is missing"
  exit 1
}
if grep -Eiq '(^|/)(Aleona|data\.Wargus|campaigns|graphics|maps|sounds|videos)(/|$)|\.(mpq|pud|sav|save|p12|mobileprovision|provisionprofile|cer|pem)$' \
    <<< "$ENTRIES"; then
  print -u2 "IPA contains prohibited game, signing, or private data"
  exit 1
fi
unzip -p "$ARCHIVE" Payload/PeonPad.app/LICENSE | cmp -s "$ROOT_DIR/LICENSE" -
unzip -p "$ARCHIVE" Payload/PeonPad.app/NOTICE | cmp -s "$ROOT_DIR/NOTICE" -
unzip -p "$ARCHIVE" Payload/PeonPad.app/THIRD_PARTY_NOTICES.md | \
  cmp -s "$ROOT_DIR/THIRD_PARTY_NOTICES.md" -

mkdir -p "${OUTPUT:h}"
mv -f "$ARCHIVE" "$OUTPUT"
HASH=$(shasum -a 256 "$OUTPUT" | awk '{print $1}')
print "$HASH  ${OUTPUT:t}" > "$OUTPUT.sha256"
print "Packaged audited unsigned PeonPad IPA: $OUTPUT"
print "SHA-256: $HASH"
print "This IPA contains no game data and must be signed before installation."
