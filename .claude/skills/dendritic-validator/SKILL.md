---
name: "dendritic-validator"
description: "Comprehensive validation of dendritic pattern compliance across all Nix modules. Validates structure, scope usage, anti-patterns, and module placement. Use after making changes, before commits, or when reviewing code."
disable-model-invocation: false
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob, Bash
---

# Dendritic Pattern Validator

Perform comprehensive architectural validation of Nix modules against the dendritic pattern.

## Validation Context

Files to validate: **$ARGUMENTS** (or all modified files if not specified)

**CRITICAL**: Read `DENDRITIC_SOURCE_OF_TRUTH.md` first to understand the complete dendritic pattern.

## Validation Process

### Phase 1: Discovery

1. **Identify target files**:
   - If $ARGUMENTS provided: validate those specific files
   - Otherwise: validate all `.nix` files under `modules/` modified in current branch
   - Use: `git diff --name-only main...HEAD | grep '^modules/.*\.nix$'`

2. **Categorize files**:
   - Infrastructure modules (`modules/infrastructure/*.nix`)
   - Feature modules (define `flake.modules.*`)
   - Host definitions (`modules/hosts/*/definition.nix`)
   - Option declarations (`modules/constants.nix`, `modules/meta.nix`, etc.)

### Phase 2: Structural Validation

For each file, validate:

#### Infrastructure Modules (`modules/infrastructure/*.nix`)

**Expected structure**:
```nix
{ lib, config, inputs, ... }:
{
  # 1. DECLARE OPTIONS
  options.configurations.<platform> = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.submodule {
      options.module = lib.mkOption {
        type = lib.types.deferredModule;  # CRITICAL
      };
    });
  };

  # 2. TRANSFORM TO OUTPUTS
  config.flake.<platform>Configurations = lib.mapAttrs
    (name: { module }: inputs.<platform-lib>.nixosSystem { modules = [ module ]; })
    config.configurations.<platform>;
}
```

**Check**:
- ✅ Uses `deferredModule` type (critical for merging)
- ✅ Only transforms options to outputs
- ❌ Does NOT import feature modules
- ❌ Does NOT contain configuration logic

**Reference**: DENDRITIC_SOURCE_OF_TRUTH.md lines 208-278

#### Feature Modules (most files under `modules/`)

**Expected structure**:
```nix
{ config, ... }:
let
  constants = config.constants;  # Access top-level config
in
{
  # Define platform modules
  flake.modules.nixos.myFeature = { pkgs, ... }: {
    # NixOS configuration
  };

  flake.modules.homeManager.myFeature = { pkgs, ... }: {
    # Home-manager configuration
  };
}
```

**Check**:
- ✅ Is a flake-parts module (`{ config, ... }:`)
- ✅ Defines `flake.modules.<platform>.<name>`
- ✅ Accesses constants via `config.constants`
- ✅ Proper scope (top-level vs platform-level)
- ❌ No `with pkgs;`
- ❌ No `specialArgs`
- ❌ No direct constant imports

**Reference**: DENDRITIC_SOURCE_OF_TRUTH.md lines 280-348

#### Host Definitions (`modules/hosts/*/definition.nix`)

**Expected structure**:
```nix
{ config, inputs, ... }:
let
  inherit (config.flake.modules) nixos homeManager;
in
{
  configurations.nixos.hostname.module = {
    imports = [
      # External input modules
      inputs.home-manager.nixosModules.home-manager

      # Feature modules
      nixos.base
      nixos.myFeature
    ];

    # Host-specific configuration
    nixpkgs.hostPlatform = "x86_64-linux";
    networking.hostName = "hostname";
  };
}
```

**Check**:
- ✅ Sets `configurations.<platform>.<hostname>.module`
- ✅ Imports from `config.flake.modules`
- ✅ Imports external modules at host level
- ❌ Does NOT define feature modules here

**Reference**: DENDRITIC_SOURCE_OF_TRUTH.md lines 350-401, 877-933

### Phase 3: Anti-Pattern Detection

Scan all files for these anti-patterns:

#### 1. `with pkgs;` Usage
```nix
# ❌ ANTI-PATTERN
home.packages = with pkgs; [ curl wget ];

# ✅ CORRECT
home.packages = [ pkgs.curl pkgs.wget ];
```
**Reference**: DENDRITIC_SOURCE_OF_TRUTH.md lines 1020-1026

#### 2. `specialArgs` / `extraSpecialArgs`
```nix
# ❌ ANTI-PATTERN
lib.nixosSystem {
  specialArgs = { inherit inputs; };
}

# ✅ CORRECT
{ config, inputs, ... }:  # Access from outer scope
```
**Reference**: DENDRITIC_SOURCE_OF_TRUTH.md lines 477-527, 1000-1010

#### 3. Direct Constant Imports
```nix
# ❌ ANTI-PATTERN
let constants = import ../lib/constants.nix; in

# ✅ CORRECT
{ config, ... }:
let constants = config.constants; in
```
**Reference**: DENDRITIC_SOURCE_OF_TRUTH.md lines 723-766, 1028-1035

