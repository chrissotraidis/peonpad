#!/bin/zsh

set -eu
setopt PIPE_FAIL

SCRIPT_DIR=${0:A:h}
ROOT_DIR=${SCRIPT_DIR:h}
LOCK_FILE="$ROOT_DIR/config/inputs.lock"
MODE=""
INPUT_PATH=""
TEMP_ROOT=""

usage() {
  cat <<'EOF'
Usage:
  ./scripts/prepare-ipad-build.sh --installer /path/to/setup.exe
  ./scripts/prepare-ipad-build.sh --data /path/to/data.Wargus

Builds PeonPad's host tools, prepares user-owned Warcraft II data, stages the
iPad payload, and generates the native Xcode project. Exactly one input mode is
required. The source game data and generated build directories remain ignored.
EOF
}

fail() {
  print -u2 "$1"
  exit 1
}

manifest_value() {
  local section=$1 key=$2
  awk -F ' *= *' -v wanted_section="[$section]" -v wanted_key="$key" '
    $0 == wanted_section {in_section = 1; next}
    /^\[/ {in_section = 0}
    in_section && $1 == wanted_key {
      gsub(/"/, "", $2)
      print $2
      exit
    }
  ' "$LOCK_FILE"
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

validate_data() {
  local data_dir=$1 required
  for required in scripts/stratagus.lua extracted; do
    [[ -s "$data_dir/$required" ]] || {
      print -u2 "invalid data.Wargus; missing or empty $required: $data_dir"
      return 1
    }
  done
  for required in graphics maps sounds; do
    [[ -d "$data_dir/$required" ]] || {
      print -u2 "invalid data.Wargus; missing directory $required: $data_dir"
      return 1
    }
  done
}

cleanup() {
  if [[ -n "$TEMP_ROOT" && -d "$TEMP_ROOT" ]]; then
    cmake -E remove_directory "$TEMP_ROOT"
  fi
}
trap cleanup EXIT

while (( $# > 0 )); do
  case "$1" in
    --installer|--data)
      (( $# >= 2 )) || { print -u2 "$1 requires a path"; usage >&2; exit 2; }
      [[ -z "$MODE" ]] || { print -u2 "choose exactly one input mode"; usage >&2; exit 2; }
      MODE=${1#--}
      INPUT_PATH=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      print -u2 "unexpected argument: $1"
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "$MODE" ]] || { usage >&2; exit 2; }
INPUT_PATH=${INPUT_PATH:A}

if [[ "$MODE" == data ]]; then
  [[ -d "$INPUT_PATH" ]] || fail "data.Wargus directory is missing: $INPUT_PATH"
  validate_data "$INPUT_PATH" || exit 1
else
  [[ -f "$INPUT_PATH" ]] || fail "Warcraft II installer is missing: $INPUT_PATH"

  EXPECTED_EXE_NAME=$(manifest_value reference.wc2_installer exe_name)
  EXPECTED_BIN_NAME=$(manifest_value reference.wc2_installer bin_name)
  EXPECTED_EXE_HASH=$(manifest_value reference.wc2_installer exe_sha256)
  EXPECTED_BIN_HASH=$(manifest_value reference.wc2_installer bin_sha256)
  INSTALLER_DIR=${INPUT_PATH:h}
  BIN_PATH="$INSTALLER_DIR/$EXPECTED_BIN_NAME"

  [[ ${INPUT_PATH:t} == "$EXPECTED_EXE_NAME" ]] || \
    fail "unsupported installer filename; expected $EXPECTED_EXE_NAME"
  [[ -f "$BIN_PATH" ]] || \
    fail "matching installer data file is missing: $BIN_PATH"
  [[ "$(sha256_file "$INPUT_PATH")" == "$EXPECTED_EXE_HASH" ]] || \
    fail "installer hash does not match the validated English Warcraft II 2.02 release"
  [[ "$(sha256_file "$BIN_PATH")" == "$EXPECTED_BIN_HASH" ]] || \
    fail "installer .bin hash does not match the validated English Warcraft II 2.02 release"

  missing_dependencies=()
  for dependency in innoextract ffmpeg; do
    command -v "$dependency" >/dev/null 2>&1 || missing_dependencies+=("$dependency")
  done
  if (( ${#missing_dependencies} > 0 )); then
    print -u2 "missing extraction dependencies: ${missing_dependencies[*]}"
    print -u2 "install them with: brew install ${missing_dependencies[*]}"
    exit 1
  fi
fi

"$SCRIPT_DIR/preflight.sh"
"$SCRIPT_DIR/build-macos.sh"

if [[ "$MODE" == installer ]]; then
  DATA_DIR="$ROOT_DIR/data.Wargus"
  if [[ -e "$DATA_DIR" ]]; then
    [[ -d "$DATA_DIR" ]] || fail "data.Wargus exists but is not a directory: $DATA_DIR"
    validate_data "$DATA_DIR" || \
      fail "refusing to overwrite incomplete data.Wargus; move or remove it first"
    "$SCRIPT_DIR/validate-wartool-media.sh" "$DATA_DIR" || \
      fail "existing data.Wargus has incomplete media; move or remove it and run again"
    print "Using existing validated data.Wargus: $DATA_DIR"
  else
    mkdir -p "$ROOT_DIR/build"
    TEMP_ROOT=$(mktemp -d "$ROOT_DIR/build/wc2-extract.XXXXXX")
    ARCHIVE_DIR="$TEMP_ROOT/installer"
    TEMP_DATA="$TEMP_ROOT/data.Wargus"
    mkdir -p "$ARCHIVE_DIR" "$TEMP_DATA"

    print "Extracting the validated Warcraft II installer..."
    innoextract "$INPUT_PATH" -d "$ARCHIVE_DIR"
    [[ -d "$ARCHIVE_DIR/Support" && -f "$ARCHIVE_DIR/Install.mpq" ]] || \
      fail "innoextract did not produce Support/ and Install.mpq"

    for resource in campaigns contrib maps shaders scripts; do
      [[ -d "$ROOT_DIR/game/wargus/$resource" ]] || \
        fail "tracked Wargus resource is missing: game/wargus/$resource"
      rsync -a "$ROOT_DIR/game/wargus/$resource" "$TEMP_DATA/"
    done

    print "Converting Warcraft II data with PeonPad's wartool..."
    "$SCRIPT_DIR/run-wartool-with-ffmpeg.sh" \
      "$ROOT_DIR/build/macos/wargus/wartool" -v -r "$ARCHIVE_DIR" "$TEMP_DATA"
    validate_data "$TEMP_DATA" || fail "wartool did not produce a complete data.Wargus"
    "$SCRIPT_DIR/validate-wartool-media.sh" "$TEMP_DATA" || \
      fail "wartool did not convert all cinematics and music"
    mv "$TEMP_DATA" "$DATA_DIR"
    print "Created ignored game-data directory: $DATA_DIR"
  fi
  INPUT_PATH="$DATA_DIR"
fi

PEONPAD_WC2_DATA_DIR="$INPUT_PATH" "$SCRIPT_DIR/stage-ios-wc2-test-data.sh"
"$SCRIPT_DIR/generate-ios-xcode.sh"

print
print "PeonPad is ready for Xcode:"
print "  project: build/ios-xcode/stratagus.xcodeproj"
print "  data:    build/ios-wc2-data"
print "Open the project, select your Personal Team and connected iPad, then press Run."
