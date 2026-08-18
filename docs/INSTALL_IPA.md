# Install the unsigned PeonPad IPA

PeonPad's preview IPA contains the native ARM64 engine, PeonPad integration,
branding, and required open-source notices. It contains no Warcraft II data and
is not signed for a particular Apple account.

## Requirements

- An iPad running iPadOS 16 or newer.
- A method you trust to sign and install an unsigned IPA.
- A complete `data.Wargus` extracted on a computer from your legally owned
  Warcraft II copy.

## Install and add game data

1. Download `PeonPad-0.1.0-preview.1-unsigned.ipa` and its checksum from the
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

## What the release proves

The release audit checks the IPA structure, ARM64/iPadOS identity, legal files,
absence of signing material, and absence of bundled game/private data. It does
not make the IPA App Store or TestFlight software, supply a signing service, or
grant rights to Warcraft II content.
