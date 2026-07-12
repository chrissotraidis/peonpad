# PeonPad build status

Status captured: 2026-07-12

Remote-to-local handoff updated: 2026-07-11

Physical-device testing is now active. PeonPad has been signed with the local
Personal Team, installed over USB, launched, and used to start King of the
Hill, For the Motherland, and Skirmish Classic matches. The gameplay-only
three-finger camera pan is now working in device testing. Current findings,
content decisions, and the control design are recorded in
[ipad-test-notes.md](ipad-test-notes.md).

The private device profile now uses the existing extracted Warcraft II payload
from `ref/data.Wargus`, staged without its redundant installer MPQ. The engine
remains a native ARM64 iPadOS/Metal build; no Windows executable is run or
emulated. Proprietary data remains ignored and is not part of the repository.

The first delayed-touch recognizer was rejected during physical testing after
it swallowed taps in gameplay and in-game menus. The installed recovery build
restores SDL single-touch behavior while retaining gameplay-only multi-touch
commands and explicit selection-rectangle cancellation.

Device console capture identified the apparent Front Lines freeze as a content
termination: the legacy map references the undefined `unit-nomad` type and the
engine exits with code 1. Random Skirmish also reports an extended/base tileset
brush mismatch. The private Warcraft II device menu now exposes only Skirmish
Classic and Skirmish Modern under Standard Game; original campaigns remain
available separately.

Physical follow-up proved Beyond the Dark Portal Alliance Act I renders and
plays correctly, including touch and camera pan. Skirmish Modern also runs, but
its default map intentionally starts at the map edge with one peasant and can
initially resemble an empty scene. The incompatible custom-mode files are now
physically absent from the staged iPad payload rather than merely filtered by
the menu widget.

The current device control candidate uses one-finger selection with empty-map
deselection, a two-finger chord for right-click commands at the leftmost
finger's position, and three-finger drag for camera panning. Two-finger movement beyond
a small tolerance cancels the command, and adding the third finger cancels the
pending command before panning. The pan now has a 1.35 movement gain, and text
fields reactivate UIKit's software keyboard when tapped. SDL's separate
hardware keyboard, mouse, and trackpad paths remain enabled for Magic Keyboard
and external pointer testing.

Replay Game and Save Replay are hidden in the private iPad profile after device
testing found that both legacy and newly generated logs failed to play
reliably. The engine also retains a missing-map preflight so stale files cannot
reach the fatal map loader if replay UI is re-enabled later.

This is the handoff point for resuming the active PeonPad goal with a physical
M2 iPad Pro. It distinguishes completed engineering from acceptance work that
still requires the device or external licensing evidence.

## Remote Mac to local Mac handoff

Development through the first native iOS application was performed on the
remote Mac. The pushed GitHub revision is the authoritative portable project
state. The ignored `ref/`, `assets/aleonas-tales/source/`, `build/`, and
`runtime/` trees are intentionally not portable through Git and must not be
added to the repository.

At handoff time the remote Mac reports:

```text
Xcode 26.6 (17F113)
iPhoneOS SDK 26.5
xcrun devicectl list devices: No devices found.
security find-identity -p codesigning: 0 valid identities found
```

Consequently, the current source has produced a valid unsigned arm64 iOS app,
but no PeonPad build has yet been signed, installed, launched, or exercised on
a physical iPad. This is the precise resume boundary; do not interpret the
locally successful Xcode build as Phase 2 acceptance.

On the local Mac:

1. Pull the current GitHub `main` branch.
2. Restore the required local-only reference material under `ref/` without
   committing it. Run `./scripts/preflight.sh` and confirm the locked reference
   digest printed below. If the reference material is intentionally different,
   validate it before updating `config/inputs.lock`; do not bypass the guard.
3. Restore a local-test Aleona tree at `assets/aleonas-tales/source/`, or replace
   it with a verified compatible libre payload. A fresh clone intentionally
   cannot generate the app project without one of those payloads.
4. Run `./scripts/build-macos.sh` first. The iOS generator requires the host
   `toluapp` produced by that build.
5. Connect and trust the unlocked iPad, enable Developer Mode if requested,
   and confirm it appears in `xcrun devicectl list devices`.
6. Add the Apple ID only through Xcode's native **Settings → Accounts** flow and
   allow Xcode to create an Apple Development certificate.
