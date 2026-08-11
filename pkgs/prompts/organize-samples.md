# Organize Samples

You are tidying the user's sample library at `~/Music/samples`. This folder is
NFS-exported to Mercury (macOS) and consumed by Ableton Live, so the layout must
stay stable and human-browsable.

New content lands here automatically via qBittorrent's `music-production`
category. Each completed torrent arrives as `~/Music/samples/<torrent-name>/`.

## Workflow

1. **Survey.** List the top level of `~/Music/samples`. For each unorganised
   entry, note: name, size (`du -sh`), and a one-line guess at its type (drum
   kit, synth preset pack, loop pack, stems, multisample, etc.). Use `file` /
   extensions to inform the guess.
2. **Propose a taxonomy.** Use or extend the user's existing folders. Prefer
   this baseline unless the user has diverged:
   - `drums/` — oneshots, kits, breaks
   - `loops/` — melodic/rhythmic loops
   - `synths/` — presets, patches, multisamples
   - `stems/` — song stems, acapellas
   - `fx/` — risers, impacts, foley, textures
   - `packs/` — commercial sample packs kept whole
3. **Confirm before moving.** Present the proposed moves in a table (source →
   destination) and wait for approval. Never move without confirmation.
4. **Preserve structure.** If a torrent arrives as a well-structured sample pack
   (e.g. nested `Kicks/`, `Snares/`, `Presets/`), keep it whole under
   `packs/<pack-name>/`. Do not flatten commercial packs.
5. **Move, never copy or delete.** Use `mv`. If a destination already exists,
   ask the user — do not overwrite.
6. **Clean up empties.** After moves, `rmdir` empty source dirs (but never
   `rm -rf`).

## Guardrails

- Treat anything ambiguous as a question for the user rather than a guess.
- If a focus is given (e.g. `drums`, `synths`, `loops` — `$ARGUMENTS` when
  invoked as a slash command), restrict the pass to items that look like that
  category.
- Never touch files outside `~/Music/samples`.
- Never delete. If something looks like junk (thumbnails, `.DS_Store`, torrent
  metadata), surface it and let the user decide.
- Ableton references samples by absolute path — warn the user before moving
  anything that's already been dragged into a live project.
