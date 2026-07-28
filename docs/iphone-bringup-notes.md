# iPhone bring-up findings

> **Status:** investigation record only. PeonPad remains an iPad-first
> developer preview and does not currently claim iPhone support.

On July 28, 2026, the current `main` build at `f492151c` was compiled, signed,
installed and launched on a physical iPhone 14 (`iPhone14,7`) running iOS
26.5.2. The app remained present in the device process list after launch.

That result proves that the arm64 application can run on the phone. It does not
prove that the interface, gestures, performance or lifecycle are suitable for
iPhone use.

## How the experiment differed from the repository

The tracked Xcode target remains deliberately iPad-only with
`TARGETED_DEVICE_FAMILY=2`. For this experiment, the generated, ignored Xcode
project was changed locally to target device families `1,2`. No tracked source
configuration was changed to claim iPhone support.

The build used normal Apple Development signing and an in-place device install.
Device identifiers, provisioning material and user-owned game data are not part
of this record and must remain local.

## Physical findings

### Layout and readability

- iOS currently forces an `800x600` logical game surface.
- The safe-area viewport preserves that 4:3 aspect ratio.
- A regular iPhone in landscape is much wider than 4:3, so the game occupies a
  narrow central area with substantial unused width.
- Scaling the entire `800x600` interface to the phone's height makes text,
  command buttons and the control-group bank uncomfortably small.
- The tracked Info.plist defines iPad landscape orientations and iPad icons,
  but has no accepted iPhone-specific orientation or icon configuration.

Simply enabling the iPhone device family is therefore not a usable layout fix.
Stretching the 4:3 image would also be incorrect.

### Multitouch

The current gesture contract is:

- one finger for pointing, selection, drag-selection and UI activation;
- a two-finger **tap** for a right-click command at the leftmost finger;
- movement beyond a 16-logical-pixel tolerance cancels that pending command;
- a three-finger drag pans the map; and
- PeonPad multitouch gestures run only during gameplay, not in menus.

During this iPhone experiment, two-finger touch did not produce an effective
gameplay result for the tester. This needs an instrumented reproduction before
the exact cause is declared.

One concrete area to investigate is coordinate conversion. Rendering is
aspect-fitted into a safe-area viewport, while the PeonPad finger-event path
currently converts normalized SDL touch coordinates directly with
`point * Video.Width/Height`. On a wide, letterboxed phone this may target a
different logical position from the content under the finger. Tests should
cover touches inside the viewport, in the side regions and near each safe-area
edge.

## Recommended iPhone work

Keep the first iPhone iteration narrow and reversible:

1. **Declare the platform correctly**
   - add an intentional `1,2` device-family setting;
   - add explicit landscape orientations and required icons for iPhone; and
   - keep the public status iPad-first until physical acceptance passes.
2. **Make input and rendering share one transform**
   - expose one tested screen-to-logical coordinate conversion;
   - use it for finger gestures, synthesized mouse commands and control groups;
   - define how touches outside the rendered game viewport behave; and
   - add geometry fixtures for regular and Max-size iPhones with safe-area
     insets.
3. **Adapt the phone gesture contract**
   - preserve immediate one-finger interaction;
   - retain a two-finger tap for right-click;
   - consider starting map pan when two-finger movement crosses the tolerance,
     instead of requiring an awkward three-finger drag on a phone; and
   - regression-test cancellation, menus, backgrounding and foregrounding.
4. **Design a phone layout rather than shrinking the iPad layout**
   - keep touch targets readable and thumb-accessible;
   - use the wide landscape regions intentionally for compact controls;
   - decide whether gameplay should gain a wider map viewport while classic
     menus remain aspect-preserved; and
   - avoid stretching artwork or hiding content behind the notch or Home
     indicator.

The smallest useful prototype is the input-transform fix plus phone-specific
two-finger pan behavior. A genuinely comfortable regular-iPhone layout is a
separate product and UI task.

## Physical acceptance checklist

Before changing the public support statement, verify on at least one regular
iPhone and one larger iPhone:

- signed install, launch and relaunch;
- both landscape orientations and every safe-area edge;
- readable menus, gameplay panels, text entry and control groups;
- one-finger selection and UI activation;
- two-finger command and pan behavior, including cancellation;
- save/load, background/foreground recovery and repeated menu cycles;
- audio, frame pacing, memory, thermals and battery behavior; and
- hardware keyboard, pointer and controller behavior where available.

Build or Simulator success cannot replace this physical usability pass.

## Useful starting points

- `engine/stratagus/CMakeLists.txt` — device-family build setting
- `platform/apple/ios/Info.plist.in` — orientations, icons and device metadata
- `engine/stratagus/src/ui/script_ui.cpp` — forced iOS logical resolution
- `platform/apple/ios/PeonPadIOSViewport.mm` — safe-area viewport application
- `platform/apple/ios/PeonPadViewportGeometry.cpp` — aspect-fit calculation
- `engine/stratagus/src/video/sdl.cpp` — finger gestures and coordinate mapping
- `platform/apple/ios/PeonPadControlGroupLayout.cpp` — fixed `800x600` overlay
- `tests/viewport_geometry_test.cpp` — current geometry regression fixtures