7. Run `./scripts/generate-ios-xcode.sh`, open
   `build/ios-xcode/stratagus.xcodeproj`, select the `stratagus` target and the
   Personal Team, select the iPad, and press **Run**. If the fixed
   `org.peonpad.ios` identifier is unavailable, use a unique local bundle ID in
   Xcode for the first test and record the change before making it permanent.
8. Complete the physical acceptance checklist later in this document and save
   device logs/screenshots outside `ref/`.

The next engineering gate is deliberately narrow: get the current Aleona-based
vertical slice through one complete physical-device match. After it passes,
implement Phase 3 touch/Pencil/pointer input. Actual Warcraft II on iPad is a
later and separate Phase 4 milestone: add a Files/`UIDocumentPicker` import and
validation flow for the user's locally extracted `data.Wargus`, then verify
campaigns, skirmishes, audio, caching, and save/load. Blizzard content must
remain local and must never be committed or distributed.

The Generals iOS reference reinforces the expected device-only work after the
first launch: lifecycle-safe render/simulation pausing, cancelled-touch
handling, gesture arbitration, persistent device logs, and memory profiling.
PeonPad does not need Generals' DXVK/Vulkan/MoltenVK translation stack because
Stratagus already renders through SDL2's Metal backend.

## Executive status

Goals 0, 1, and 2 are complete and locally verified. Goal 3 is running on the
physical iPad: launch, menus, audio, and multiple live maps are proven, while a
complete-match regression remains. Goal 4 has started with
gameplay-only multi-touch controls and remains unaccepted until the device
regression matrix passes.

The iPad and local Personal Team signing are no longer blockers. The remaining
content blocker is unchanged: 797 Aleona media files lack a verified
redistribution grant, so the current Aleona payload is local-test-only and must
not be published or distributed.

## Goal evidence

| Goal | State | Current evidence |
| --- | --- | --- |
| Goal 0 — reproducible baseline | Complete | `scripts/preflight.sh` passes; all input revisions and tools are locked; `ref/` is ignored, untracked, and unchanged. |
| Goal 1 — macOS baseline | Complete | The PeonPad-built arm64 engine completed both a WC2 skirmish using read-only `ref/data.Wargus` and an independent Aleona match. Writable state was isolated under `runtime/`. |
| Goal 2 — iOS arm64 libraries | Complete | Stratagus, Wargus data layer, SDL2, SDL2_image, SDL2_mixer, Lua, tolua++, zlib, PNG, Ogg, Vorbis, Theora, and the remaining confirmed dependencies build as iOS arm64 artifacts. Architecture/platform verification passes. |
| Goal 3 — first playable iPad slice | Physical regression in progress | The signed app launches on the M2 iPad; campaigns and skirmishes render and play; manual save, autosave, load, and repeated Quit-to-Menu checks pass. A complete-match regression remains. The Aleona snapshot is not redistribution-cleared. |
| Goal 4 — Apple input | In progress | One-finger selection, leftmost-target two-finger commands, and three-finger camera pan are implemented and undergoing physical regression testing. Discoverable Shift/Control/Alt controls are designed but not implemented. |

## Phase 2 implementation proven locally

The current iOS app includes:

- SDL's UIKit application wrapper and an explicitly selected Metal renderer;
- an aspect-preserving safe-area viewport with UIKit point-to-Retina-pixel
  conversion shared by rendering and SDL input-coordinate conversion;
- landscape-left and landscape-right iPad orientations;
- `UIApplicationSupportsIndirectInputEvents = YES`;
- application-container writable state through `SDL_GetPrefPath`;
- bundled-data discovery through `SDL_GetBasePath()/Aleona`;
- original PeonPad launch artwork and opaque iPad icon renditions containing no
  game-derived branding;
- an application-bundle scan that rejects MPQs, installers, `data.Wargus`, and
  other proprietary Warcraft II inputs.

The Xcode route received an additional fix during the final audit. CMake 3.27
escaped Xcode's `${EFFECTIVE_PLATFORM_NAME}` in a post-build bundle path,
placing Aleona and artwork in a literal, incorrect directory. The
`platform/apple/ios/copy-xcode-bundle-resources.sh` bridge now uses Xcode's
authoritative `TARGET_BUILD_DIR` and `WRAPPER_NAME`. A clean unsigned Xcode
Release build and an incremental build both succeeded, and the real
`Release-iphoneos/PeonPad.app` now contains Aleona plus every declared launch
and icon resource.

