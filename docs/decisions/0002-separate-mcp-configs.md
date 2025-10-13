# ADR-0002: Keep Separate MCP Platform Configurations

**Date:** 2025-01-14  
**Status:** Accepted  
**Deciders:** Lewis Flude  
**Technical Story:** Phase 1 Architecture Improvements - MCP Configuration Evaluation

## Context

Model Context Protocol (MCP) configurations exist in three locations:

1. `home/common/modules/mcp.nix` - Module definition (options, types)
2. `home/darwin/mcp.nix` - Darwin implementation
3. `home/nixos/mcp.nix` - NixOS implementation

During Phase 1 consolidation efforts, we evaluated whether to merge these into a single file with conditional logic.

### Darwin Implementation
- Simple `claude mcp add` commands
- Basic activation script
- Minimal environment setup
- ~150 lines

### NixOS Implementation  
- Advanced wrapper scripts for secrets management
- Systemd services for registration and warm-up
- Complex environment setup (Rust docs, OpenAI, etc.)
- Build-time optimizations and caching
- Pre-fetching and package warming
- ~300 lines

## Decision

**Keep separate platform-specific implementations.**

The module definition remains shared in `home/common/modules/mcp.nix`, but platform implementations stay separated in `home/darwin/mcp.nix` and `home/nixos/mcp.nix`.

## Consequences

### Positive

- **Clarity**: Each implementation is focused and clear
- **Maintainability**: Easier to modify platform-specific behavior
- **Simplicity**: No complex conditional logic
- **Platform Optimization**: Can optimize for each platform independently
- **Debugging**: Easier to debug platform-specific issues
- **Readability**: Each file is understandable on its own

### Negative

- **Some Duplication**: Server definitions repeated (but with different configs)
- **Update Overhead**: Changes to common servers need platform-specific updates
- **More Files**: Three files instead of one

### Neutral

- **File Count**: More files, but better organized
- **Import Overhead**: Need to import platform-specific module

## Alternatives Considered

### Alternative 1: Merge into Single File with Conditionals
```nix
{lib, pkgs, config, system, ...}: {
  config = lib.mkMerge [
    (lib.mkIf (isLinux system) {
      # 300 lines of Linux-specific config
    })
    (lib.mkIf (isDarwin system) {
      # 150 lines of Darwin-specific config
    })
  ];
}
```

**Rejected because:**
- Creates 450+ line file with deeply nested conditionals
- Hard to read and understand
- Difficult to maintain (changes affect both platforms)
- Complex control flow
- Mental overhead of tracking which code runs where

### Alternative 2: Extract Common Servers to Shared Config
```nix
# common/mcp-servers.nix
{
  servers = {
    kagi = {...};
    github = {...};
    # ...
  };
}
```

**Rejected because:**
- Server configurations are platform-specific (paths, wrappers, env vars)
- False sense of sharing (would still need platform overrides)
- Adds complexity without meaningful benefit
- Server definitions are not truly "common"

### Alternative 3: Use NixOS Modules System for Platform Detection
**Rejected because:**
- Over-engineering for this use case
- Adds unnecessary abstraction
- Doesn't solve the fundamental issue: implementations are different

## Rationale

Platform-specific modules are justified when:

1. ✅ **Implementations are fundamentally different**
   - Darwin: Simple command-line registration
   - NixOS: Systemd services, wrappers, warm-up

2. ✅ **Each platform has unique features**
   - Darwin: Uses `claude` CLI directly
   - NixOS: Custom wrapper scripts, environment setup

3. ✅ **Merging increases complexity more than it reduces**
   - Single file would be 450+ lines with complex conditionals
   - Separate files: 150 + 300 = 450 lines, but much clearer

4. ✅ **Platform-specific optimizations are important**
   - NixOS: Pre-fetching, caching, systemd integration
   - Darwin: Simplicity, direct CLI usage

## Best Practice Established

**Guideline:** Separate platform implementations when:
- Implementation approaches differ significantly (>50% different)
- Each platform has unique features or requirements
- Merging would create complex conditional logic
- Separate files improve readability and maintainability

**Counter-example:** Don't separate when:
- Only minor differences (can use simple conditionals)
- Logic is mostly shared with small platform variations
- Separation would cause significant duplication

## References

- [Phase 1 Documentation](../ARCHITECTURE-IMPROVEMENTS.md#mcp-configuration-architecture-decision)
- [MCP Module Definition](../../home/common/modules/mcp.nix)
- [Darwin MCP Implementation](../../home/darwin/mcp.nix)
- [NixOS MCP Implementation](../../home/nixos/mcp.nix)

## Related ADRs

- [ADR-0001](0001-overlay-consolidation.md) - Contrasting decision (consolidation)

---

**Result:** Platform-specific implementations maintained. Code remains clear, maintainable, and optimized for each platform.
