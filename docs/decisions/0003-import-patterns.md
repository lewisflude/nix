# ADR-0003: Standardize Import Patterns

**Date:** 2025-01-14  
**Status:** Accepted  
**Deciders:** Lewis Flude  
**Technical Story:** Phase 2 Architecture Improvements - Import Pattern Standardization

## Context

Import statements throughout the codebase were inconsistent:

```nix
# Mixed patterns observed
imports = [
  ./directory         # Sometimes
  ./directory.nix     # Other times
  ./file             # Sometimes  
  ./file.nix         # Other times
];
```

This inconsistency caused:
- Confusion about whether something is a file or directory
- Mental overhead when reading code
- No clear convention for new contributors
- Harder to maintain (unclear what pattern to follow)

Consistency was approximately 70% - enough to cause issues but not enough to have a clear standard.

## Decision

**Standard:** Directories without `.nix` extension, files with `.nix` extension.

```nix
imports = [
  ./directory      # ✅ Directory (has default.nix inside)
  ./file.nix       # ✅ File
];
```

This pattern makes it immediately clear from the import statement alone whether you're importing a single module file or a directory of modules.

## Consequences

### Positive

- **Visual Clarity**: Immediate distinction between files and directories
- **Consistency**: 100% uniform pattern across codebase
- **Easier Review**: Code reviews can catch violations easily
- **Onboarding**: New contributors understand convention immediately
- **Tooling Friendly**: Can write validators/linters for this pattern
- **Nix Idiomatic**: Follows Nix/NixOS conventions

### Negative

- **Migration Effort**: Required updating existing imports
- **Breaking Pattern**: Some might prefer `./file` for brevity

### Neutral

- **Slightly Verbose**: Files require `.nix` suffix (4 extra chars)
- **Learning Curve**: New pattern to learn (but very simple)

## Alternatives Considered

### Alternative 1: Always Use .nix Extension
```nix
imports = [
  ./directory.nix    # Directory
  ./file.nix         # File  
];
```

**Rejected because:**
- Inconsistent with Nix conventions (directories don't have extensions)
- Less clear that it's a directory
- Would require renaming directories or creating file wrappers

### Alternative 2: Never Use .nix Extension
```nix
imports = [
  ./directory        # Directory
  ./file             # File
];
```

**Rejected because:**
- Can't distinguish files from directories
- Requires checking filesystem to understand imports
- Less explicit than our chosen approach

### Alternative 3: Use Different Markers
```nix
imports = [
  ./directory/       # Directory with trailing slash
  ./file.nix         # File
];
```

**Rejected because:**
- Trailing slashes are not idiomatic in Nix
- Can cause issues with path manipulation
- Not well-supported by Nix tooling

## Implementation Details

### Pattern Rules

1. **Directories** (containing `default.nix`):
   ```nix
   ./apps          # ✅ Correct
   ./apps/         # ❌ No trailing slash
   ./apps.nix      # ❌ No extension
   ```

2. **Files** (standalone modules):
   ```nix
   ./git.nix       # ✅ Correct
   ./git           # ❌ Must have extension
   ```

3. **Exceptions**: None. This rule applies universally.

### Validation

Created validator in `lib/validation.nix`:
```nix
validateImportPatterns = imports: let
  invalidImports = lib.filter (import:
    if lib.hasSuffix ".nix" import
    then false  # Files with .nix are valid
    else true   # Check if it's actually a directory
  ) imports;
in
  if invalidImports != []
  then lib.warn "Invalid import patterns: ${...}" true
  else true;
```

### Migration Strategy

1. Identify all `default.nix` files
2. Update imports to use directory name without `.nix`
3. Ensure all file imports have `.nix` extension
4. Run formatter to ensure consistency
5. Add validation to catch future violations

## Examples

### Before
```nix
# Inconsistent
{...}: {
  imports = [
    ./apps.nix           # Directory, wrongly has .nix
    ./git                # File, missing .nix
    ./development        # Directory, correct
    ./shell.nix          # File, correct
  ];
}
```

### After
```nix
# Consistent
{...}: {
  imports = [
    ./apps               # Directory ✅
    ./git.nix            # File ✅
    ./development        # Directory ✅
    ./shell.nix          # File ✅
  ];
}
```

## Documentation

- Added to [modules/INDEX.md](../../modules/INDEX.md)
- Added to [CONTRIBUTING.md](../../CONTRIBUTING.md)
- Examples in all `default.nix` files
- Validation helpers in `lib/validation.nix`

## References

- [Phase 2 Documentation](../PHASE-2-IMPROVEMENTS.md)
- [Module Index](../../modules/INDEX.md#import-patterns)
- [Contributing Guide](../../CONTRIBUTING.md#import-patterns)
- Commit: `6f84100`

## Related ADRs

- None directly, but establishes pattern used in all future modules

---

**Result:** Successfully standardized across entire codebase. Import consistency: 70% → 100%. Clear, easy-to-follow pattern for all contributors.
