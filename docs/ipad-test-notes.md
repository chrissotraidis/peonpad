# iPad test status and product decisions

Status captured: 2026-07-12

## Product target and test content

PeonPad targets **Warcraft II through Wargus**, not Warcraft III. The engine
cannot run Warcraft III content.

The distributable vertical-slice configuration boots Aleona's Tales because it
is the only complete non-Blizzard payload available without an import step. It
is a test payload, not a disguised or expanded edition of Warcraft II. Its
current asset audit also prevents distribution.

For private USB testing, the repository already contains the user's extracted
Warcraft II runtime at `ref/data.Wargus`. A device-only staging copy excludes
the redundant 468 MB installer MPQ and produces a roughly 296 MB payload. The
2026-07-12 signed iPad build now runs that Warcraft II payload instead of
Aleona. Neither the extracted data nor the staged copy may be committed.

Recreate that private payload with:

```sh
./scripts/stage-ios-wc2-test-data.sh
```

The staging script also removes incompatible legacy custom modes from the
device-facing Standard Game list without modifying `ref/data.Wargus`.

The iPad runs Stratagus as a native ARM64 iPadOS executable with SDL2 and
Metal. The Windows installer `.exe`, `.bin`, and MPQ are source material for
data extraction; they are not executed or emulated on iPad.

The intended product flow is therefore explicit content selection:

1. **Import Warcraft II data** — select a locally extracted `data.Wargus`
   folder through Files. This is the authentic Warcraft II campaign/skirmish
   path and remains the primary project goal.
2. **Play the free content** — launch a license-cleared libre game when one is
   available. Aleona's Tales fills this role only during local development.

PeonPad must not silently present Aleona as Warcraft, copy Warcraft artwork
into Aleona, or bundle Blizzard data. Until the importer exists, development
builds should identify Aleona as test content.

## Physical iPad findings

Verified on the USB-connected M2 iPad Pro:

- signed installation, launch, landscape/safe-area layout, audio, menus, and
  responsive single-touch input;
- King of the Hill starts after correcting a malformed default-map Lua line;
- For the Motherland starts, but can show a blank screen for several seconds
  while loading;
- Skirmish Classic starts and plays;
- Beyond the Dark Portal Alliance, Act I (`A Time for Heroes`) renders its
  terrain, loads, and plays on the physical iPad;
- Skirmish Modern's default map starts player 0 at `{40, 1}` with a single
  peasant, which can look like a blank or misplaced camera until the player
  scrolls. This is map setup/fog behavior, not the campaign terrain failure;
- three-finger camera pan works after gameplay finishes loading, although the
  gesture should not be judged during the initial loading transition;
- Quit to Menu worked on a later attempt, but one earlier attempt appeared to
  terminate the app and remains a regression check;
- manual saves and both the manual save and autosave were loaded successfully
  during the 2026-07-12 device pass;
- replay logs persisted across earlier payload changes. Logs whose maps are no
  longer available now fail a preflight instead of reaching the engine's fatal
  map loader; disabled Front Lines and Motherland maps are absent from the
  staged device runtime. Because playback is not reliable even for newer logs,
  Replay Game and Save Replay are hidden in the iPad test profile;
- Front Lines starts its simulation but does not render its terrain layer with
  either tested payload. On the Warcraft II payload it then terminates with
  `UnitTypeByIdent: Unknown unitType 'unit-nomad'`. It is excluded from the
  device-test mode menu until the legacy custom content is repaired.

The exposed local-test modes are now limited to For the Motherland, King of
the Hill, Skirmish Classic, and Skirmish Modern. This is an allowlist of modes
that reach a live game loop; it is not a promise that all Aleona content is
release-ready.

The private Warcraft II device profile is narrower: Standard Game exposes only
Skirmish Classic and Skirmish Modern. Front Lines, Random Skirmish, and For the
Motherland are incompatible legacy extensions and are hidden. Original Human,
Orc, and expansion campaigns remain available through Campaign Game.

