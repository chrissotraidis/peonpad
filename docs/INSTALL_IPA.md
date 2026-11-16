# Install the unsigned PeonPad IPA

PeonPad's preview IPA contains the native ARM64 engine, PeonPad integration,
branding, and required open-source notices. It contains no Warcraft II data and
is not signed for a particular Apple account.

## Requirements

- An iPad running iPadOS 16 or newer.
- A method you trust to sign and install an unsigned IPA.
- A complete `data.Wargus` extracted on a computer from your legally owned
  Warcraft II copy with Wargus 3.2 or newer (3.3.x is what PeonPad is tested
  with), or with PeonPad's `scripts/prepare-ipad-build.sh`. PeonPad turns away
  data made by Wargus 3.1 or older, because those scripts call engine functions
  its Stratagus no longer has.
- If your FFmpeg has no `libtheora` encoder, Wargus leaves `data.Wargus/videos`
  empty. The game still runs, without its cinematics;
  `scripts/prepare-ipad-build.sh` works around the missing encoder.

## Install and add game data

1. Download `PeonPad-0.1.0-preview.2-unsigned.ipa` and its checksum from the
   matching GitHub prerelease.
2. Verify the SHA-256 checksum.
3. Sign and install the IPA. It is not directly installable until signed.
4. Launch PeonPad once. With no data present, it reports the expected Files
   location. Dismiss the message; PeonPad closes without starting the engine.
5. In Files or Finder file sharing, open the PeonPad app folder and copy the
   complete directory as `data.Wargus`:

   ```text
   On My iPad/PeonPad/data.Wargus
   ```

6. Relaunch PeonPad.

The app requires these entries inside the selected folder:

```text
data.Wargus/extracted
data.Wargus/scripts/stratagus.lua
data.Wargus/graphics/
data.Wargus/maps/
data.Wargus/sounds/
```

Do not copy the original installer, `.bin`, MPQ, disc image, signing credential,
or provisioning profile into the PeonPad folder. Extraction remains a desktop
operation. Saves and preferences remain in PeonPad's separate application
support directory and survive an in-place update with the same bundle ID.

## If PeonPad closes or says it had to stop

When the game engine hits an error, such as a missing or unreadable file in
`data.Wargus`, PeonPad shows a **PeonPad stopped** message with the reason
before it closes. Every launch is also written to `PeonPad.log` in the PeonPad
folder, and the launch before it is kept as `PeonPad.previous.log`. Attach
`PeonPad.log` when you report a problem; it holds the app version, device
model, iPadOS version and the engine's messages, and no game data.

In LiveContainer, the PeonPad folder is PeonPad's data container inside
LiveContainer's own folder (`LiveContainer/Data/Application/<container>/Documents`),
so `data.Wargus` and the logs go there.

## What the release proves

The release audit checks the IPA structure, ARM64/iPadOS identity, legal files,
absence of signing material, and absence of bundled game/private data. It does
not make the IPA App Store or TestFlight software, supply a signing service, or
grant rights to Warcraft II content.
