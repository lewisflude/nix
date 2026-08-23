---
description:
  Generate Ableton Drum Rack .adg files from samples. Folder mode picks
  deterministically; vibe mode curates by theme.
allowed-tools:
  Bash(drumrack:*), Bash(ls:*), Bash(find:*), Bash(file:*), Bash(du:*),
  Bash(test:*), Read, Glob, Grep
argument-hint: [folder path | theme description]
---

You are building an Ableton Drum Rack `.adg` from samples in `~/Music/samples`.
The library is SMB-mounted on Mercury (macOS) at `/Volumes/music/samples/`,
where Ableton Live consumes the generated rack. The `drumrack` CLI handles the
.adg mechanics; your job is curation and confirmation.

## Modes

- **Folder mode** — `$ARGUMENTS` is an existing directory containing categorised
  samples (`Kicks/`, `Snares/`, `Claps/`, `Hats/`, `Perc/`, etc.).
  Deterministic; uses alphabetical pick per category, 4×4 Push layout (C1–D#2).
- **Vibe mode** — `$ARGUMENTS` describes a theme (e.g. "dark 80s industrial",
  "warm boom-bap", "footwork"). You search the library, propose pads, get
  confirmation, then drive the generator with a JSON spec.

## Workflow — folder mode

1. Run `drumrack build-from-folder "$ARGUMENTS" --dry-run`. This prints the
   proposed pad→sample table.
2. Show the table to the user and ask for confirmation (or to swap any pads).
3. On confirmation, re-run without `--dry-run`. The `.adg` lands beside the
   source folder.

## Workflow — vibe mode

1. Map the theme to candidate folders. Use the user's library taxonomy (see
   `organize-samples`): start with `~/Music/samples/drums/oneshots/` and
   `~/Music/samples/Packs/` for category folders matching the theme. Use
   `find`/`Glob` with case-insensitive name matches; sample-library hints in
   filenames (genre tags, drum-machine names) are useful.
2. Propose 4–16 pads as a table: pad #, MIDI note (C1=36 ascending), pad name,
   candidate sample path. Cover at least kicks + snares + hats; add percs if the
   theme calls for it.
3. Ask the user to confirm or swap individual pads.
4. Build a JSON spec:

   ```json
   {
     "name": "<kit name>",
     "out_path": "/home/lewisflude/Music/samples/<dest>/<kit name>.adg",
     "pads": [
       {"midi_note": 36, "name": "Kick", "sample": "/home/.../kick.wav"},
       ...
     ]
   }
   ```

5. Pipe it: `echo '<spec-json>' | drumrack build-from-spec -`.

## Guardrails

- **Never overwrite.** If the target `.adg` already exists, ask for a new name.
  The CLI errors out without `--force`; do not pass `--force` without explicit
  user permission.
- **Default output location:** sibling of the source kit folder (folder mode) or
  under the most-relevant pack directory (vibe mode). This keeps racks colocated
  with their samples — matches how Live's pack convention works.
- **All samples must live under `~/Music/samples/`.** The CLI errors otherwise.
  If the user picks a sample elsewhere, surface the error rather than working
  around it.
- **MIDI layout reminder:** standard Push 4×4 drum grid is C1=36 (kick row,
  bottom) through D#2=51 (perc row, top). Pads on other notes are valid but
  won't sit on the visible Push pad grid.
- **Mac path translation is automatic** — the CLI rewrites `~/Music/samples/...`
  to `/Volumes/music/samples/...` in the .adg. Don't pre-translate.
- On success, print the mac path of the output and remind the user to refresh
  Live's browser to see the new rack.
