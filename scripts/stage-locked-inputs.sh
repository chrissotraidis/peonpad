#!/bin/zsh

set -eu

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
INPUT_LOCK="$ROOT_DIR/config/inputs.lock"

usage() {
  cat <<'EOF'
Usage: ./scripts/stage-locked-inputs.sh

Exports clean, revision-locked source snapshots from ref/ into the PeonPad
project tree. It reads reference repositories only; it never modifies them.

Expected inputs (overridable with environment variables):
  PEONPAD_REF_STRATAGUS  ref/stratagus
  PEONPAD_REF_WARGUS     ref/wargus
  PEONPAD_REF_ALEONA     ref/aleonas-tales

Destinations:
  engine/stratagus
  game/wargus
  assets/aleonas-tales/source
EOF
}

if (( $# > 0 )); then
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
  fi
  print -u2 "unexpected argument: $1"
  usage >&2
  exit 2
fi

manifest_value() {
  local section=$1
  local key=$2
  awk -F ' *= *' -v wanted_section="[$section]" -v wanted_key="$key" '
    $0 == wanted_section {in_section = 1; next}
    /^\[/ {in_section = 0}
    in_section && $1 == wanted_key {
      gsub(/"/, "", $2)
      print $2
      exit
    }
  ' "$INPUT_LOCK"
}

verify_exportable_repository() {
  local label=$1
  local section=$2
  local source=$3

  [[ -d "$source" ]] || {
    print -u2 "$label is missing: ${source#$ROOT_DIR/}"
    return 1
  }

  local expected_revision
  expected_revision=$(manifest_value "$section" revision)
  [[ -n "$expected_revision" && "$expected_revision" != "MISSING" ]] || {
    print -u2 "$label revision is not locked in config/inputs.lock"
    return 1
  }

  local license
  license=$(manifest_value "$section" license)
  [[ -n "$license" && "$license" != "MISSING" ]] || {
    print -u2 "$label license is not recorded in config/inputs.lock"
    return 1
  }

  local actual_revision
  actual_revision=$(GIT_OPTIONAL_LOCKS=0 git -C "$source" \
    rev-parse HEAD 2>/dev/null) || {
    print -u2 "$label is not an inspectable Git repository"
    return 1
  }

  [[ "$actual_revision" == "$expected_revision" ]] || {
    print -u2 "$label revision mismatch: expected $expected_revision, got $actual_revision"
    return 1
  }

  [[ -z "$(GIT_OPTIONAL_LOCKS=0 git -C "$source" \
    status --porcelain --ignore-submodules=none)" ]] || {
    print -u2 "$label reference worktree or one of its submodules is dirty"
    return 1
  }

  local submodule_status
  submodule_status=$(GIT_OPTIONAL_LOCKS=0 git -C "$source" \
    submodule status --recursive 2>/dev/null || true)
  if [[ -n "$submodule_status" ]] && \
      print -r -- "$submodule_status" | grep -q '^[+-U]'; then
    print -u2 "$label has an uninitialized or mismatched submodule"
    return 1
  fi

  local forbidden
  forbidden=$(find "$source" \
    -type d -name .git -prune -o \
    \( -type d -name data.Wargus -o \
       -type f -iname '*.mpq' -o \
       -type f -name 'setup_warcraft_ii_*' \) \
    -print -quit)
  [[ -z "$forbidden" ]] || {
    print -u2 "$label contains forbidden proprietary input: $forbidden"
    return 1
  }
}

export_repository() {
  local label=$1
  local section=$2
  local source=$3
  local destination=$4

  [[ ! -e "$destination" ]] || {
    print -u2 "destination already exists; refusing to overwrite: ${destination#$ROOT_DIR/}"
    return 1
  }

  verify_exportable_repository "$label" "$section" "$source"

  local revision
  revision=$(manifest_value "$section" revision)
  mkdir -p "$destination"
  git -C "$source" archive --format=tar "$revision" \
    | tar -xf - -C "$destination"

  if [[ -f "$source/.gitmodules" ]]; then
    local key submodule_path submodule_revision actual_submodule_revision
    while read -r key submodule_path; do
      submodule_revision=$(GIT_OPTIONAL_LOCKS=0 git -C "$source" \
        ls-tree "$revision" -- "$submodule_path" | awk '{print $3}')
      actual_submodule_revision=$(GIT_OPTIONAL_LOCKS=0 \
        git -C "$source/$submodule_path" rev-parse HEAD)
      [[ "$actual_submodule_revision" == "$submodule_revision" ]] || {
        print -u2 "$label submodule mismatch at $submodule_path"
        return 1
      }
      mkdir -p "$destination/$submodule_path"
      git -C "$source/$submodule_path" archive --format=tar \
        "$submodule_revision" | tar -xf - -C "$destination/$submodule_path"
      printf '%s\n' "$submodule_revision" \
        > "$destination/$submodule_path/.peonpad-source-revision"
    done < <(git -C "$source" config --file .gitmodules \
      --get-regexp '^submodule\..*\.path$')
  fi
  printf '%s\n' "$revision" > "$destination/.peonpad-source-revision"
  print "STAGED $label -> ${destination#$ROOT_DIR/} ($revision)"
}

STRATAGUS_SOURCE=${PEONPAD_REF_STRATAGUS:-$ROOT_DIR/ref/stratagus}
WARGUS_SOURCE=${PEONPAD_REF_WARGUS:-$ROOT_DIR/ref/wargus}
ALEONA_SOURCE=${PEONPAD_REF_ALEONA:-$ROOT_DIR/ref/aleonas-tales}
STRATAGUS_PATCH="$ROOT_DIR/patches/stratagus/0001-xcode-26-apple-vendored-deps.patch"
STRATAGUS_WRITABLE_MAP_PATCH="$ROOT_DIR/patches/stratagus/0002-route-relative-editor-maps-to-user.patch"
STRATAGUS_IOS_PATCH="$ROOT_DIR/patches/stratagus/0003-ios-arm64-static-dependencies.patch"
STRATAGUS_IOS_XCODE_PATCH="$ROOT_DIR/patches/stratagus/0004-ios-xcode-external-generator.patch"
STRATAGUS_IOS_VIEWPORT_PATCH="$ROOT_DIR/patches/stratagus/0005-ios-metal-safe-area-viewport.patch"
STRATAGUS_IOS_LAUNCH_PATCH="$ROOT_DIR/patches/stratagus/0006-ios-launch-image-resource.patch"
WARGUS_PATCH="$ROOT_DIR/patches/wargus/0001-xcode-26-apple-vendored-deps.patch"
WARGUS_IOS_PATCH="$ROOT_DIR/patches/wargus/0002-ios-data-layer-library.patch"
ALEONA_KOTH_PATCH="$ROOT_DIR/patches/aleonas-tales/0001-fix-king-of-the-hill-map-syntax.patch"
ALEONA_TEST_MENU_PATCH="$ROOT_DIR/patches/aleonas-tales/0002-limit-device-test-modes.patch"

# Verify every input before creating any destination.
verify_exportable_repository "Stratagus" "sources.stratagus" "$STRATAGUS_SOURCE"
verify_exportable_repository "Wargus" "sources.wargus" "$WARGUS_SOURCE"
verify_exportable_repository "Aleona's Tales" "assets.aleonas_tales" "$ALEONA_SOURCE"

[[ ! -e "$ROOT_DIR/engine/stratagus" ]] || {
  print -u2 "destination already exists: engine/stratagus"
  exit 1
}
[[ ! -e "$ROOT_DIR/game/wargus" ]] || {
  print -u2 "destination already exists: game/wargus"
  exit 1
}
[[ ! -e "$ROOT_DIR/assets/aleonas-tales/source" ]] || {
  print -u2 "destination already exists: assets/aleonas-tales/source"
  exit 1
}

export_repository "Stratagus" "sources.stratagus" \
  "$STRATAGUS_SOURCE" "$ROOT_DIR/engine/stratagus"
[[ -f "$STRATAGUS_PATCH" ]] || {
  print -u2 "required Stratagus compatibility patch is missing"
  exit 1
}
patch -s -d "$ROOT_DIR/engine/stratagus" -p1 < "$STRATAGUS_PATCH"
print "PATCHED Stratagus for the Xcode 26 SDL/HIDAPI diagnostic"
[[ -f "$STRATAGUS_WRITABLE_MAP_PATCH" ]] || {
  print -u2 "required Stratagus writable-map patch is missing"
  exit 1
}
patch -s -d "$ROOT_DIR/engine/stratagus" -p1 \
  < "$STRATAGUS_WRITABLE_MAP_PATCH"
print "PATCHED Stratagus to keep generated maps in the user directory"
[[ -f "$STRATAGUS_IOS_PATCH" ]] || {
  print -u2 "required Stratagus iOS dependency patch is missing"
  exit 1
}
patch -s -d "$ROOT_DIR/engine/stratagus" -p1 < "$STRATAGUS_IOS_PATCH"
print "PATCHED Stratagus dependencies for iOS static-library builds"
[[ -f "$STRATAGUS_IOS_XCODE_PATCH" ]] || {
  print -u2 "required Stratagus iOS Xcode patch is missing"
  exit 1
}
patch -s -d "$ROOT_DIR/engine/stratagus" -p1 < "$STRATAGUS_IOS_XCODE_PATCH"
print "PATCHED Stratagus vendored dependencies for native Xcode app builds"
[[ -f "$STRATAGUS_IOS_VIEWPORT_PATCH" ]] || {
  print -u2 "required Stratagus iOS viewport patch is missing"
  exit 1
}
patch -s -d "$ROOT_DIR/engine/stratagus" -p1 \
  < "$STRATAGUS_IOS_VIEWPORT_PATCH"
print "PATCHED Stratagus with the PeonPad Metal and safe-area viewport integration"
[[ -f "$STRATAGUS_IOS_LAUNCH_PATCH" ]] || {
  print -u2 "required Stratagus iOS launch-image patch is missing"
  exit 1
}
patch -s -d "$ROOT_DIR/engine/stratagus" -p1 \
  < "$STRATAGUS_IOS_LAUNCH_PATCH"
print "PATCHED Stratagus to bundle the PeonPad launch image"
export_repository "Wargus" "sources.wargus" \
  "$WARGUS_SOURCE" "$ROOT_DIR/game/wargus"
[[ -f "$WARGUS_PATCH" ]] || {
  print -u2 "required Wargus compatibility patch is missing"
  exit 1
}
patch -s -d "$ROOT_DIR/game/wargus" -p1 < "$WARGUS_PATCH"
print "PATCHED Wargus for Xcode 26 and Apple vendored dependencies"
[[ -f "$WARGUS_IOS_PATCH" ]] || {
  print -u2 "required Wargus iOS data-layer patch is missing"
  exit 1
}
patch -s -d "$ROOT_DIR/game/wargus" -p1 < "$WARGUS_IOS_PATCH"
print "PATCHED Wargus with the PeonPad iOS data-layer library target"
export_repository "Aleona's Tales" "assets.aleonas_tales" \
  "$ALEONA_SOURCE" "$ROOT_DIR/assets/aleonas-tales/source"
[[ -f "$ALEONA_KOTH_PATCH" ]] || {
  print -u2 "required Aleona King of the Hill patch is missing"
  exit 1
}
patch -s -d "$ROOT_DIR/assets/aleonas-tales/source" -p1 \
  < "$ALEONA_KOTH_PATCH"
print "PATCHED Aleona's Tales King of the Hill map syntax"
[[ -f "$ALEONA_TEST_MENU_PATCH" ]] || {
  print -u2 "required Aleona device-test menu patch is missing"
  exit 1
}
patch -s -d "$ROOT_DIR/assets/aleonas-tales/source" -p1 \
  < "$ALEONA_TEST_MENU_PATCH"
print "PATCHED Aleona's Tales device-test mode menu"

print "All locked inputs staged without modifying ref/."
