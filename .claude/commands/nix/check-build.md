---
description: "Validate Nix flake builds without activating"
---

# Check Nix Build

Validate that the Nix flake builds correctly without activating the configuration.

## What This Does

Runs `nix flake check` and optionally builds specific outputs to verify the configuration is valid.

## Usage

```
/nix/check-build [hostname]
```

**Arguments**:
- `$1` (optional) - Hostname to check (checks current host if omitted)
- Use "all" to check all outputs

## Checks Performed

### 1. Flake Check

```bash
nix flake check
```

Validates:
- Flake syntax
- Module imports
- Option types
- System outputs
- Tests (if defined)

### 2. Build Specific Host (optional)

```bash
# NixOS
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel

# nix-darwin
nix build .#darwinConfigurations.<hostname>.system
```

Verifies the configuration builds completely.

### 3. Home Manager Check (optional)

```bash
nix build .#homeConfigurations.<username>@<hostname>.activationPackage
```

Validates home-manager configuration builds.

## Your Task

1. **Run flake check**:
   ```bash
   nix flake check
   ```

2. **Analyze output**:
   - Check for errors or warnings
   - Identify specific issues
   - Note which modules have problems

3. **If errors found**:
   - Explain the error clearly
   - Identify the problematic file/line if possible
   - Suggest fixes

4. **If successful**:
   - Confirm all checks passed
   - List what was validated
   - Note any warnings to address

5. **Optional: Build test**:
   If `nix flake check` passes, offer to test-build specific outputs

## Common Errors

**Syntax errors**:
- Missing semicolons, brackets, braces
- Typos in attribute names
- Fix by correcting the syntax

**Type errors**:
- Wrong type for option (e.g., string instead of list)
- Fix by using correct type

**Import errors**:
- File doesn't exist
- Circular dependency
- Fix by correcting paths or breaking cycles

**Option conflicts**:
- Same option set multiple times
- Conflicting values
- Fix by resolving in higher-priority location

## After Successful Check

Recommend:
1. ✅ Configuration is valid
2. 💡 Ready to build and switch (user must run)
3. 📝 Commit changes if this was a fix

## Build Commands (For User)

**DO NOT RUN these commands** - suggest to user:

```bash
# NixOS
nh os switch
# or
sudo nixos-rebuild switch --flake .#<hostname>

# nix-darwin
darwin-rebuild switch --flake .#<hostname>

# Home Manager only
home-manager switch --flake .#<user>@<hostname>
```

## Related Commands

- `/validate-module` - Check specific module structure
- `/format-project` - Format code before checking
- `/nix/trace-dep` - Debug dependency issues

## Related Documentation

- `docs/DX_GUIDE.md` - Build and validation workflow
- `CONVENTIONS.md` - Common error patterns
