---
description: "Trace module dependencies and imports"
---

# Trace Module Dependencies

Trace and visualize module dependencies to understand import relationships and find circular dependencies.

## What This Does

Helps you understand:
- Which modules import which other modules
- Dependency chains
- Circular dependencies (if any)
- Module organization

## Usage

```
/nix/trace-dep [module-path]
```

**Arguments**:
- `$1` (optional) - Path to specific module to trace
- If omitted, shows overview of all modules

**Examples**:
```
/nix/trace-dep modules/nixos/features/gaming.nix
/nix/trace-dep home/common/apps/git.nix
/nix/trace-dep
```

## Available Tools

### 1. Visualize Modules (POG Script)

```bash
nix run .#visualize-modules
```

This generates GraphViz dependency graphs showing:
- Module relationships
- Import structure
- System organization

### 2. Manual Tracing

Read modules and follow their `imports` attributes.

### 3. Nix Evaluation Trace

```bash
nix-instantiate --eval --strict --trace-verbose <expression>
```

Shows evaluation order and dependencies.

## Your Task

1. **Identify target module**:
   - Use provided argument or ask which module to trace
   - Validate the module exists

2. **Trace dependencies**:
   - **Option A**: Run `nix run .#visualize-modules` for visual graph
   - **Option B**: Read module and recursively follow imports

3. **Analyze imports**:
   - List direct dependencies
   - Identify transitive dependencies
   - Check for circular imports

4. **Check for issues**:
   - Circular dependencies
   - Unnecessary imports
   - Missing imports
   - Organization problems

5. **Report findings**:
   ```
   Module: modules/nixos/features/gaming.nix

   Direct Imports:
   - modules/nixos/features/desktop/graphics.nix
   - modules/nixos/features/audio.nix

   Transitive Dependencies:
   - modules/nixos/hardware/gpu.nix (via graphics.nix)
   - modules/shared/features/common.nix (via audio.nix)

   Dependency Depth: 3 levels
   Circular Dependencies: None detected

   Organization: ✅ Well-organized
   ```

## Circular Dependency Detection

If circular dependencies are found:

1. **Identify the cycle**:
   ```
   A imports B
   B imports C
   C imports A  <- CYCLE
   ```

2. **Suggest fix**:
   - Extract common parts to shared module
   - Remove unnecessary import
   - Restructure module organization

## Use Cases

**Understanding module structure**:
- New to the codebase
- Planning refactoring
- Debugging import errors

**Finding circular dependencies**:
- Build errors mentioning infinite recursion
- Evaluation errors

**Refactoring**:
- Before moving modules
- When consolidating features
- Optimizing import graph

## Visualization Output

The `visualize-modules` POG script creates `.dot` and `.svg` files showing:
- Nodes = Modules
- Edges = Import relationships
- Colors = Module types (system/home/shared)

## Related Commands

- `/nix/check-build` - Validate builds after dependency changes
- `/validate-module` - Check individual module structure
- `nix run .#visualize-modules` - Generate dependency graphs

## Related Documentation

- `docs/reference/architecture.md` - Module organization principles
- `docs/FEATURES.md` - Feature module patterns
- `CONVENTIONS.md` - Import best practices
