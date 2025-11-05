# Feature System Duplication Analysis

This document analyzes duplication between the features system and other configuration code in this repository.

## Executive Summary

The features system has **moderate duplication** with other configuration code, primarily in:
1. **Package lists** duplicated between system-level and home-manager feature modules
2. **Development toolchains** duplicated across features, shells, and project-specific configs
3. **Service bridges** that create thin mapping layers (intentional, minimal duplication)

Overall, the features system is well-structured with **intentional separation** between system-level and user-level configuration. Most duplication is:
- **Acceptable**: Platform-specific (system vs home-manager) or context-specific (features vs shells)
- **Minimal**: Service modules are separate from features (features bridge to services)
- **Manageable**: Package lists are similar but serve different purposes

## Duplication Patterns

### 1. Development Feature Duplication (System vs Home-Manager)

**Location:**
- `modules/shared/features/development/default.nix` (system-level)
- `home/common/features/development/default.nix` (home-manager level)

**Duplicated Items:**
- Rust toolchain: `rustc`, `cargo`, `rustfmt`, `clippy`, `rust-analyzer`, `cargo-watch`, `cargo-audit`, `cargo-edit`
- Python toolchain: `python313`, `pip`, `virtualenv`, `uv`, `ruff`, `pyright`, `black`, `poetry`
- Go toolchain: `go`, `gopls`, `gotools`, `golangci-lint`, `delve`
- Node.js toolchain: `nodejs_24`, `npm`, `yarn`, `pnpm`, `typescript`, `typescript-language-server`, `eslint`, `prettier`
- Lua toolchain: `luajit`, `luarocks`, `lua-language-server`, `stylua`, `selene`
- Java toolchain: `jdk`, `gradle`, `maven`
- Docker tools: `docker-client`, `docker-compose`, `docker-credential-helpers`, `lazydocker`
- Build tools: `gnumake`, `cmake`, `pkg-config`, `gcc`, `binutils`, `autoconf`, `automake`, `libtool`
- Git tools: `git`, `git-lfs`, `gh`, `delta`

**Analysis:**
- **Intentional separation**: System-level packages are installed system-wide, home-manager packages are user-specific
- **Some overlap**: Both install similar toolchains, but for different contexts
- **Recommendation**: This is acceptable duplication - they serve different purposes (system vs user)

**Duplication Score: ~70%** (package lists are very similar, but context is different)

### 2. Development Shells vs Features

**Location:**
- `shells/default.nix` (development shells)
- `modules/shared/features/development/default.nix` (feature module)
- `home/common/features/development/default.nix` (home-manager feature)

**Duplicated Items:**
- Rust: `rustc`, `cargo`, `rust-analyzer`, `clippy`, `cargo-watch`, `cargo-edit`, `cargo-audit`
- Python: `python312` (shells) vs `python313` (features), `pip`, `virtualenv`, `ruff`, `black`, `poetry`
- Node.js: `nodejs_24` (shells and features)

**Analysis:**
- **Different purposes**: Shells are for ephemeral dev environments, features are for system/user setup
- **Version differences**: Shells use `python312`, features use `python313` - intentional version pinning
- **Recommendation**: Acceptable - they serve different use cases

**Duplication Score: ~40%** (similar packages but different contexts and some version differences)

### 3. Language Tools Module (Additional Duplication Layer)

**Location:**
- `home/common/features/development/language-tools.nix`

**Duplicated Items:**
- Python tools: `python313`, `pip`, `virtualenv`, `uv`, `ruff`, `pyright` (duplicates home feature)
- Go tools: `go`, `gopls`, `gotools` (duplicates home feature)
- Node.js: `nodejs_24` (duplicates home feature)
- Lua: `luajit`, `luarocks`, `lua-language-server` (duplicates home feature)

**Analysis:**
- **Potential issue**: This module duplicates packages already in `home/common/features/development/default.nix`
- **Comment in code**: Has comments like "duplicates removed - managed by feature flags" but still includes some duplicates
- **Recommendation**: Review and consolidate - this appears to be an intermediate refactoring state

**Duplication Score: ~60%** (significant overlap with home feature module)

### 4. Service Modules vs Features

**Location:**
- `modules/nixos/features/media-management.nix` (bridge module)
- `modules/nixos/services/media-management/qbittorrent.nix` (service module)

**Duplication:**
- **Minimal**: Bridge module just maps feature options to service options
- **No package duplication**: Service modules handle implementation, features handle configuration

