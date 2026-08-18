# Phase 2 iPad app shell

PeonPad now has a separate unsigned, data-free distribution build:

```sh
./scripts/build-ios-release.sh
```

Output:

```text
build/ios-release-xcode/Release-iphoneos/PeonPad.app
```

The build is native iOS (`LC_BUILD_VERSION` platform 2), targets iPadOS 16.0,
and links the vendored SDL2 engine as a Metal-capable SDL application. The
bundle is landscape-only, enables indirect pointer input, and writes
preferences and saves through `SDL_GetPrefPath`. At launch it validates
`Documents/data.Wargus`; a bundled `Aleona` directory is accepted only in an
explicit local-data development build.

The system launch screen displays the original PeonPad tablet-and-banner mark,
and the bundle includes matching opaque 76-point, Retina 76-point, and
83.5-point Retina iPad icons. Their vector source is kept beside the generated
PNGs under `platform/apple/ios`; none is derived from game content.

The iOS engine now explicitly selects SDL's `metal` renderer. UIKit safe-area
insets are converted from points into Retina drawable pixels, and the 4:3 game
surface is aspect-fitted inside that safe rectangle. The same SDL viewport and
scale drive SDL's built-in pointer/touch event conversion, avoiding a second
coordinate transform. Insets are reapplied after UIKit size changes, and the
Home gesture uses SDL's two-swipe deferral mode.

The platform-independent viewport calculation is covered by:

```sh
./scripts/test-ios-viewport.sh
```

## Content boundary

The distribution audit fails if an MPQ, installer, `WAR2DAT.MPQ`,
`data.Wargus`, `Aleona`, signing material, a non-system dynamic dependency, or
a local build path appears in the application. It also requires the project
and third-party license notices, release identity, arm64/iOS 16 metadata, and
Files document-sharing keys.

The current Aleona snapshot remains approved only for local development
testing. Its aggregate repository is GPLv2, but the per-file art, audio, map,
and vendored Wyrmsun provenance audit remains
`REVIEW_REQUIRED_BEFORE_BUNDLING`. The distribution build solves that boundary
by omitting Aleona entirely; the findings remain recorded in
[aleona-asset-audit.md](aleona-asset-audit.md).

## Proven locally

- `PeonPad.app/PeonPad` is a Mach-O arm64 executable.
- Its load command records iOS platform 2, minimum 16.0, SDK 26.5.
- The generated Info.plist identifies an iPad application and enables
  `UIApplicationSupportsIndirectInputEvents`.
- The Info.plist declares a nonblank PeonPad launch image and matching iPad
icons, and the build verifies that every declared raster is in the bundle.
- Xcode resource copying uses `TARGET_BUILD_DIR` and `WRAPPER_NAME`, avoiding
  CMake's incorrectly escaped `${EFFECTIVE_PLATFORM_NAME}` post-build path.
- The distribution app contains no game-data directory. The explicit
  local-data mode can still embed ignored test data for private development.
- The final executable links successfully with SDL2, SDL2_image, SDL2_mixer,
  Lua, and the vendored media libraries.
- Both the Makefile device build and a clean native Xcode Release build contain
  the UIKit safe-area bridge and produce arm64 iOS 16.0 applications.
- SDL_mixer uses Timidity for MIDI on iOS. Its macOS native-MIDI backend is
  deliberately disabled because that implementation compiles empty under the
  iPhoneOS SDK and otherwise leaves unresolved symbols.

## Remaining Phase 2 acceptance

For a private development build that embeds owned Warcraft II data, generate
the native Xcode project used for automatic personal-team signing with:

```sh
./scripts/generate-ios-xcode.sh --local-data build/ios-wc2-data
open build/ios-xcode/stratagus.xcodeproj
```

In Xcode, select the `stratagus` target, open **Signing & Capabilities**, and
choose your Personal Team. Select the connected iPad as the run destination
and press Run. This uses only Xcode and the Apple account stored by Xcode; no
third-party credential tool is involved.

The generator requires either `--distribution` or `--local-data PATH`; it
never infers that release data may be bundled. It removes its script-owned
build tree first so stale
ExternalProject caches cannot retain an incompatible CMake generator. The
generated project has been proven through a complete unsigned Xcode Release
build. Its top-level PeonPad target is native Xcode while vendored
dependencies use their verified single-configuration CMake builds. A
connected, paired iPad and a signing team configured natively in Xcode are
still required to install it. Physical M2 iPad testing has since accepted
launch, menus, Warcraft II campaigns and skirmishes, Metal rendering, audio,
save/load, and the current touch controls; see `ipad-test-notes.md` for the
remaining regression matrix.