## Touch control model

The control model should remain discoverable and allow keyboard-equivalent
combinations. Multi-finger shortcuts alone cannot cover Shift+Alt, are hard to
learn, and conflict with camera movement and iPadOS gestures.

Current implementation:

- one finger retains SDL's existing pointer/select behavior, and tapping empty
  terrain clears the current selection;
- a two-finger chord issues the equivalent of a right click at the leftmost
  finger's position, making the target independent of which finger lands first;
- moving either finger beyond a small tolerance cancels the pending right-click
  command;
- a three-finger drag pans the camera directly and cancels any pending
  two-finger command;
- multi-touch gestures are gameplay-only, never invoke menu callbacks, and
  reset when the app backgrounds or leaves gameplay;
- Pencil and hardware pointer behavior remain unchanged;
- tapping a text field reactivates SDL text input after the iOS window has
  focus, allowing UIKit to present the software keyboard;
- the three-finger camera pan uses a modest 1.35 movement gain. It has no
  momentum state, keeping gesture cancellation and menu transitions simple.

The app declares indirect-input support and retains SDL's native hardware
keyboard, mouse, and trackpad event paths. A connected Magic Keyboard or mouse
should therefore provide normal pointer buttons, keyboard shortcuts, and
modifier combinations. Trackpad gestures reserved by iPadOS, including system
three-finger navigation, are not available to the game; trackpad scrolling is
delivered as mouse-wheel input rather than as PeonPad's direct-touch pan.

The classic Wargus gameplay view is fixed-scale and does not expose a native
pinch-zoom command. Multiplayer code exists in the engine, but network play on
iPad remains unverified and is outside the current touch-control acceptance
gate.

A custom delayed single-touch recognizer was tested and immediately rolled
back because it could swallow gameplay taps and leave in-game menus
unresponsive. Future timing forgiveness must preserve SDL's proven single-touch
stream rather than replacing it wholesale.

Planned modifier dock:

- show compact **Shift**, **Control**, and **Alt** controls only during a game;
- one tap arms a modifier for the next action, then clears it;
- double-tap locks a modifier for repeated actions; tap again to release;
- allow combinations such as Shift+Alt and show every active state clearly;
- clear all modifiers on pause, game exit, and return to menu;
- preserve native hardware-keyboard modifiers when a keyboard is connected.

Priority follows actual Warcraft II usage: Shift first for queued orders and
repeat building, Control second for type selection/autocast, then Alt for
defend and Shift+Alt building behavior. The modifier dock should be implemented
after the two-finger command/three-finger pan mapping survives the device
regression matrix.

Skirmish Classic's Opponents list is constrained by the selected scenario. Its
default two-player map correctly offers only one opponent; selecting a larger
scenario expands the list rather than requiring dropdown scrolling.

## Next device regression matrix

1. Start and exit King of the Hill, Motherland, Skirmish Classic, and Skirmish
   Modern in one process.
2. Pan the camera repeatedly with three fingers while no unit is selected, while
   a unit is selected, and after opening/closing an in-game menu.
3. Confirm single taps still select and issue commands after every pan.
4. Background and foreground the app during a pan, then confirm input is not
   stuck.
5. Exercise Quit to Menu from every mode and verify the app remains alive.
6. Complete one skirmish, then verify save/load and relaunch persistence.
7. Capture a screenshot and console log for any missing terrain before
   changing renderer or tileset code.
8. With no hardware keyboard connected, tap the save-name and network login
   fields and confirm the iPad keyboard appears and types into the field.
9. Attach the Apple Magic Keyboard case and verify pointer movement, primary
   and secondary click, Shift-click, Control-click, Alt-click, and ordinary
   typing. Treat iPadOS-reserved trackpad gestures as system behavior.
10. Confirm Replay Game is absent from the main menu and Save Replay is absent
    from the results screen. Replay playback remains deferred rather than
    presenting files that cannot be used reliably.
