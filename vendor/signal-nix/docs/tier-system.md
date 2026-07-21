# Configuration Method Tier System

## Quick Reference

When integrating a new application, use the **highest available tier**:

| Tier | Method | When to Use | Example |
|------|--------|-------------|---------|
| **1** | Native theme options | Home-Manager has dedicated theme support | `programs.bat.themes` |
| **2** | Structured colors | Home-Manager has typed color options | `programs.alacritty.settings.colors` |
| **3** | Freeform settings | Home-Manager has untyped settings attrset | `programs.kitty.settings` |
| **4** | Raw config | No better option exists | `programs.tmux.extraConfig` |

## Tier Details

### Tier 1: Native Theme Options (BEST)
- Home-Manager provides dedicated theme options
- Full type safety and validation
- Forward-compatible
- Examples: bat, helix

### Tier 2: Structured Colors (GOOD)
- Home-Manager provides structured attrsets for colors
- Type-safe color options
- Clear namespace separation
- Examples: alacritty

### Tier 3: Freeform Settings (ACCEPTABLE)
- Home-Manager has freeform `settings` option
- Serializes to config format
- Limited type validation
- Examples: kitty, ghostty, delta, lazygit, yazi, fuzzel, starship, zellij

### Tier 4: Raw Config (LAST RESORT)
- Manual config string generation
- No type safety or validation
- Only use when no better option exists
- Examples: wezterm, eza, fzf, neovim, zsh, btop, tmux, gtk

## Required Module Metadata

Every module MUST include this metadata block:

```nix
{
  config,
  lib,
  signalColors,
  signalLib,
  ...
}:
# CONFIGURATION METHOD: <tier-name>
# HOME-MANAGER MODULE: <module-path>
# UPSTREAM SCHEMA: <schema-url>
# SCHEMA VERSION: <version>
# LAST VALIDATED: <YYYY-MM-DD>
# NOTES: <additional-context>
let
  # ... implementation
```

## Integration Checklist

### 1. Research
- [ ] Check Home-Manager module options
- [ ] Identify highest available tier
- [ ] Find upstream schema documentation
- [ ] Note current version

### 2. Implement
- [ ] Create module in correct category folder
- [ ] Add required metadata comment
- [ ] Use `signalLib.shouldThemeApp` helper
- [ ] Map Signal colors semantically
- [ ] Support light and dark modes

### 3. Test
- [ ] Run `nix flake check`
- [ ] Test both light and dark modes
- [ ] Verify colors in actual application
- [ ] Check for warnings/errors

### 4. Document
- [ ] Update module imports in `modules/common/default.nix`
- [ ] Add to README.md
- [ ] Create example if needed

## Upgrading Tiers

If Home-Manager adds better options:
1. Update module implementation
2. Update metadata comment
3. Test thoroughly
4. Document in commit message

Check for upgrades quarterly using `./check-hm-updates.sh`
