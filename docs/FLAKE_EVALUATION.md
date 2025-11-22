# Nix Flake Evaluation Report

This document evaluates components in the configuration that could benefit from using official or unofficial Nix flakes to improve reproducibility and maintainability.

## Executive Summary

**High Priority Changes:**
1. ✅ MCP Servers - Replace `@latest` NPM tags with `github:roman/mcps.nix` flake
2. ✅ ComfyUI - Replace `:latest` Docker tag with `github:utensils/nix-comfyui` flake
3. ⚠️ Cursor Editor - Use `code-cursor` from nixpkgs-unstable for Linux only

**Medium Priority Changes:**
4. ⏸️ Container Images - Keep pinned versions as-is (already reproducible)

**Low Priority:**
5. ✅ ZSH plugins, Nx package, Home Assistant - Working well, no changes needed

---

## 1. MCP Servers (HIGH PRIORITY)

### Current Implementation

**Files:** `home/nixos/mcp.nix`, `home/darwin/mcp.nix`, `modules/shared/mcp/servers.nix`

**Issues:**
- NPM packages use `@latest` tag: `@modelcontextprotocol/server-filesystem@latest`
- Python packages use runtime uvx fetching with no version pinning
- Runtime downloads break Nix's reproducibility guarantees
- Cache misses on every build
- No guarantee same versions run across machines

**Examples:**
```nix
# Current approach - NON-REPRODUCIBLE
"${servers.nodejs}/bin/npx" "-y" "@modelcontextprotocol/server-memory@latest"
"${pkgs.uv}/bin/uvx" "--from" "mcp-server-fetch" "mcp-server-fetch"
```

### Available Flake Solutions

Three mature flakes available:

#### 1. roman/mcps.nix (RECOMMENDED)
- **URL:** `github:roman/mcps.nix`
- **Features:**
  - 14 built-in presets (git, GitHub, filesystem, LSP integrations, etc.)
  - Home Manager module integration (`programs.claude-code`)
  - Secure credential management via file-based tokens
  - Version pinning via flake.lock
