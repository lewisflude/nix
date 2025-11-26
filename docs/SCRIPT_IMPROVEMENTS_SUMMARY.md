# Script Organization Improvements - Quick Summary

## 🎯 Problems We're Solving

| Problem | Impact | Solution |
|---------|--------|----------|
| **Flat 23-script directory** | Hard to navigate, unclear purpose | **Categorized structure** (hooks/, media/, network/, diagnostics/, validation/) |
| **656-line monolithic README** | Difficult to find information | **Category-specific docs** + auto-generated registry |
| **No script generator** | Inconsistent scripts, manual creation | **`nix run .#new-script`** POG tool with templates |
| **Unclear integration status** | Don't know which scripts are active | **Script registry** with integration mapping |
| **No testing** | Scripts break silently | **Basic test harness** for critical scripts |
| **Inconsistent headers** | Hard to understand script purpose | **Standard header format** with metadata |

## 📊 Before & After

### Current Structure (Flat)

```
scripts/
├── ai-tool-setup.sh
├── auto-format-nix.sh
├── block-dangerous-commands.sh
├── diagnose-qbittorrent-seeding.sh
├── diagnose-ssh-slowness.sh
├── diagnose-steam-audio.sh
├── ... (17 more scripts)
└── README.md (656 lines!)
```

### Proposed Structure (Organized)

```
scripts/
├── README.md (100 lines - overview + links)
├── REGISTRY.md (auto-generated index)
├── templates/
│   └── generic-script.sh
├── hooks/ (7 scripts)
│   └── README.md (hook-specific docs)
├── media/ (8 scripts)
│   └── README.md (qBittorrent/VPN docs)
├── network/ (3 scripts)
│   └── README.md
├── diagnostics/ (3 scripts)
│   └── README.md
├── validation/ (2 scripts)
│   └── README.md
└── tests/ (optional)
    └── test-runner.sh
```

## 🚀 New Capabilities

### 1. Interactive Script Generator

```bash
# Create a new script interactively
nix run .#new-script

# Prompts for:
# - Category: hooks, media, network, diagnostics, validation
# - Name: my-awesome-script
# - Description: Does something useful
# - Integration: none, nix-module, claude-hook, systemd

# Result: Fully scaffolded script with:
# ✓ Standard header format
# ✓ Proper shebang and set -euo pipefail
# ✓ Help flag implementation
# ✓ Error handling boilerplate
# ✓ Executable permissions
```

### 2. Script Registry (Always Up-to-Date)

```markdown
# REGISTRY.md (auto-generated)

| Script | Category | Integration | Description |
|--------|----------|-------------|-------------|
| optimize-mtu.sh | network | none | Discover optimal MTU |
| protonvpn-natpmp-portforward.sh | media | nix-module | NAT-PMP forwarding |
| load-context.sh | hooks | claude-hook | Load session context |
...

## Integration Map
✓ scripts/hooks/load-context.sh → .claude/settings.json
✓ scripts/media/protonvpn-natpmp-portforward.sh → modules/nixos/.../protonvpn-portforward.nix
...
```

### 3. Clear Integration Guidance

New guide: `docs/SCRIPT_INTEGRATION_GUIDE.md`

**Decision tree:**

```
Should script run automatically?
├─ YES → systemd service (readFile in module)
└─ NO → Is it used frequently?
   ├─ YES → Add to PATH (writeShellScriptBin)
   └─ NO → Keep standalone
```

### 4. Standard Script Format

```bash
#!/usr/bin/env bash
# Script: optimize-mtu.sh
# Category: network
# Description: Discover and optimize MTU for network interfaces
# Usage: ./optimize-mtu.sh [--vpn-only] [--apply]
# Integration: none
# Exit codes: 0=success, 1=error
# Dependencies: ping, ip

set -euo pipefail

# Implementation...
```

## 📈 Benefits

### For Users

- 🔍 **Easy discovery** - Find scripts by category
- 📖 **Clear docs** - Focused, category-specific documentation
- ✅ **Integration visibility** - Know which scripts are active vs manual

### For Developers

- 🏗️ **Consistent creation** - Template-based scaffolding
- 📝 **Standard format** - Uniform headers and interfaces
- 🧪 **Testability** - Basic test harness for validation

### For AI Assistants

