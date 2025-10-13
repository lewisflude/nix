# ADR-0001: Consolidate Overlay Management

**Date:** 2025-01-14  
**Status:** Accepted  
**Deciders:** Lewis Flude  
**Technical Story:** Phase 1 Architecture Improvements

## Context

Overlays were defined in multiple locations throughout the codebase:

1. Inline in `lib/output-builders.nix` (~30 lines)
2. Inline in `modules/shared/overlays.nix` (~30 lines)
3. Individual files in `overlays/` directory (cursor, npm-packages)

This resulted in:
- Significant code duplication (~60 lines repeated)
- Unclear single source of truth
- Difficult to add new overlays (multiple places to update)
- Maintenance burden (changes needed in multiple files)

## Decision

Consolidate all overlay management into the `overlays/` directory with a single entry point:

```
overlays/
├── default.nix       # Single entry point, exports all overlays
├── cursor.nix        # Existing overlay
├── npm-packages.nix  # Existing overlay
├── waybar.nix        # Extracted from inline
├── swww.nix          # Extracted from inline
└── ghostty.nix       # Extracted from inline (Darwin-specific)
```

All consumers now use:
```nix
overlays = import ../overlays {inherit inputs system;};
```

## Consequences

### Positive

- **Zero Duplication**: Overlays defined exactly once
- **Single Source of Truth**: Clear location for all overlays
- **Easy to Extend**: Add new overlay = create one file
- **Better Organization**: All overlays in one place
- **Reduced LOC**: ~60 lines of duplication eliminated
- **Simpler Imports**: One line instead of 30+

### Negative

- **Indirection**: One extra level of indirection via `default.nix`
- **Migration Effort**: Required updating multiple files in one change

### Neutral

- **Structure Change**: New pattern to learn (but well-documented)
- **Backward Compatibility**: Old imports don't work (intentional breaking change)

## Alternatives Considered

### Alternative 1: Keep Inline Overlays
**Rationale:** No change needed, works as-is

**Rejected because:**
- Duplication is a maintenance burden
- Violates DRY principle
- Makes adding overlays more complex

### Alternative 2: Centralize in a Single File
**Rationale:** Put all overlays in `overlays.nix` instead of directory

**Rejected because:**
- Would create a very large file
- Less modular than directory approach
- Harder to maintain as overlays grow

### Alternative 3: Keep Duplicated, Add Comments
**Rationale:** Document why duplicated, keep as-is

**Rejected because:**
- Doesn't solve the actual problem
- Documentation doesn't prevent drift
- Still requires updating multiple places

## Implementation Details

### Pattern Established

Each overlay file follows this pattern:
```nix
# overlays/my-overlay.nix
{inputs}: final: prev: {
  my-package = ...;
}
```

The `default.nix` aggregates them:
```nix
# overlays/default.nix
{inputs, system}: [
  (import ./cursor.nix)
  (import ./npm-packages.nix)
  (import ./waybar.nix {inherit inputs;})
  # ...
]
```

### Migration Path

1. Extract inline overlays to files
2. Create `default.nix` aggregator
3. Update consumers to use consolidated import
4. Verify builds work
5. Delete old inline definitions

## References

- [Phase 1 Documentation](../ARCHITECTURE-IMPROVEMENTS.md)
- [Nixpkgs Manual - Overlays](https://nixos.org/manual/nixpkgs/stable/#chap-overlays)
- Commit: `d9a4ab9`

## Related ADRs

- None (this is the first ADR)

---

**Result:** Successfully implemented in Phase 1. Reduced codebase by 126 lines and eliminated all overlay duplication.