**Analysis:**
- **Well-separated**: Features are high-level, services are low-level
- **Bridge pattern**: Thin mapping layer is intentional and doesn't duplicate logic
- **Recommendation**: This is good architecture - no changes needed

**Duplication Score: ~5%** (only option mapping, no logic duplication)

### 5. Virtualisation Feature vs Docker Apps

**Location:**
- `modules/shared/features/virtualisation/default.nix`
- `modules/nixos/features/virtualisation.nix`
- `home/common/apps/docker.nix`

**Duplicated Items:**
- Docker tools: `docker-client`, `docker-compose`, `lazydocker`

**Analysis:**
- **Different contexts**: Features install system-wide, apps install user-level
- **Some overlap**: Both provide Docker tools
- **Recommendation**: Acceptable - different installation contexts

**Duplication Score: ~30%** (limited overlap)

### 6. Example/Template Files

**Location:**
- `modules/examples/development-feature.nix`
- `modules/examples/gaming-feature.nix`

**Duplication:**
- Similar patterns to actual feature modules

**Analysis:**
- **Intentional**: Examples/templates are meant to show patterns
- **Recommendation**: Keep as-is - they're documentation

**Duplication Score: N/A** (documentation, not production code)

## Quantified Duplication Metrics

### Package List Duplication

| Package Category | System Feature | Home Feature | Shells | Other | Total Locations |
|-----------------|----------------|--------------|--------|-------|-----------------|
| Rust toolchain | ✅ | ✅ | ✅ | - | 3 |
| Python toolchain | ✅ | ✅ | ✅ | - | 3 |
| Go toolchain | ✅ | ✅ | - | - | 2 |
| Node.js toolchain | ✅ | ✅ | ✅ | - | 3 |
| Lua toolchain | ✅ | ✅ | - | - | 2 |
| Java toolchain | ✅ | ✅ | - | - | 2 |
| Docker tools | ✅ | ✅ | - | ✅ (apps) | 3 |
| Build tools | ✅ | ✅ | - | - | 2 |
| Git tools | ✅ | ✅ | ✅ | - | 3 |

### File-Level Duplication

- **Rust packages**: Found in 20 files (73 total matches)
- **Python packages**: Found in 10 files (48 total matches)
- **Docker packages**: Found in 13 files (20 total matches)

## Recommendations

### High Priority

1. **Consolidate `language-tools.nix`**
   - Review `home/common/features/development/language-tools.nix`
   - Remove packages that are already in `home/common/features/development/default.nix`
   - Keep only unique packages or refactor to share package lists

### Medium Priority

2. **Extract Shared Package Lists**
   - Create shared package definitions in `lib/` or `modules/shared/lib/`
   - Example: `lib/development-packages.nix` with functions like:
     ```nix
     rustToolchain = [ rustc cargo rustfmt clippy rust-analyzer ... ];
     pythonToolchain = [ python313 pip virtualenv ... ];
     ```
   - Use these in both system and home feature modules

3. **Document Intentional Duplication**
   - Add comments explaining why system vs home-manager duplication exists
   - Document version differences (e.g., python312 in shells vs python313 in features)

### Low Priority

4. **Monitor Shell vs Feature Consistency**
   - Keep an eye on version differences between shells and features
   - Consider if version alignment is needed or if differences are intentional

5. **Consider Feature Option Consolidation**
   - Some features have similar option structures
   - Could create shared option helpers, but may add complexity

## Architecture Assessment

### Strengths

1. **Clear separation**: Features vs services vs shells are well-separated
2. **Bridge pattern**: Feature-to-service bridges are thin and don't duplicate logic
3. **Platform awareness**: System vs home-manager separation is intentional

### Areas for Improvement

1. **Package list DRY**: Extract shared package lists to reduce duplication
2. **Language tools module**: Clean up the intermediate refactoring state
3. **Documentation**: Better document why duplication exists where it does

## Conclusion

The features system has **moderate, mostly intentional duplication**:
- **~70% duplication** between system and home-manager development features (acceptable - different contexts)
- **~40% duplication** between shells and features (acceptable - different purposes)
- **~60% duplication** in language-tools.nix (needs cleanup)
- **~5% duplication** in service bridges (excellent - intentional thin layer)

**Overall Assessment**: The duplication is manageable and mostly serves valid architectural purposes. The main cleanup opportunity is consolidating the `language-tools.nix` module.

**Estimated Reduction Potential**: If fully consolidated, could reduce duplication by ~15-20% while maintaining clear separation of concerns.

