# Agent instructions

## Release gate

Every public release artifact (IPA, APK, macOS or desktop build, and any source archive attached to a release) must pass `python3 ~/.codex/release-gate/release_gate.py <artifact>` on the maintainer's machine before it is published. A failure is a stop, not a note. Never commit original game data, ROMs, discs, keys, or translated or decompiled game code.