#### 4. Config Scope Confusion
```nix
# ❌ ANTI-PATTERN (shadowing)
{ config, ... }:
{
  flake.modules.nixos.shell = { config, pkgs, ... }: {
    users.users.${config.username}.shell = pkgs.fish;  # config is NixOS!
  };
}

# ✅ CORRECT (named parameter)
{ config, ... }:
{
  flake.modules.nixos.shell = nixosArgs: {
    users.users.${config.username}.shell = nixosArgs.config.programs.fish.package;
  };
}
```
**Reference**: DENDRITIC_SOURCE_OF_TRUTH.md lines 306-341, 1103-1126

#### 5. Infrastructure Importing Features
```nix
# ❌ ANTI-PATTERN (in infrastructure/nixos.nix)
lib.nixosSystem {
  modules = [ module nixos.base ];  # Infrastructure shouldn't import!
}

# ✅ CORRECT (in hosts/jupiter/definition.nix)
configurations.nixos.jupiter.module = {
  imports = [ nixos.base ];  # Host imports features
};
```
**Reference**: DENDRITIC_SOURCE_OF_TRUTH.md lines 1128-1154

### Phase 4: Module Placement Validation

Verify correct system vs home-manager placement:

**System-level** (`flake.modules.nixos.*` or `flake.modules.darwin.*`):
- System services (systemd, launchd)
- Kernel modules and drivers
- Hardware configuration
- Boot configuration
- System daemons (root processes)
- Container runtimes

**Home-manager** (`flake.modules.homeManager.*`):
- User applications and CLI tools
- User services (systemd --user)
- Dotfiles and user configuration
- Development tools (LSPs, formatters)
- User tray applets
- Shell configuration

**Check**: Are packages/services in the right layer?

**Reference**: CLAUDE.md lines 164-207

### Phase 5: Cross-Reference Validation

Check module relationships:

1. **Constants access**:
   - All feature modules should access constants via `config.constants`
   - No direct imports of `lib/constants.nix`

2. **Module composition**:
   - Feature modules define `flake.modules.*`
   - Hosts compose features via `imports`
   - Infrastructure only transforms options

3. **Dependencies**:
   - Module imports happen at host level
   - No circular dependencies
   - External inputs imported at host level

## Validation Report Format

Generate a comprehensive report:

```markdown
# Dendritic Pattern Validation Report

## Summary
- **Files validated**: N
- **✅ Compliant**: N
- **⚠️ Warnings**: N
- **❌ Violations**: N

## Details

### ✅ Compliant Modules
- `modules/audio.nix` - Proper flake-parts module with cross-platform features
- `modules/infrastructure/nixos.nix` - Correct infrastructure pattern

### ⚠️ Warnings
- `modules/gaming.nix:42` - Consider splitting large module into separate files

### ❌ Critical Violations

#### modules/shell.nix
**Line 15**: Config scope confusion
```nix
flake.modules.nixos.shell = { config, pkgs, ... }: {
  users.users.${config.username}.shell = pkgs.fish;  # ❌ shadows outer config
}
```
**Fix**:
```nix
flake.modules.nixos.shell = nixosArgs: {
  users.users.${config.username}.shell = nixosArgs.pkgs.fish;
}
```
**Reference**: DENDRITIC_SOURCE_OF_TRUTH.md line 306-341

#### modules/desktop/theme.nix
**Line 28**: Anti-pattern 'with pkgs;'
```nix
home.packages = with pkgs; [ gnome-themes ];  # ❌
```
**Fix**:
```nix
home.packages = [ pkgs.gnome-themes ];  # ✅
```
**Reference**: DENDRITIC_SOURCE_OF_TRUTH.md line 1020-1026

## Recommendations

1. **High Priority**: Fix all ❌ violations before committing
2. **Medium Priority**: Address ⚠️ warnings in next refactoring session
3. **Suggested Reading**: Review DENDRITIC_SOURCE_OF_TRUTH.md sections referenced above

## Commands to Run

```bash
# Fix the violations
$EDITOR modules/shell.nix modules/desktop/theme.nix

# Validate syntax
nix flake check --no-build

# Run feature-validator skill again
/feature-validator modules/shell.nix modules/desktop/theme.nix
```
```

## Tool Usage Guidelines

- **Use Read**: Read files to analyze structure
- **Use Grep**: Search for anti-patterns across codebase
- **Use Glob**: Find all modules matching patterns
- **Use Bash**: Run git commands to find modified files

## Exit Criteria

Validation is complete when:
1. All target files have been analyzed
2. All 5 validation phases completed
3. Comprehensive report generated with:
   - Specific line numbers for issues
   - Code snippets showing violations
   - Suggested fixes
   - References to documentation

## Related Documentation

- **`DENDRITIC_SOURCE_OF_TRUTH.md`** - Complete pattern documentation (READ THIS FIRST)
- **`CLAUDE.md`** - Repository guidelines and conventions
- **Canonical dendritic**: https://github.com/mightyiam/dendritic
- **Flake Parts**: https://flake.parts
