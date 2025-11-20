# Code Review Remediation Plan

**Generated**: 2025-11-13
**Status**: Active
**Estimated Total Effort**: ~12-16 hours

This document outlines a comprehensive plan to address architectural issues, antipatterns, and code quality concerns identified in the codebase review.

---

## Table of Contents

1. [Critical Issues (P0)](#critical-issues-p0) - Fix Immediately
2. [High Priority (P1)](#high-priority-p1) - Fix This Week
3. [Medium Priority (P2)](#medium-priority-p2) - Fix This Month
4. [Low Priority (P3)](#low-priority-p3) - Ongoing Improvements
5. [Documentation Updates](#documentation-updates)
6. [Validation & Testing](#validation--testing)

---

## Critical Issues (P0)

**Timeline**: Fix immediately (1-2 hours)
**Impact**: System correctness, duplication, wasted resources

### Task 1.1: Delete `home/nixos/system/podman.nix`

**File**: `home/nixos/system/podman.nix`
**Action**: DELETE entire file

**Rationale**:

- Podman is already properly configured at system-level in `modules/nixos/features/virtualisation.nix:28-32`
- Container tools require system privileges and should never be user packages
- The conditional check is fragile and accessing system config incorrectly

**Steps**:

1. Delete `home/nixos/system/podman.nix`
2. Remove import from `home/nixos/system/default.nix:11`
3. Verify podman still works: `podman --version`
4. Check that system-level podman config is active: `systemctl status podman.socket`

**Verification**:

```bash
# Podman should work via system config only
podman ps
podman-compose --version
```

---

### Task 1.2: Delete `home/nixos/system/graphics.nix`

**File**: `home/nixos/system/graphics.nix`
**Action**: DELETE entire file

**Rationale**:

- 100% duplication of packages already in `modules/nixos/features/desktop/graphics.nix:43-68`
- System graphics libraries should not be in home-manager
- Wastes ~200MB+ of build time and disk space

**Steps**:

1. Delete `home/nixos/system/graphics.nix`
2. Remove import from `home/nixos/system/default.nix:10`
3. Verify graphics tools still available: `vulkan-tools`, `vainfo`, `glxinfo`

**Verification**:

```bash
# All these should still work via system packages
vulkaninfo
vainfo
glxinfo
eglinfo
```

---

### Task 1.3: Remove Hardcoded Timezone

**File**: `modules/nixos/features/desktop/desktop-environment.nix:13`
**Action**: DELETE line 13

**Current Code**:

```nix
time.timeZone = "Europe/London";
```

**Rationale**:

- Timezone should be per-host configuration, not feature-level
- Already properly configured in `hosts/jupiter/default.nix` (implicitly via system defaults)
- Creates inflexibility for multi-timezone setups

**Steps**:

1. Remove line 13 from `modules/nixos/features/desktop/desktop-environment.nix`
2. Verify timezone is set in host configs or system defaults
3. For multi-host setups, ensure each host explicitly sets timezone

**Verification**:

```bash
timedatectl
# Should show: Time zone: Europe/London (GMT, +0000)
```

---

### Task 1.4: Fix SOPS Owner Conditional

**File**: `modules/shared/sops.nix:29`
**Action**: Simplify redundant conditional

**Current Code**:

```nix
resolvedOwner = if isDarwin then config.host.username else config.host.username;
```

**Fixed Code**:

```nix
resolvedOwner = config.host.username;
```

**Rationale**:

- Both branches are identical
- Confusing and suggests there was intended platform difference
- Simplifies code

---

## High Priority (P1)

**Timeline**: This week (3-5 hours)
**Impact**: Code maintainability, duplication, architecture

### Task 2.1: Refactor MCP Configuration to Reduce Duplication

**Files**:

- `home/nixos/mcp.nix` (256 lines)
- `home/darwin/mcp.nix` (148 lines)
- `home/common/modules/mcp.nix` (167 lines)

**Problem**:

- Registration script logic duplicated
- Platform differences minimal (mostly port numbers)
- Difficult to maintain consistency

**Approach**:

#### 2.1.1: Create Shared Registration Script

**New File**: `home/common/lib/mcp-registration.nix`

Extract common registration logic:

```nix
{ lib, pkgs }:
{
  mkRegistrationScript = {
    servers,
    timeout ? "60000",
    dryRun ? false,
  }:
    pkgs.writeShellScript "mcp-register" ''
      # Common registration logic here
      # Platform-agnostic script generation
    '';
}
```

#### 2.1.2: Update Platform-Specific Files

**`home/nixos/mcp.nix`**:

- Import shared registration helper
- Only define NixOS-specific overrides (ports, wrappers)
- Reduce to ~100 lines

**`home/darwin/mcp.nix`**:

- Import shared registration helper
- Only define Darwin-specific overrides (Docker github, file-based wrappers)
- Reduce to ~60 lines

**Expected Savings**: ~200 lines of duplicated code

---

### Task 2.2: Rename `home/nixos/system/` Directory

**Current**: `home/nixos/system/`
**Proposed**: `home/nixos/hardware-tools/`

**Rationale**:

- Name "system" implies system-level config but it's in home-manager
- Actually contains user-level tools for hardware/system interaction
- Causes conceptual confusion

**Steps**:

1. Rename directory: `git mv home/nixos/system home/nixos/hardware-tools`
2. Update all imports in `home/nixos/default.nix:4`
3. Update any documentation references
4. Commit with message: `refactor: rename home/nixos/system to hardware-tools for clarity`

**Files to update**:

- `home/nixos/default.nix:4` - import path
- Any documentation mentioning this path

---

### Task 2.3: Fix Parameter Passing Antipattern

**Files**:

- `home/common/apps/docker.nix:3-6`

**Current Code**:

```nix
{
  pkgs,
  lib,
  system,
  virtualisation ? { },
  ...
}:
```

**Problem**:

- Attempting to pass module system config as function parameter with default
- Should use `config.virtualisation` inside the module
- Not how NixOS/home-manager module system works

**Fixed Approach**:

```nix
{
  pkgs,
  lib,
  config,
  system,
  ...
}:
let
  platformLib = (import ../../../lib/functions.nix { inherit lib; }).withSystem system;
  dockerEnabled = config.host.features.virtualisation.docker or false;
  linuxPackages = ...
in
```

**Note**: This requires that `virtualisation` config is properly exposed through the module system.

---

### Task 2.4: Improve `lib/functions.nix` Platform Detection

**File**: `lib/functions.nix:4-6`

**Current Code**:

```nix
isLinux = system: lib.hasInfix "linux" system;
isDarwin = system: lib.hasInfix "darwin" system;
```

**Problem**:

- `hasInfix` could match unintended strings (e.g., "notlinux-something")
- Less precise than suffix matching

**Improved Code**:

```nix
isLinux = system: lib.hasSuffix "-linux" system || system == "linux";
isDarwin = system: lib.hasSuffix "-darwin" system || system == "darwin";
```

**Rationale**:

- More precise matching
- Handles both "x86_64-linux" and "linux" formats
- Prevents false positives

---

### Task 2.5: Add Explicit Feature Flag Checks

**Files**: Various home-manager modules that should respect feature flags

**Current Issue**:
Some modules unconditionally install packages without checking feature flags.

**Examples to Review**:

- `home/nixos/desktop-apps.nix` - should check `config.host.features.desktop.enable`
- `home/common/apps/packages.nix` - review if conditional logic needed
- `home/darwin/apps.nix` - unconditional packages

**Pattern to Apply**:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.host.features.desktop;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ ... ];
  };
}
```

**Action Items**:

1. Audit all `home/*/apps/*.nix` files
2. Add feature flag checks where appropriate
3. Document which packages are "always installed" vs conditional

---

## Medium Priority (P2)

**Timeline**: This month (4-6 hours)
**Impact**: Code quality, maintainability

### Task 3.1: Migrate Away from `with pkgs;` Pattern

**Scope**: 80+ occurrences across codebase

**Strategy**: Gradual migration, prioritize high-traffic files

**Phase 1 - High Priority Files** (1-2 hours):

- `home/common/apps/*.nix` - Core applications
- `home/nixos/system/*.nix` - Hardware tools
- `modules/shared/features/*.nix` - Feature modules

**Phase 2 - Medium Priority** (1-2 hours):

- `modules/nixos/features/*.nix`
- `modules/darwin/*.nix`

**Phase 3 - Low Priority** (ongoing):

- Legacy/stable modules that rarely change

**Before**:

```nix
home.packages = with pkgs; [
  vulkan-tools
  mesa-demos
  libva
];
```

**After**:

```nix
home.packages = [
  pkgs.vulkan-tools
  pkgs.mesa-demos
  pkgs.libva
];
```

**Exception**: Keep `with pkgs;` for very long package lists (10+ items) where noise reduction has value.

---

### Task 3.2: Flatten Profile Import Hierarchy

**Files**:

- `home/common/default.nix`
- `home/common/profiles/full.nix`
- `home/common/profiles/base.nix`
- `home/common/profiles/optional.nix`

**Current Structure**:

```
home/common/default.nix
  └─ imports profiles/full.nix
       ├─ imports base.nix
       └─ imports optional.nix
```

**Problem**:

- Extra indirection with minimal value
- `default.nix` just imports one file
- Could be simpler

**Proposed Structure** (Option A - Flatten):

```
home/common/default.nix
  ├─ imports profiles/base.nix (core tools)
  └─ imports profiles/optional.nix (extra features)
```

**Proposed Structure** (Option B - Eliminate Profiles):

```
home/common/default.nix
  ├─ imports shell.nix
  ├─ imports git.nix
  ├─ imports apps/...
  └─ imports features/...
```

**Decision Point**: Evaluate if profile abstraction adds value for your workflow.

**Implementation**:

1. Review with team/users if profiles are actually used differently
2. If profiles are always identical: Option B (eliminate)
3. If profiles provide value: Option A (flatten one level)

---

### Task 3.3: Extract Magic Numbers to Constants

**Pattern**: Hardcoded ports, timeouts, sizes scattered throughout

**Examples**:

- `home/nixos/mcp.nix:145` - port 6280
- Various timeout values
- Service ports in `modules/nixos/services/`

**Action**:
Create `lib/constants.nix`:

```nix
{
  ports = {
    mcp = {
      github = 6230;
      kagi = 6240;
      openai = 6250;
      docs = 6280;
      rustdocs = 6270;
      time-nixos = 6262;
      time-darwin = 6263;
      sequential-thinking-nixos = 6281;
      sequential-thinking-darwin = 6282;
    };
    services = {
      restic = 8000;
      ollama = 11434;
      openWebui = 7000;
      # ... etc
    };
  };

  timeouts = {
    mcp = {
      registration = "60000";
      warmup = "900";
    };
  };
}
```

**Usage**:

```nix
let
  constants = import ../../../lib/constants.nix;
in
{
  port = constants.ports.mcp.kagi;
}
```

---

### Task 3.4: Add Validation Functions

**File**: New file `lib/validators.nix`

**Purpose**: Centralize common validation patterns

**Content**:

```nix
{ lib }:
{
  # Validate port is in valid range
  isValidPort = port: port >= 1 && port <= 65535;

  # Validate path exists
  pathExists = path: builtins.pathExists (toString path);

  # Validate username format
  isValidUsername = name: builtins.match "[a-z_][a-z0-9_-]*" name != null;

  # Validate email format
  isValidEmail = email: builtins.match ".*@.*\\..*" email != null;

  # Create assertion helper
  mkAssertion = condition: message: {
    assertion = condition;
    inherit message;
  };
}
```

**Usage in Modules**:

```nix
let
  validators = import ../../lib/validators.nix { inherit lib; };
in
{
  assertions = [
    (validators.mkAssertion
      (validators.isValidPort cfg.port)
      "Invalid port: ${toString cfg.port}")
  ];
}
```

---

### Task 3.5: Standardize Error Messages

**Current Issue**: Inconsistent error message formats

**Examples**:

- Some use "ERROR: ..."
- Some use "[component] message"
- Some use bare messages

**Standard Format**:

```nix
assertions = [
  {
    assertion = condition;
    message = ''
      [MODULE_NAME] Error description

      Expected: what should be true
      Got: what was actually found
      Solution: how to fix
    '';
  }
];
```

**Action**: Create style guide and update existing assertions

---

## Low Priority (P3)

**Timeline**: Ongoing (2-3 hours spread over time)
**Impact**: Polish, consistency

### Task 4.1: Add Module Documentation Headers

**Pattern**: Standardize module documentation

**Template**:

```nix
# Module: <name>
# Purpose: <one-line description>
# Platform: nixos | darwin | home | shared
# Dependencies: <key dependencies>
# Configuration: config.host.<path>
#
# Example:
#   config.host.features.desktop.enable = true;

{ config, lib, pkgs, ... }:
# ... module code
```

**Action**: Add to all modules in phases

---

### Task 4.2: Extract Repeated Package Lists

**Pattern**: Same packages defined in multiple places

**Example - Audio Production Tools**:

```nix
# modules/nixos/features/audio.nix
# modules/shared/features/media/audio.nix
# Likely some overlap
```

**Action**:

1. Identify common package groups
2. Extract to `lib/package-sets.nix` (already exists, enhance)
3. Reference from modules

---

### Task 4.3: Add Type Annotations

**Current**: Most options have types, but some helpers don't

**Action**: Ensure all custom functions have type documentation

**Example**:

```nix
# Type: String -> Bool
isLinux = system: lib.hasSuffix "-linux" system;

# Type: String -> String -> [String]
platformPackages = system: linuxPkgs: darwinPkgs: ...;
```

---

### Task 4.4: Create Module Testing Framework

**New File**: `tests/modules/README.md`

**Purpose**: Document how to test module changes

**Content**:

- How to test NixOS modules: `nixos-rebuild build-vm`
- How to test home-manager: `home-manager build`
- Quick validation commands
- Common test scenarios

**Create Example Tests**:

```nix
# tests/modules/desktop-test.nix
{
  name = "desktop-module-test";
  nodes.machine = {
    host.features.desktop.enable = true;
  };
  testScript = ''
    machine.wait_for_unit("greetd.service")
    machine.succeed("niri --version")
  '';
}
```

---

### Task 4.5: Optimize Import Statements

**Pattern**: Sort and organize imports consistently

**Standard Order**:

1. Feature modules (highest level)
2. Service modules
3. Hardware modules
4. Application modules
5. Configuration files

**Example**:

```nix
{
  imports = [
    # Features
    ../features/desktop
    ../features/gaming

    # Services
    ../services/media-management

    # Hardware
    ../hardware/nvidia

    # Apps
    ./apps/browser.nix
    ./apps/terminal.nix
  ];
}
```

---

## Documentation Updates

### Task 5.1: Update Architecture Documentation

**File**: `docs/reference/architecture.md`

**Add Section**: "Home-Manager vs System Configuration"

**Content**:

```markdown
## Home-Manager vs System Configuration Guidelines

### System-Level (NixOS/nix-darwin)
- System services (systemd, launchd)
- Kernel modules and drivers
- System-wide daemons
- Hardware configuration
- Boot configuration
- System users and groups
- Container runtimes (Docker, Podman)
- Graphics drivers
- Network configuration

### Home-Manager Level
- User applications
- User services (systemd --user)
- User configuration files
- Development tools
- Desktop applications
- User-level tray applets
- Terminal tools
- Editor configurations

### Gray Areas (Context Dependent)
- GPG/SSH: System for key storage, Home for user config
- Audio: System for PipeWire/PulseAudio, Home for user mixers
- Containers: System for runtime, Home for CLI tools (carefully)
```

---

### Task 5.2: Update CLAUDE.md

**File**: `CLAUDE.md`

**Add Section**: "Module Placement Guidelines"

**Content**:

```markdown
## Module Placement Guidelines

When creating or modifying modules, follow these rules:

1. **System Services**: `modules/nixos/services/` or `modules/darwin/`
2. **User Applications**: `home/common/apps/` or `home/{nixos,darwin}/apps/`
3. **Features**: `modules/shared/features/` or `modules/nixos/features/`
4. **Hardware**: `modules/nixos/hardware/`

### Quick Checklist

Does it require root privileges? → System module
Does it run as a system service? → System module
Is it a user application? → Home-Manager module
Does it configure dotfiles? → Home-Manager module
Is it a tray applet? → Home-Manager module
```

---

### Task 5.3: Create Troubleshooting Guide

**New File**: `docs/TROUBLESHOOTING.md`

**Sections**:

1. Package not found after rebuild
2. Service not starting
3. Home-Manager activation fails
4. Secret not accessible
5. Graphics issues
6. MCP registration problems

---

## Validation & Testing

### Task 6.1: Create Pre-Commit Validation Script

**New File**: `scripts/validate-config.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Validating Nix configuration..."

# Check for antipatterns
echo "Checking for boundary violations..."
if grep -r "home.packages.*podman" home/; then
  echo "❌ ERROR: Podman found in home-manager"
  exit 1
fi

# Check for duplicates
echo "Checking for package duplication..."
# Add logic to detect duplicates

# Validate flake
echo "Checking flake structure..."
nix flake check --no-build

echo "✅ Validation complete"
```

---

### Task 6.2: Build Matrix Test

**Create**: `.github/workflows/build-test.yml` or equivalent

**Test Matrix**:

- NixOS build (jupiter host)
- Darwin build (MacBook host)
- Home-Manager standalone

---

### Task 6.3: Create Rollback Plan

**Document**: `docs/ROLLBACK.md`

**Content**:

- How to rollback NixOS: `sudo nixos-rebuild switch --rollback`
- How to rollback home-manager: `home-manager generations`
- How to access previous generation
- Common failure scenarios and recovery

---

## Implementation Roadmap

### Week 1: Critical Fixes

- [ ] Task 1.1: Delete podman.nix
- [ ] Task 1.2: Delete graphics.nix
- [ ] Task 1.3: Remove hardcoded timezone
- [ ] Task 1.4: Fix SOPS owner conditional
- [ ] Task 6.1: Create validation script
- [ ] Task 5.2: Update CLAUDE.md

**Estimated**: 2-3 hours

### Week 2: High Priority

- [ ] Task 2.1: Refactor MCP configuration
- [ ] Task 2.2: Rename system directory
- [ ] Task 2.3: Fix parameter passing
- [ ] Task 2.4: Improve platform detection
- [ ] Task 5.1: Update architecture docs

**Estimated**: 4-5 hours

### Week 3-4: Medium Priority

- [ ] Task 3.1: Migrate from `with pkgs;` (Phase 1)
- [ ] Task 3.2: Flatten profile hierarchy
- [ ] Task 3.3: Extract constants
- [ ] Task 3.4: Add validators
- [ ] Task 3.5: Standardize errors

**Estimated**: 5-6 hours

### Ongoing: Low Priority

- [ ] Task 4.1-4.5: Polish and documentation
- [ ] Task 3.1: Continue `with pkgs;` migration (Phase 2-3)

**Estimated**: 2-3 hours over several weeks

---

## Success Metrics

### Quantitative

- [ ] **0** boundary violations (home-manager installing system packages)
- [ ] **<50** uses of `with pkgs;` (down from 80+)
- [ ] **0** hardcoded values (all in constants)
- [ ] **100%** modules have documentation headers
- [ ] **<5min** rebuild time improvement (from reduced duplication)

### Qualitative

- [ ] Clear separation of concerns
- [ ] Consistent code style
- [ ] Easy to onboard new contributors
- [ ] Self-documenting configuration
- [ ] Predictable module behavior

---

## Notes

- This plan is living document - adjust as needed
- Some tasks may reveal additional issues
- Prioritize correctness over completion speed
- Test each change before moving to next task
- Create git commits for each major task

---

## Questions for Discussion

1. **Profile Structure**: Do you use different profiles for different machines/users? If not, we should flatten.
2. **MCP Refactoring**: Are you open to larger structural changes or prefer minimal changes?
3. **Migration Strategy**: Big bang refactor or gradual migration?
4. **Testing**: Do you want automated tests or manual validation?

---

**Last Updated**: 2025-11-13
**Next Review**: After Week 1 completion