Local application artifacts, intentionally excluded from Git, are:

```text
build/ios-arm64/engine/PeonPad.app
build/ios-xcode/Release-iphoneos/PeonPad.app
build/ios-xcode/stratagus.xcodeproj
```

Both executables are arm64 Mach-O files with `LC_BUILD_VERSION` platform iOS,
minimum iOS 16.0, and SDK 26.5. Both are intentionally unsigned. The native
Xcode project is generated reproducibly with `scripts/generate-ios-xcode.sh`.

## Immutable inputs and publication boundary

The locked reference digest is:

```text
c1782ea011559049ce65b739c6cbe5825a4db3b1c8d2afaea0dbcb54e7357f8f
```

Locked source revisions are recorded in `config/inputs.lock`, including:

- Stratagus: `3d87c93f7fd8c0b62ee1be5df0a6d9efc72ca6cc`
- Wargus: `cde1a0718a0058cc651ecd56ff8149fc39f624e9`
- Stratagus Vita: `5454452ec3ef9f6a14e51a57be8fe13e44893cdf`
- Aleona's Tales: `695d3ed6464cfa186c42e4804ee1e2c4e88f6e09`

The following remain local and must never be committed or pushed:

- `ref/`, including applications, installers, logs, repositories, and extracted
  Warcraft II data;
- all `data.Wargus` directories, MPQs, and installers;
- `build/`, `runtime/`, saves, caches, logs, signing identities, profiles, and
  local configuration;
- `assets/aleonas-tales/source/` while its asset audit remains unresolved.

The Aleona audit inspected 2,849 media files: 2,037 are covered by the vendored
Wyrmsun declaration, 15 non-vendor files have explicit grants, 112 have author
attribution without a license grant, and 685 lack adjacent provenance. The
unresolved total is 797. `PEONPAD_DISTRIBUTION_BUILD=1` makes both iOS build
entry points run the strict audit and stop before compilation. See
`aleona-asset-audit.md` for evidence and remediation paths.

## Resume checklist for the physical iPad

1. Connect the unlocked M2 iPad Pro to the Mac by USB.
2. Accept **Trust This Computer** on the iPad and enter its passcode.
3. If iPadOS requests it, enable **Settings → Privacy & Security → Developer
   Mode**, restart, and confirm Developer Mode after restart.
4. Confirm the device is visible:

   ```sh
   xcrun devicectl list devices
   ```

5. In **Xcode → Settings → Accounts**, add the Apple ID natively and allow
   Xcode to create a Personal Team development certificate. No third-party
   credential tool is used.
6. From the PeonPad root, regenerate the native project:

   ```sh
   ./scripts/generate-ios-xcode.sh
   open build/ios-xcode/stratagus.xcodeproj
   ```

7. Select the `stratagus` target, choose the Personal Team under **Signing &
   Capabilities**, select the connected iPad as the run destination, and press
   **Run**.
8. Verify the PeonPad launch mark appears, the app remains landscape, the menu
   stays inside safe areas at Retina resolution, and no import prompt appears.
9. Start an Aleona skirmish, verify Metal rendering and OGG audio, play through
   a complete match, then relaunch and confirm preferences/saves remain inside
   the application container.
10. Capture Xcode device-console output and any visual defects. Re-run
    `scripts/reference-digest.sh` after testing and confirm the locked digest is
    unchanged.

Passing all ten steps completes the remaining physical portion of Goal 3. It
does not clear Aleona for distribution; that remains a separate content gate.
Only after the physical match passes should Goal 4 input implementation begin.

## Revalidation commands

The iOS application commands below require the ignored local-test snapshot at
`assets/aleonas-tales/source/` in this existing workspace. A fresh GitHub clone
will intentionally not contain that unresolved payload; use a future
license-cleared Aleona snapshot or another verified compatible libre payload.

```sh
./scripts/preflight.sh
./tests/script-guardrails.sh
./scripts/test-ios-viewport.sh
./scripts/build-ios-libs.sh
./scripts/build-ios-app.sh
./scripts/audit-aleona-assets.sh --local-test
./scripts/reference-digest.sh
```

Expected nonfatal warnings are recorded in `ios-static-libraries.md` and
`ios-app-shell.md`. They are primarily upstream deprecation and precision
warnings plus duplicate static-library link warnings. No new PeonPad platform
bridge warning remains.