- **Sources:**
  - [GitHub - roman/mcps.nix](https://github.com/roman/mcps.nix)

#### 2. aloshy-ai/nix-mcp-servers
- **URL:** `github:aloshy-ai/nix-mcp-servers`
- **Features:**
  - Declarative MCP server configuration
  - Supports Claude and Cursor
  - Home Manager modules
- **Sources:**
  - [GitHub - aloshy-ai/nix-mcp-servers](https://github.com/aloshy-ai/nix-mcp-servers)
  - [MCP Server Configuration Manual](https://aloshy-ai.github.io/nix-mcp-servers/)

#### 3. natsukium/mcp-servers-nix
- **URL:** `github:natsukium/mcp-servers-nix`
- **Features:**
  - Framework-based configuration
  - Ready-to-use packages
  - Extensible
- **Sources:**
  - [GitHub - natsukium/mcp-servers-nix](https://github.com/natsukium/mcp-servers-nix)

### Recommendation

**Use `github:roman/mcps.nix`** because:
- Most comprehensive preset library
- Already integrates with Home Manager (which you use)
- Active maintenance in 2025
- Handles versioning properly
- Supports secure credential management

### Implementation Plan

1. Add to `flake.nix` inputs:
```nix
mcps = {
  url = "github:roman/mcps.nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

2. Update `home/nixos/mcp.nix` and `home/darwin/mcp.nix` to use presets
3. Remove `@latest` tags from all NPM and Python server definitions
4. Let flake.lock pin versions for reproducibility

---

## 2. ComfyUI (HIGH PRIORITY)

### Current Implementation

**File:** `modules/nixos/services/containers-supplemental/services/comfyui.nix:26`

**Issues:**
```nix
image = "docker.io/runpod/comfyui:latest";  # NON-REPRODUCIBLE
```
- `:latest` tag fetches different versions over time
- No version pinning
- Non-reproducible builds
- Potential security issues from unvetted updates

### Available Flake Solutions

#### 1. utensils/nix-comfyui (RECOMMENDED)
- **URL:** `github:utensils/nix-comfyui`
- **Features:**
  - Cross-platform (macOS Intel/Apple Silicon, Linux)
  - Automatic GPU detection (CUDA 12.4, MPS, CPU fallback)
  - Python 3.12 support
  - Data persistence in `~/.config/comfy-ui`
  - Includes ComfyUI-Manager for plugins
  - Docker support (GPU support in development)
- **Sources:**
  - [GitHub - utensils/nix-comfyui](https://github.com/utensils/nix-comfyui)

#### 2. dyscorv/nix-comfyui
- **URL:** `github:dyscorv/nix-comfyui`
- **Features:**
  - Can be used as flake input
  - Provides nixpkgs overlay
- **Sources:**
  - [GitHub - dyscorv/nix-comfyui](https://github.com/dyscorv/nix-comfyui)

#### 3. Official ComfyUI PR #7292
- **Status:** Pull Request (not merged)
- **Limitations:** NVIDIA GPU only
- **Sources:**
  - [Add nix support PR](https://github.com/comfyanonymous/ComfyUI/pull/7292)

### Recommendation

**Use `github:utensils/nix-comfyui`** because:
- Most mature and feature-complete
- Better dependency management than Docker
- Automatic hardware detection
- Proper version pinning via flake.lock
- Active development

### Implementation Plan

1. Add to `flake.nix` inputs:
```nix
comfyui = {
  url = "github:utensils/nix-comfyui";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

2. Replace Docker container with native Nix package
3. Update module to use flake package instead of OCI container
4. Configure data paths and GPU passthrough

---

## 3. Cursor Editor (MEDIUM PRIORITY)

### Current Implementation

**Files:** `pkgs/cursor/default.nix`, `pkgs/cursor/cursor-info.json`, `pkgs/cursor/linux.nix`

**Issues:**
- Manual URL and hash management
- Requires manual updates for new versions
- Could benefit from automation

**Example:**
```json
{
  "version": "1.7.46",
  "linux": {
    "url": "https://downloads.cursor.com/production/b9e5948c1ad20443a5cecba6b84a3c9b99d62582/linux/x64/Cursor-1.7.46-x86_64.AppImage",
    "sha256": "sha256-XDKDZYCagr7bEL4HzQFkhdUhPiL5MaRzZTPNrLDPZDM="
  }
}
```

### Available Solutions

#### 1. nixpkgs-unstable `code-cursor` (RECOMMENDED for Linux)
- **Package:** `pkgs.code-cursor`
- **Platform:** Linux only
- **Features:**
  - Officially maintained in nixpkgs
  - Automatic updates via nixpkgs-unstable
  - AppImage wrapped for NixOS
- **Sources:**
  - [nixpkgs Issue #309541](https://github.com/NixOS/nixpkgs/issues/309541)
  - [Cursor Forum Discussion](https://forum.cursor.com/t/cursor-is-now-available-on-nixos/16640)

#### 2. omarcresp/cursor-flake
- **URL:** `github:omarcresp/cursor-flake`
- **Features:**
  - Dedicated Cursor flake
  - Similar to current manual approach
- **Sources:**
  - [GitHub - omarcresp/cursor-flake](https://github.com/omarcresp/cursor-flake)

### Recommendation

**Use nixpkgs-unstable `code-cursor` for Linux, keep manual approach for Darwin:**
- Linux: Use `pkgs.code-cursor` from nixpkgs-unstable (maintained by community)
- Darwin: Keep current manual approach (nixpkgs doesn't support Darwin for this package)

**Rationale:**
- nixpkgs-unstable already has `code-cursor` for Linux
- Automatically updated by nixpkgs maintainers
- Current manual approach works well for Darwin
- No significant benefit from third-party flake

### Implementation Plan

1. For Linux hosts: Replace `pkgs.cursor` with `pkgs.code-cursor`
2. For Darwin hosts: Keep current implementation
3. Consider automating hash updates with `nix-update` or similar tools

---

## 4. Container Images (LOW PRIORITY - NO CHANGE NEEDED)

### Current Implementation

**File:** `modules/nixos/services/containers-supplemental/services/calcom.nix`

**Example:**
```nix
image = "docker.io/calcom/cal.com:v5.8.2";
image = "docker.io/library/postgres:16.3-alpine";
```

### Analysis

**Why this is actually GOOD:**
- ✅ Pinned versions provide reproducibility (not using `:latest`)
- ✅ Explicit version tags are easy to audit
- ✅ Can be updated via automated tools (Renovate, Dependabot)
- ✅ No good Nix flake alternatives for these services

**Why NOT to change:**
- Container images don't have mature Nix flake alternatives
- Pinned versions already provide reproducibility guarantees
- Updates can be automated via CI/CD pipelines
- Current approach is industry-standard for containerized services

### Recommendation

**KEEP AS-IS** - Pinned container versions are already reproducible.

**Optional Improvements:**
- Set up Renovate or Dependabot to automate version bumps
- Create a script to check for security updates
- Document update process in CONTRIBUTING.md

---

## 5. Low Priority Components (NO CHANGE NEEDED)

### ZSH Plugins via nvfetcher
- **Status:** ✅ Working well
- **Reasoning:** nvfetcher provides automated updates and version pinning
- **Recommendation:** Keep current approach

### Nx Package
- **Status:** ✅ Working well
- **Implementation:** Using `buildNpmPackage` with pinned version
- **Recommendation:** Keep current approach

### Home Assistant Components
- **Status:** ✅ Working well
- **Reasoning:** Infrequently updated, current approach is sufficient
- **Recommendation:** Keep current approach

---

## Implementation Priority

### Phase 1: High Priority (Breaks Reproducibility)
1. ✅ Implement MCP servers flake (`github:roman/mcps.nix`)
2. ✅ Implement ComfyUI flake (`github:utensils/nix-comfyui`)

### Phase 2: Medium Priority (Maintenance Improvements)
3. ⚠️ Switch to `code-cursor` from nixpkgs-unstable for Linux

### Phase 3: Optional Enhancements
4. ⏸️ Set up automated container image updates
5. ⏸️ Automate Cursor hash updates for Darwin

---

## Testing Plan

After implementing changes:

1. **MCP Servers:**
   - Verify all servers register with Claude CLI
   - Test each server's functionality
   - Confirm no runtime downloads occur
   - Check flake.lock for version pins

2. **ComfyUI:**
   - Verify GPU detection works
   - Test model downloads and persistence
   - Confirm UI accessibility
   - Check CUDA/MPS acceleration

3. **Cursor (if changed):**
   - Verify application launches
   - Test code editing functionality
   - Confirm extensions work

4. **Reproducibility:**
   - Run `nix flake check`
   - Build on fresh machine
   - Verify no network fetches during build

---

## References

### MCP Servers
- [GitHub - roman/mcps.nix](https://github.com/roman/mcps.nix)
- [GitHub - aloshy-ai/nix-mcp-servers](https://github.com/aloshy-ai/nix-mcp-servers)
- [GitHub - natsukium/mcp-servers-nix](https://github.com/natsukium/mcp-servers-nix)
- [MCP Server Configuration Manual](https://aloshy-ai.github.io/nix-mcp-servers/)

### ComfyUI
- [GitHub - utensils/nix-comfyui](https://github.com/utensils/nix-comfyui)
- [GitHub - dyscorv/nix-comfyui](https://github.com/dyscorv/nix-comfyui)
- [ComfyUI Nix Support PR](https://github.com/comfyanonymous/ComfyUI/pull/7292)

### Cursor
- [GitHub - omarcresp/cursor-flake](https://github.com/omarcresp/cursor-flake)
- [nixpkgs Issue #309541](https://github.com/NixOS/nixpkgs/issues/309541)
- [Cursor on NixOS Forum](https://forum.cursor.com/t/cursor-is-now-available-on-nixos/16640)

---

## Conclusion

**Immediate Action Required:**
- Implement MCP servers flake (HIGH IMPACT on reproducibility)
- Implement ComfyUI flake (HIGH IMPACT on reproducibility)

**Optional Improvements:**
- Switch to nixpkgs `code-cursor` for Linux
- Automate container image updates

**No Action Needed:**
- Container images with pinned versions (already reproducible)
- ZSH plugins, Nx package, Home Assistant (working well)
