# Signal-nix Refactoring Audit
## Principle: Color Theme Only - No Behavior Configuration

### Violations Found

#### High Priority (Remove Immediately)

- [x] **bat.nix** - Lines 360-362
  - ✅ COMPLETED: Comment added documenting user responsibility
  - No non-theme settings remain
  - ✅ Action: Complete

- [x] **ironbar/default.nix** - Line 197
  - ✅ COMPLETED: Comment added documenting user responsibility
  - No systemd setting in Signal module
  - ✅ Action: Complete

- [x] **ironbar/style.css** - Generated CSS
  - ✅ COMPLETED: Stripped to colors only
  - ❌ Removed: font-family, font-size, margin, padding, border-radius, border-width
  - ✅ Created: examples/ironbar-complete.css showing full layout
  - ✅ Updated: README.md with guidance on layout customization
  - ✅ Action: Complete

#### Medium Priority (Review & Refactor)

- [x] **lib/default.nix** - Extract common patterns
  - ✅ COMPLETED: Added getSyntaxColors helper
  - ✅ Provides consistent color mappings for syntax highlighting
  - ✅ Updated bat.nix to use centralized helper
  - ✅ Action: Complete

- [x] **fzf.nix** - Simplify dual-setting approach
  - ✅ COMPLETED: Simplified to single color definition
  - ✅ Removed redundant mkMerge and duplicate color settings
  - ✅ Uses mapAttrsToList for cleaner code
  - ✅ Action: Complete

- [ ] **ironbar/config.nix** - Full audit needed
  - Review what non-color settings are in config
  - Strip to absolute minimum

#### Low Priority (Documentation/Examples)

- [x] **examples/*** - Ensure examples don't show Signal enabling programs
  - ✅ COMPLETED: examples/ironbar-complete.css created
  - ✅ Shows users enabling programs FIRST, then Signal theming them
  - ✅ Clear separation of concerns documented
  - ✅ Action: Complete

- [x] **README.md** - Document ironbar layout guidance
  - ✅ COMPLETED: Added section on ironbar customization
  - ✅ Shows how to combine Signal colors with user layout
  - ✅ References examples/ironbar-complete.css
  - ✅ Action: Complete

### Refactoring Strategy

1. **Phase 1**: Remove obvious violations (bat, ironbar systemd) ✅ **COMPLETED**
   - bat.nix: Documented user responsibility for non-color settings
   - ironbar: Stripped CSS to colors only
   - ironbar: Documented systemd as user responsibility
   
2. **Phase 2**: Create style guide for contributors ✅ **COMPLETED**
   - DESIGN_PRINCIPLES.md created with clear guidelines
   - examples/ironbar-complete.css shows correct pattern
   - README.md updated with ironbar guidance
   
3. **Phase 3**: Improve lib helpers ✅ **COMPLETED**
   - getSyntaxColors() extracted to lib
   - bat.nix refactored to use helper
   - fzf.nix simplified with better pattern
   
4. **Phase 4**: Add CI checks to prevent non-color settings (TODO)
   - Can add validation in future
   
5. **Phase 5**: Document philosophy prominently ✅ **COMPLETED**
   - DESIGN_PRINCIPLES.md explains color-only approach
   - Examples demonstrate correct usage

### Decision: What Counts as "Color-Related"?

#### ✅ Allowed (Color/Theme Related)
- Color hex values, RGB, OKLCH values
- Theme names (e.g., "signal-dark")
- Palette definitions
- Syntax highlighting scopes → color mappings
- ANSI color assignments
- Background/foreground/border colors

#### ❌ Not Allowed (Behavior/Layout)
- Font families, sizes, weights
- Margins, padding, spacing
- Border radius, width (except color)
- Feature toggles (italic, bold as behavior)
- Service management (systemd, autostart)
- Keybindings
- Pagers, formatters, external tools
- Display modes (line numbers, git markers)

#### 🤔 Gray Area (Requires Discussion)
- **Transparency/opacity**: Arguably color-related?
  - Decision: Allow if it's about color alpha channel
  - Disallow if it's about window/compositor effects

- **Icon themes**: Related to visual design system?
  - Decision: For now, stick to colors only
  - Could be future expansion

### Module-by-Module Checklist

#### Terminals
- [ ] alacritty.nix - ✅ Colors only (good!)
- [ ] kitty.nix - ✅ Colors only (good!)
- [ ] ghostty.nix - ✅ Colors only (good!)
- [ ] wezterm.nix - Review needed

#### Editors
- [ ] helix.nix - Review theme file generation
- [ ] neovim.nix - Review needed

#### CLI Tools
- [ ] bat.nix - ❌ Has violations (see above)
- [ ] delta.nix - Review needed
- [ ] eza.nix - Review needed
- [ ] fzf.nix - ✅ Colors only (good!)
- [ ] lazygit.nix - Review needed
- [ ] yazi.nix - Review needed

#### Multiplexers
- [ ] tmux.nix - Review needed
- [ ] zellij.nix - Review needed

#### Other
- [ ] btop.nix - Review needed
- [ ] starship.nix - Review needed
- [ ] zsh.nix - Review needed
- [ ] gtk/default.nix - Review needed
- [ ] ironbar/* - ❌ Has violations (see above)
- [ ] fuzzel.nix - Review needed

### Implementation Plan

```nix
# Proposed: Add to lib/default.nix
strictColorMode = {
  # Validation that can be optionally enabled
  # Could error or warn on non-color settings
  enabled = false; # Off by default during transition
  
  validate = module: settings: 
    # Check settings against allowlist
    # Throw helpful error with suggestion
};
```

### Success Criteria

1. ✅ All modules only set color-related properties
2. ✅ No program enablement in Signal modules
3. ✅ Clear documentation of separation of concerns
4. ✅ Examples demonstrate correct usage pattern
5. ✅ CI validates no non-color settings introduced
