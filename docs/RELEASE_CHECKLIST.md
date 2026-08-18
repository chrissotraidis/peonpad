# PeonPad unsigned IPA release checklist

## Source and tests

- [ ] Release commit is reviewed and the worktree contains no staged private data.
- [ ] `./scripts/preflight.sh` passes.
- [ ] `./tests/script-guardrails.sh` passes.
- [ ] `./scripts/test-ios-game-data-path.sh` passes.
- [ ] `./scripts/test-ios-control-groups.sh` passes.
- [ ] `./scripts/test-ios-viewport.sh` passes.
- [ ] The ordered Stratagus patch series reconstructs the tracked engine tree.

## Artifact

- [ ] `./scripts/build-ios-release.sh` succeeds without `ref/`, Aleona, game data,
      a signing identity, or a provisioning profile.
- [ ] `./scripts/audit-ios-app.sh` passes.
- [ ] `./scripts/package-ios.sh` succeeds twice from the same app and both IPAs
      have the same SHA-256 hash.
- [ ] A deliberately injected `data.Wargus`/signing fixture is rejected.
- [ ] The release includes the unsigned IPA, checksum, and exact corresponding
      source archive.

## Physical iPad

- [ ] Back up the existing PeonPad `Documents` and `Library` state.
- [ ] Install a signed copy of the data-free release build in place.
- [ ] Missing-data launch displays the setup message without a crash.
- [ ] `Documents/data.Wargus` is accepted after copying through Files/Finder.
- [ ] Campaign, skirmish, audio, touch, save/load, and relaunch pass.
- [ ] An in-place update preserves `data.Wargus`, saves, and preferences.

## Publication

- [ ] Tag `v0.1.0-preview.1` points to the reviewed release commit.
- [ ] GitHub release is marked prerelease and documents unsigned/user-data terms.
- [ ] Downloaded IPA and checksum match the locally audited artifact.
- [ ] `main`, `origin/main`, the release tag, and hosted source are verified.