- 🎯 **Better context** - Clear categorization and purpose
- 🗺️ **Integration map** - Understand what's connected where
- 🔧 **Easy updates** - Standard patterns to follow

## 🛠️ Implementation Phases

### Phase 1: Structure (Week 1) ✅ NON-BREAKING

- Create subdirectories
- Copy scripts (keep originals with symlinks)
- Create category READMEs
- Update `.claude/settings.json`

### Phase 2: Tooling (Week 2)

- Create script templates
- Implement `new-script` POG tool
- Update AI guidelines

### Phase 3: Documentation (Week 3)

- Create REGISTRY.md
- Implement registry generator
- Create integration guide
- Update main README

### Phase 4: Testing (Week 4, Optional)

- Create test framework
- Add tests for critical scripts
- Integrate with CI/CD

### Phase 5: Cleanup (Week 5)

- Remove old locations
- Update all references
- Archive old docs

## 📋 Quick Wins (Immediate Impact)

### 1. Reorganize into Categories (1-2 hours)

**Impact**: Instant clarity, easier navigation

```bash
mkdir -p scripts/{hooks,media,network,diagnostics,validation}
# Move scripts + create symlinks for backward compat
```

### 2. Create Basic REGISTRY.md (30 minutes)

**Impact**: Immediate script discovery

```bash
# Manual first version listing all scripts with descriptions
```

### 3. Add Standard Headers (1 hour)

**Impact**: Better understanding of each script

```bash
# Update top 5-10 most-used scripts with standard header
```

## 🎓 Example: Finding & Using Scripts

### Before (Current)

```bash
# User thinks: "I need to check VPN port forwarding"
cd scripts/
ls *.sh | grep -i vpn  # Hope something matches
# Opens 5 different scripts to find the right one
# Reads 656-line README to understand what each does
```

### After (Proposed)

```bash
# User thinks: "I need to check VPN port forwarding"
cd scripts/media/  # Clear category
ls  # Only 8 relevant scripts
cat README.md  # 100 lines, focused on VPN/qBittorrent
# Or check REGISTRY.md for complete index
./monitor-protonvpn-portforward.sh  # Clear name, obvious purpose
```

## 💡 Integration Example

### Current Integration (Manual)

```nix
# modules/nixos/services/media-management/protonvpn-portforward.nix
systemd.services.protonvpn-portforward = {
  script = builtins.readFile ../../../../scripts/protonvpn-natpmp-portforward.sh;
  # Where is this script? What does it do? Is it tested?
};
```

### Proposed Integration (Clear)

```nix
# modules/nixos/services/media-management/protonvpn-portforward.nix
systemd.services.protonvpn-portforward = {
  script = builtins.readFile ../../../../scripts/media/protonvpn-natpmp-portforward.sh;
  # Clear location: scripts/media/
  # See: scripts/media/README.md for details
  # Integration status tracked in scripts/REGISTRY.md
};
```

## 🔄 Migration Strategy

**Backward Compatibility:**

1. Week 1-2: Both old and new locations exist (symlinks)
2. Week 3-4: Update all references to new locations
3. Week 5+: Remove old locations

**Reference Updates:**

- `.claude/settings.json` (7 scripts)
- NixOS modules (5 scripts)
- Documentation references (~20 files)
- README.md examples

## ✨ Future Enhancements (Post-MVP)

1. **Script analytics** - Track which scripts are actually used
2. **Dependency tracking** - Auto-detect script dependencies
3. **Version tracking** - Semantic versioning for scripts
4. **CI/CD integration** - Auto-test on commit
5. **Script marketplace** - Share scripts across Nix community

## 📝 Next Steps

1. **Review proposal**: Read `docs/SCRIPT_ORGANIZATION_PROPOSAL.md`
2. **Provide feedback**: What resonates? What doesn't?
3. **Prioritize**: Which phases are most important?
4. **Start Phase 1**: Can begin immediately (non-breaking)

---

**Full Proposal**: [SCRIPT_ORGANIZATION_PROPOSAL.md](SCRIPT_ORGANIZATION_PROPOSAL.md)
**Status**: Ready for review
**Timeline**: 5 weeks (4 weeks MVP, 1 week cleanup)
**Risk**: Low (non-breaking migration with symlinks)
