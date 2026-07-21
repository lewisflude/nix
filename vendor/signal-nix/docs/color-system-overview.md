# Signal Theme System

Signal is a perceptually uniform, scientifically-derived color system for desktop theming in Nix environments.

---

## ⚠️ Important: Source of Truth

**signal-nix does NOT define colors.**

All color specifications come from **[signal-palette](https://github.com/lewisflude/signal-palette)**, the single source of truth for the Signal color system.

- 📦 **signal-palette** → Defines colors (OKLCH, APCA, sRGB)
- 🎨 **signal-nix** → Implements colors in Nix/Home Manager modules

See [Signal Palette Integration](./signal-palette-integration.md) for details on how signal-nix imports colors.

---

## Color System Documentation

For complete color system documentation, see signal-palette:

| Topic | Document | Description |
|-------|----------|-------------|
| **Color Theory** | [OKLCH Explained](https://github.com/lewisflude/signal-palette/blob/main/docs/oklch-explained.md) | Why we use OKLCH color space |
| **Design Principles** | [Philosophy](https://github.com/lewisflude/signal-palette/blob/main/docs/philosophy.md) | Design rationale and goals |
| **Color Specifications** | [Color System Reference](https://github.com/lewisflude/signal-palette/blob/main/docs/color-system-reference.md) | Complete palette with all colors |
| **Technical Details** | [Technical Specification](https://github.com/lewisflude/signal-palette/blob/main/docs/technical-specification.md) | Mathematical constraints and validation |
| **Accessibility** | [Accessibility](https://github.com/lewisflude/signal-palette/blob/main/docs/accessibility.md) | APCA contrast standards |
| **UI Mappings** | [Semantic Bridge](https://github.com/lewisflude/signal-palette/blob/main/docs/semantic-bridge.md) | Platform-agnostic color mappings |

---

## signal-nix Repository Structure

```
signal-nix/
├── modules/                       # Application-specific integrations
│   ├── terminals/                # Terminal emulator themes
│   │   └── alacritty.nix        # ← Uses semantic bridge
│   ├── editors/                  # Editor themes
│   │   └── neovim.nix           # ← Uses semantic bridge
│   ├── cli/                      # CLI tool themes
│   │   └── bat.nix              # ← Uses semantic bridge
│   ├── desktop/                  # Desktop environment themes
│   └── ironbar/                  # Ironbar color integration
│       └── tokens.nix            # ← Uses semantic bridge
│
├── lib/                           # Helper libraries
│   ├── semantic.nix              # Semantic bridge (color API)
│   └── validate.nix              # Validation functions
│
├── pkgs/                          # Generated theme packages
│   ├── grub-theme/               # Bootloader themes
│   ├── gtk-theme/                # GTK application themes
│   ├── plymouth-theme/           # Boot splash themes
│   └── sddm-theme/               # Display manager themes
│
└── docs/                          # Documentation
    ├── semantic-bridge-guide.md  # How to use colors in modules
    ├── signal-palette-integration.md  # How colors are imported
    └── theming-reference.md      # Application theming guide
```

**Note:** Color specifications (palette.json, technical docs) live in the **signal-palette** repository.

---

## Why Signal?

Signal solves the **"Context Conflict"** in UI design.

By using **APCA** for contrast and **OKLCH** for uniformity, Signal ensures that an "Alert Red" in your terminal has the exact same functional legibility as the "Alert Red" in your web dashboard, across both light and dark modes.

### The Problem

Traditional theming systems suffer from:
- **Inconsistent contrast** - A color readable in your editor may be illegible in your terminal
- **Perceptual non-uniformity** - HSL/RGB-based themes don't account for human color perception
- **Context mismatch** - Semantic colors (danger, success) look different across applications
- **Dark mode afterthought** - Light themes adapted to dark rather than designed in parallel

### The Signal Solution

1. **APCA Contrast** - Every text color is calculated to meet specific readability targets (75 for primary text, 60 for secondary) against its background, in both light and dark modes.

2. **OKLCH Color Space** - Perceptually uniform adjustments mean that brightness and saturation changes are consistent across all hues.

3. **Single Source of Truth** - All applications derive from signal-palette, ensuring perfect consistency.

### Real-World Impact

- Your red "error" message in `lazygit` has the same legibility as a red button in GTK
- Switching from Alacritty to Kitty to WezTerm maintains identical color appearance
- Dark mode is not a compromise—it's equally well-designed as light mode
- Code syntax highlighting maintains consistent readability across Neovim, VSCode, and Zed

---

## How signal-nix Uses Colors

### The Semantic Bridge

signal-nix uses a **semantic bridge** (`lib/semantic.nix`) to access colors from signal-palette:

```nix
{ signalLib, semantic, ... }:

let
  mode = signalLib.resolveThemeMode cfg.mode;  # "light" or "dark"
in {
  # Access colors by semantic purpose
  background = (semantic.core "background" mode).hex;
  foreground = (semantic.core "foreground" mode).hex;
  error = (semantic.status "error" mode).hex;
  success = (semantic.status "success" mode).hex;
}
```

**Why semantic bridge?**
- Stable API even when palette structure changes
- Colors named by purpose ("background") not implementation ("surface-base")
- Better error messages and discoverability
- Single point of validation

See [Semantic Bridge Guide](./semantic-bridge-guide.md) for complete usage documentation.

---

## Contributing

### Golden Rules

#### 1. Single Source of Truth

**✅ DO:**
```nix
# Import from signal-palette via semantic bridge
{ semantic, signalLib, ... }:

let
  mode = signalLib.resolveThemeMode cfg.mode;
in {
  # Reference semantic colors
  programs.myapp.colors.error = (semantic.status "error" mode).hex;
  programs.myapp.colors.success = (semantic.status "success" mode).hex;
}
```

**❌ NEVER:**
```nix
# Do NOT hardcode colors in modules
programs.myapp.colors.error = "oklch(0.64 0.23 40)";  # FORBIDDEN
programs.myapp.colors.error = "#ff5555";               # FORBIDDEN
programs.myapp.colors.error = "#c93613";               # FORBIDDEN (even if correct!)
```

**Why?** Colors must ONLY be defined in signal-palette. Even if you copy the correct value, you're breaking the source of truth principle.

#### 2. No Hardcoded Colors

Only use colors from the semantic bridge. Never introduce:
- Hardcoded hex values (`#ff0000`)
- RGB values (`rgb(255, 0, 0)`)
- HSL values (`hsl(0, 100%, 50%)`)
- Colors not derived from the Signal system

**Why?** Accidentally using non-Signal colors breaks the perceptual uniformity and contrast guarantees of the system.

#### 3. No New Colors in signal-nix

**signal-nix cannot add new colors.**

If you need a color that doesn't exist:

1. Open an issue in **signal-palette** repository
2. Justify the need with use cases
3. Propose APCA contrast targets
4. Follow signal-palette's contribution guidelines
5. Wait for the color to be added to signal-palette
6. Update signal-nix's flake input

**Never work around missing colors** by:
- Creating "temporary" hardcoded values
- Mixing existing colors (creates unvalidated colors)
- Using colors from other themes

#### 4. Documentation

When adding new **application integrations**:

1. Document which semantic colors are used where
2. Explain semantic mapping (e.g., "error → status.error")
3. Note any platform-specific limitations
4. Add examples to the integration guide

### Workflow for New Application Integration

```bash
# 1. Check available colors in signal-palette
# Visit: https://github.com/lewisflude/signal-palette

# 2. Create your module, using semantic bridge
vim modules/myapp/default.nix

# 3. Map semantic colors to app config
# { semantic, signalLib, ... }:
# let
#   mode = signalLib.resolveThemeMode cfg.mode;
# in {
#   programs.myapp.colors = {
#     background = (semantic.core "background" mode).hex;
#     error = (semantic.status "error" mode).hex;
#   };
# }

# 4. Build and test
nix build .#homeConfigurations.test

# 5. Verify no hardcoded colors exist
rg "oklch\(|#[0-9a-fA-F]{6}|rgb\(|hsl\(" modules/myapp/ --type nix
# (Should show NO results - all colors come from semantic bridge)
```

### Common Pitfalls

❌ **Don't** copy-paste color values between files
✅ **Do** use semantic bridge references

❌ **Don't** "tweak" a color value for one specific app
✅ **Do** request a proper new color in signal-palette if existing ones don't work

❌ **Don't** use color picker tools to create new colors
✅ **Do** calculate colors using APCA and OKLCH math (in signal-palette)

❌ **Don't** edit generated theme files in `pkgs/`
✅ **Do** modify the source Nix modules that generate them

### Testing Changes

When modifying color usage:

1. **Build all themes:**
   ```bash
   nix build .#packages.x86_64-linux.grub-theme
   nix build .#packages.x86_64-linux.gtk-theme
   nix build .#packages.x86_64-linux.plymouth-theme
   nix build .#packages.x86_64-linux.sddm-theme
   ```

2. **Run tests:**
   ```bash
   ./run-tests.sh
   ```

3. **Visual inspection** in actual applications:
   - Test in terminal (Alacritty, Kitty, WezTerm)
   - Test in editor (Neovim, VSCode, Zed)
   - Test in desktop environment (GTK apps, Qt apps)
   - **Test in both light and dark modes**

4. **Check contrast:**
   - Verify text is readable
   - Check that semantic colors (danger, success) are distinguishable
   - Ensure no "invisible" elements

---

## Integration Examples

### Terminal Emulator

```nix
# modules/terminals/kitty.nix
{ config, lib, signalLib, semantic, ... }:

let
  cfg = config.theming.signal;
  mode = signalLib.resolveThemeMode cfg.mode;
in {
  programs.kitty.settings = {
    # Core colors using semantic bridge
    background = (semantic.core "background" mode).hex;
    foreground = (semantic.core "foreground" mode).hex;
    cursor = (semantic.core "cursor" mode).hex;

    # ANSI colors using terminal category
    color0 = (semantic.terminal "ansi-black" mode).hex;
    color1 = (semantic.terminal "ansi-red" mode).hex;
    color2 = (semantic.terminal "ansi-green" mode).hex;
    # ... never hardcoded values
  };
}
```

### Editor

```nix
# modules/editors/helix.nix
{ config, lib, signalLib, semantic, ... }:

let
  cfg = config.theming.signal;
  mode = signalLib.resolveThemeMode cfg.mode;
in {
  programs.helix.settings.theme = {
    "ui.background" = (semantic.editor "background" mode).hex;
    "ui.text" = (semantic.editor "foreground" mode).hex;
    "ui.linenr" = (semantic.editor "line-number" mode).hex;

    "keyword" = (semantic.syntax "keyword" mode).hex;
    "string" = (semantic.syntax "string" mode).hex;
    "comment" = (semantic.syntax "comment" mode).hex;
    # ... derived from semantic bridge
  };
}
```

---

## Further Reading

### signal-nix Documentation
- [Semantic Bridge Guide](./semantic-bridge-guide.md) - How to use colors in modules
- [Signal Palette Integration](./signal-palette-integration.md) - How colors are imported
- [Theming Reference](./theming-reference.md) - Applying Signal to your setup
- [Testing Guide](./TESTING_GUIDE.md) - Validating theme changes

### signal-palette Documentation (Color Specifications)
- [Color System Reference](https://github.com/lewisflude/signal-palette/blob/main/docs/color-system-reference.md) - Complete palette guide
- [Technical Specification](https://github.com/lewisflude/signal-palette/blob/main/docs/technical-specification.md) - Mathematical constraints
- [Philosophy](https://github.com/lewisflude/signal-palette/blob/main/docs/philosophy.md) - Design principles
- [OKLCH Explained](https://github.com/lewisflude/signal-palette/blob/main/docs/oklch-explained.md) - Color space overview
- [Accessibility](https://github.com/lewisflude/signal-palette/blob/main/docs/accessibility.md) - APCA standards

---

## Philosophy

Signal is not just a theme—it's a **system** for ensuring visual consistency and accessibility across your entire computing environment. Every color has a purpose, every contrast ratio is intentional, and every implementation maintains the mathematical guarantees of the source palette.

**Remember:** Color is math, not art. Trust the system.

---

**Last Updated:** 2026-01-21
**Documentation Version:** 1.0.1
