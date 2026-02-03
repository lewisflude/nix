---
description: "Trace module dependencies and imports"
---

# Trace Module Dependencies

Trace and visualize module dependencies to understand import relationships and find issues.

## What This Does

Helps you understand:
- Which modules define which `flake.modules.*`
- How hosts compose features
- Import chains from host definitions
- Potential circular dependencies

## Usage

```
/nix:trace-dep [module-path]
```

**Arguments**:
- `$1` (optional) - Path to specific module to trace
- If omitted, shows overview of all modules

**Examples**:
```
/nix:trace-dep modules/audio.nix
/nix:trace-dep modules/hosts/jupiter/definition.nix
/nix:trace-dep
```

## Dendritic Pattern Context

In the dendritic pattern:
- **Feature modules** define `flake.modules.nixos.*` and `flake.modules.homeManager.*`
- **Host definitions** import features from `config.flake.modules`
- **Infrastructure modules** only transform options to outputs

So "dependencies" means:
1. Which feature modules does a host import?
2. Which `flake.modules.*` does a feature define?
3. Do any modules access the same `config.*` options?

## Available Tools

### 1. Visualize Modules (POG Script)

```bash
nix run .#visualize-modules
```

Generates GraphViz dependency graphs showing:
- Module relationships
- Import structure
- System organization

### 2. Manual Tracing

For a host definition, check its imports:

```nix
# modules/hosts/jupiter/definition.nix
let
  inherit (config.flake.modules) nixos homeManager;
in
{
  configurations.nixos.jupiter.module = {
    imports = [
      nixos.audio      # ← Depends on modules/audio.nix
      nixos.gaming     # ← Depends on modules/gaming.nix
      nixos.shell      # ← Depends on modules/shell.nix
    ];
  };
}
```

### 3. Nix Evaluation Trace

```bash
nix-instantiate --eval --strict --trace-verbose <expression>
```

Shows evaluation order and dependencies.

## Your Task

1. **Identify target module**:
   - Use provided argument or ask which module to trace
   - Validate the module exists

2. **Determine module type**:
   - Is it a host definition? → Trace its imports
   - Is it a feature module? → Check what `flake.modules.*` it defines
   - Is it infrastructure? → Check what options it declares

3. **Trace dependencies**:
   - **For hosts**: List all `nixos.*` and `homeManager.*` imports
   - **For features**: Check if it uses `config.*` from other modules

4. **Report findings**:
   ```
   Module: modules/hosts/jupiter/definition.nix
   Type: Host definition

   NixOS Feature Imports:
   - nixos.base (modules/infrastructure/home-manager.nix)
   - nixos.audio (modules/audio.nix)
   - nixos.gaming (modules/gaming.nix)

   Home-Manager Feature Imports:
   - homeManager.shell (modules/shell.nix)
   - homeManager.git (modules/git.nix)

   Top-Level Config Dependencies:
   - config.username (modules/meta.nix)
   - config.constants (modules/constants.nix)
   ```

## Issue Detection

**Circular dependencies** (rare in dendritic):
- Module A defines option that Module B reads
- Module B defines option that Module A reads

**Missing imports**:
- Host tries to import `nixos.foo` but no module defines it

**Orphaned modules**:
- Feature module exists but no host imports it

## Related Commands

- `/nix:check-build` - Validate builds after dependency changes
- `/validate-module` - Check individual module structure
- `nix run .#visualize-modules` - Generate dependency graphs

## Related Documentation

- `DENDRITIC_SOURCE_OF_TRUTH.md` - Dendritic pattern documentation
- `CLAUDE.md` - AI assistant guidelines
