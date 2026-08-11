---
description:
  Dendritic pattern guide for writing and modifying .nix flake-parts modules in
  this repository. Use whenever editing, creating, or refactoring .nix files in
  this repo.
---

# Dendritic Pattern

Every .nix file (except flake.nix) is a flake-parts module.

**Read `DENDRITIC_PATTERN.md` in the repository root before writing or
refactoring any module.** It is the canonical reference for the module template,
the two config scopes and how to avoid shadowing, the anti-patterns, the
nixos-vs-homeManager placement rules, and the workflow commands. Do not work
from memory — read the file.

Never rebuild systems from within Claude — suggest `nh os switch` /
`nh home switch` for the user to run.
