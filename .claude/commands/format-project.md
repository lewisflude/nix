---
description: "Format all Nix files in the project using treefmt"
---

# Format Project

Format all `.nix` files in the project using `treefmt` or `nix fmt`.

## What This Does

Runs the project's formatter (treefmt) across all Nix files to ensure consistent formatting and code style.

## Formatting Standards

The project uses:
- **nixfmt** or **nixpkgs-fmt** for Nix file formatting
- **treefmt** as the unified formatting frontend
- Automated formatting hooks in Claude Code (PostToolUse)

## Usage

```
/format-project
```

No arguments needed - this will format the entire project.

## Your Task

1. **Run formatter**:
   ```bash
   treefmt
   ```

2. **Check results**:
   - Review which files were formatted
   - Check for any formatting errors
   - Verify no unexpected changes

3. **Report**:
   - List files that were reformatted
   - Note any errors or warnings
   - Confirm successful formatting

## After Formatting

You should:
1. **Review changes**: Run `git diff` to see what changed
2. **Verify builds**: Suggest running `nix flake check`
3. **Commit if needed**: If formatting made changes, they should be committed

## Alternative: Format Specific Files

If you want to format only specific files:

```bash
# Single file
nix fmt path/to/file.nix

# Multiple files
nix fmt file1.nix file2.nix
```

## Common Issues

**Issue**: `treefmt` not found
**Solution**: Ensure you're in the project root and Nix environment is loaded

**Issue**: Formatting conflicts with manual edits
**Solution**: Commit manual edits first, then run formatter separately

**Issue**: Some files unchanged
**Solution**: Those files were already properly formatted

## Related Commands

- `/validate-module` - Check module structure and style
- `/nix/check-build` - Validate flake builds after formatting

## Related Documentation

- `docs/DX_GUIDE.md` - Code formatting standards
- `CONVENTIONS.md` - Coding style requirements
