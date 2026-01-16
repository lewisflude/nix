# Signal Design System - Extraction & Launch Plan

**Created:** 2026-01-16  
**Status:** ✅ **COMPLETED** (2026-01-16)  
**Architecture Decision:** Hybrid (2 repos)  
**Completion:** Same day extraction & integration

## Completion Summary

✅ **Phase 1-3 COMPLETED** - All core extraction work finished:

- **signal-palette**: `github:lewisflude/signal-palette`
  - ✅ `palette.json` with full OKLCH color system
  - ✅ Multi-format exports (Nix, CSS, JS, TS, SCSS, YAML)
  - ✅ Node.js generation script
  - ✅ Comprehensive documentation
  - ✅ Flake with clean exports

- **signal-nix**: `github:lewisflude/signal-nix`
  - ✅ 10+ application modules migrated (Ironbar, GTK, Helix, terminals, CLI tools)
  - ✅ Common module interface with options
  - ✅ Library functions (color manipulation, brand governance)
  - ✅ Example configurations
  - ✅ Flake structure following Catppuccin pattern

- **Personal Config Integration**: `~/.config/nix`
  - ✅ Added `signal` flake input
  - ✅ Created integration bridge module
  - ✅ Successfully tested on signal-migration branch

**Outstanding** (Phase 4-5):
- Screenshots and demo videos
- Community documentation
- CI/CD pipelines
- Social media launch

---

## Original Plan

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Decision](#architecture-decision)
3. [Repository Structure](#repository-structure)
4. [Phase-by-Phase Implementation](#phase-by-phase-implementation)
5. [Technical Specifications](#technical-specifications)
6. [Timeline & Milestones](#timeline--milestones)
7. [Launch Strategy](#launch-strategy)
8. [Success Metrics](#success-metrics)
9. [Future Evolution](#future-evolution)

---

## Executive Summary

### What We're Extracting

**Signal Design System** - A scientific, OKLCH-based design system for NixOS/Home Manager with professional, accessible theming across desktop applications.

### Unique Value Proposition

- **First OKLCH-based design system** for Linux desktop environments
- **Accessibility-first**: APCA contrast calculations
- **Brand Governance**: Unique system for managing brand vs functional colors
- **Scientific Philosophy**: "Perception, engineered" - every color is calculated
- **Atomic Design**: Proven methodology from ironbar implementation

### Architecture Decision

**Hybrid approach with 2 repositories:**

1. **signal/palette** - Platform-agnostic color definitions (JSON, Nix, CSS, JS)
2. **signal/nix** - All Nix/Home Manager/NixOS integrations (monorepo)

**Why not separate per app?**
- Too complex for single maintainer
- Version coordination nightmare
- User confusion
- Following Catppuccin pattern (monorepo for Nix)

**Why separate palette?**
- Platform-agnostic (can be used in web, print, etc.)
- Stable semantic versioning (v1.0.0 = colors locked)
- Future-proof for signal/web, signal/react, etc.

---

## Architecture Decision

### Comparison Matrix

| Approach | Repos | User Complexity | Maintainability | Future-Proof |
|----------|-------|-----------------|-----------------|--------------|
| **Full Monorepo** | 1 | ⭐⭐⭐ Simple | ⭐⭐ Medium | ❌ Nix-locked |
| **Hybrid (Recommended)** | 2 | ⭐⭐⭐ Simple | ⭐⭐⭐ Good | ✅ Flexible |
| **Multi-Repo per App** | 7+ | ❌ Complex | ❌ Hard | ✅ Flexible |

### User Experience Comparison

#### ❌ Multi-Repo (Not Recommended)
```nix
inputs = {
  signal-palette.url = "github:signal/palette";
  signal-ironbar.url = "github:signal/ironbar";
  signal-gtk.url = "github:signal/gtk";
  signal-helix.url = "github:signal/helix";
  # Which versions are compatible??
};
```

#### ✅ Hybrid (Recommended)
```nix
inputs.signal.url = "github:signal/nix";
# Palette is transitive dependency - user doesn't see it

theming.signal = {
  enable = true;
  mode = "dark";
  ironbar.enable = true;
  gtk.enable = true;
};
```

---

## Repository Structure

### signal/palette

**Purpose:** Platform-agnostic color definitions

**Location:** `https://github.com/<username>/signal-palette`

```
signal-palette/
├── README.md                    # Philosophy, usage, exports
├── LICENSE                      # MIT
├── CHANGELOG.md                 # Semantic versioning
├── flake.nix                    # Nix consumers
├── package.json                 # NPM package (future)
├── palette.json                 # Source of truth (OKLCH)
├── exports/
│   ├── palette.nix             # Nix attrset
│   ├── palette.js              # JavaScript/TypeScript
│   ├── palette.css             # CSS custom properties
│   ├── palette.scss            # Sass variables
│   └── palette.yaml            # For design tools
├── docs/
│   ├── philosophy.md           # "Perception, engineered"
│   ├── oklch-explained.md      # Why OKLCH vs RGB/HSL
│   ├── accessibility.md        # APCA guidelines
│   ├── color-theory.md         # Design decisions
│   └── brand-governance.md     # Unique feature explained
├── tests/
│   ├── contrast-tests.nix      # APCA contrast validation
│   └── color-conversion.nix    # OKLCH → hex accuracy
└── .github/
    └── workflows/
        └── ci.yml              # Validate colors, generate exports
```

**Key Files:**

**palette.json** (Source of Truth)
```json
{
  "name": "Signal Design System",
  "version": "1.0.0",
  "description": "Perception, engineered.",
  "colorSpace": "OKLCH",
  "license": "MIT",
  
  "metadata": {
    "philosophy": "Scientific, dual-theme color system where every color is the calculated solution to a functional problem",
    "accessibility": "APCA-compliant contrast ratios",
    "perceptualUniformity": "OKLCH color space for consistent lightness"
  },
  
  "tonal": {
    "50": {
      "oklch": { "l": 0.95, "c": 0.01, "h": 240 },
      "hex": "#f5f5f7",
      "rgb": { "r": 245, "g": 245, "b": 247 },
      "description": "Lightest neutral for backgrounds",
      "apca": { "contrast": 108, "on": "950" }
    },
    "100": { "oklch": { "l": 0.90, "c": 0.02, "h": 240 }, "hex": "#e8e9ed" },
    "200": { "oklch": { "l": 0.80, "c": 0.03, "h": 240 }, "hex": "#c8cad3" },
    "300": { "oklch": { "l": 0.70, "c": 0.04, "h": 240 }, "hex": "#a8aab9" },
    "400": { "oklch": { "l": 0.60, "c": 0.04, "h": 240 }, "hex": "#888a9f" },
    "500": { "oklch": { "l": 0.50, "c": 0.04, "h": 240 }, "hex": "#6b6f82" },
    "600": { "oklch": { "l": 0.40, "c": 0.03, "h": 240 }, "hex": "#53566b" },
    "700": { "oklch": { "l": 0.30, "c": 0.02, "h": 240 }, "hex": "#3d3f54" },
    "800": { "oklch": { "l": 0.23, "c": 0.02, "h": 240 }, "hex": "#2d2e39" },
    "900": { "oklch": { "l": 0.19, "c": 0.01, "h": 240 }, "hex": "#25262f" },
    "950": { "oklch": { "l": 0.15, "c": 0.01, "h": 240 }, "hex": "#1a1b23" }
  },
  
  "accent": {
    "focus": {
      "oklch": { "l": 0.68, "c": 0.18, "h": 240 },
      "hex": "#5a7dcf",
      "description": "Primary interactive color - calm, trustworthy blue",
      "usage": ["buttons", "links", "active states"]
    },
    "success": {
      "oklch": { "l": 0.65, "c": 0.20, "h": 145 },
      "hex": "#4a9b6f",
      "description": "Positive actions and confirmations"
    },
    "warning": {
      "oklch": { "l": 0.79, "c": 0.15, "h": 90 },
      "hex": "#c9a93a",
      "description": "Caution and attention needed"
    },
    "danger": {
      "oklch": { "l": 0.64, "c": 0.23, "h": 40 },
      "hex": "#d9574a",
      "description": "Destructive actions and errors"
    },
    "info": {
      "oklch": { "l": 0.70, "c": 0.16, "h": 200 },
      "hex": "#4a9bcf",
      "description": "Informational messages"
    }
  },
  
  "categorical": {
    "syntax": {
      "keyword": { "oklch": { "l": 0.70, "c": 0.18, "h": 300 }, "hex": "#b47dcf" },
      "function": { "oklch": { "l": 0.68, "c": 0.18, "h": 240 }, "hex": "#5a7dcf" },
      "string": { "oklch": { "l": 0.65, "c": 0.20, "h": 145 }, "hex": "#4a9b6f" },
      "number": { "oklch": { "l": 0.79, "c": 0.15, "h": 90 }, "hex": "#c9a93a" },
      "comment": { "oklch": { "l": 0.50, "c": 0.04, "h": 240 }, "hex": "#6b6f82" }
    },
    "dataViz": {
      "chart1": { "oklch": { "l": 0.68, "c": 0.18, "h": 240 }, "hex": "#5a7dcf" },
      "chart2": { "oklch": { "l": 0.65, "c": 0.20, "h": 145 }, "hex": "#4a9b6f" },
      "chart3": { "oklch": { "l": 0.79, "c": 0.15, "h": 90 }, "hex": "#c9a93a" },
      "chart4": { "oklch": { "l": 0.70, "c": 0.18, "h": 300 }, "hex": "#b47dcf" },
      "chart5": { "oklch": { "l": 0.70, "c": 0.16, "h": 200 }, "hex": "#4a9bcf" }
    }
  }
}
```

**exports/palette.nix**
```nix
# Auto-generated from palette.json
{
  tonal = {
    "50" = { l = 0.95; c = 0.01; h = 240; hex = "#f5f5f7"; };
    "100" = { l = 0.90; c = 0.02; h = 240; hex = "#e8e9ed"; };
    # ... complete tonal scale
  };
  
  accent = {
    focus = { l = 0.68; c = 0.18; h = 240; hex = "#5a7dcf"; };
    success = { l = 0.65; c = 0.20; h = 145; hex = "#4a9b6f"; };
    warning = { l = 0.79; c = 0.15; h = 90; hex = "#c9a93a"; };
    danger = { l = 0.64; c = 0.23; h = 40; hex = "#d9574a"; };
    info = { l = 0.70; c = 0.16; h = 200; hex = "#4a9bcf"; };
  };
  
  # ... categorical colors
}
```

**Version Strategy:**
- v1.0.0 = Initial stable palette
- v1.1.0 = New color added (non-breaking)
- v2.0.0 = Color removed or renamed (breaking)

### signal/nix

**Purpose:** All Nix/Home Manager/NixOS integrations

**Location:** `https://github.com/<username>/signal-nix`

```
signal-nix/
├── README.md                    # Main documentation
├── LICENSE                      # MIT
├── CHANGELOG.md                 # Version history
├── flake.nix                    # Main entry point
├── flake.lock
├── lib/
│   ├── helpers.nix             # Color manipulation utilities
│   ├── brandGovernance.nix     # Brand color system
│   └── accessibility.nix       # APCA contrast checks
├── modules/
│   ├── common.nix              # Shared options (enable, mode, etc.)
│   ├── ironbar/
│   │   ├── default.nix         # Module definition
│   │   ├── tokens.nix          # Maps palette → ironbar tokens
│   │   ├── widgets.nix         # Widget builders
│   │   ├── config.nix          # JSON config generator
│   │   └── style.css           # CSS implementation
│   ├── gtk/
│   │   ├── default.nix
│   │   ├── gtk3.nix
│   │   └── gtk4.nix
│   ├── editors/
│   │   ├── helix.nix
│   │   ├── zed.nix
│   │   └── cursor.nix
│   ├── terminals/
│   │   ├── ghostty.nix
│   │   ├── zellij.nix
│   │   └── kitty.nix
│   ├── cli/
│   │   ├── bat.nix
│   │   ├── fzf.nix
│   │   └── yazi.nix
│   └── desktop/
│       ├── fuzzel.nix
│       ├── mako.nix
│       └── swaync.nix
├── examples/
│   ├── basic.nix               # Minimal setup
│   ├── ironbar-showcase.nix    # Ironbar with all features
│   ├── full-desktop.nix        # All apps enabled
│   └── custom-colors.nix       # Brand color overrides
├── tests/
│   ├── default.nix
│   ├── ironbar.nix
│   ├── gtk.nix
│   └── integration.nix
├── docs/
│   ├── installation.md
│   ├── configuration.md
│   ├── applications.md         # Per-app configuration
│   ├── brand-colors.md         # Brand governance guide
│   ├── troubleshooting.md
│   └── migration.md            # From old setup
└── .github/
    └── workflows/
        ├── ci.yml              # Test all modules
        └── release.yml         # Automated releases
```

**Key Files:**

**flake.nix**
```nix
{
  description = "Signal Design System - Scientific, OKLCH-based design system for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    signal-palette.url = "github:<username>/signal-palette";
    signal-palette.inputs.nixpkgs.follows = "nixpkgs";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, signal-palette, home-manager, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # Home Manager module (primary interface)
      homeManagerModules = {
        default = self.homeManagerModules.signal;
        
        signal = import ./modules/common.nix {
          inherit (signal-palette) palette;
        };
        
        # Optional: Per-app modules for advanced users
        ironbar = import ./modules/ironbar;
        gtk = import ./modules/gtk;
        helix = import ./modules/editors/helix.nix;
      };

      # NixOS modules (if needed)
      nixosModules = {
        default = self.nixosModules.signal;
        signal = ./modules/nixos.nix;
      };

      # Packages (if any CLI tools)
      packages = forAllSystems (system: {
        # Future: signal-export CLI tool
      });

      # Development shell
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nixpkgs-fmt
              statix
              deadnix
              nil
            ];
          };
        }
      );

      # Checks
      checks = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          format = pkgs.runCommand "check-format" {} ''
            ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}
            touch $out
          '';
        }
      );

      formatter = forAllSystems (system: 
        nixpkgs.legacyPackages.${system}.nixpkgs-fmt
      );
    };
}
```

**modules/common.nix** (Main module interface)
```nix
{ config, lib, pkgs, palette, ... }:

let
  inherit (lib) mkOption mkEnableOption types;
  cfg = config.theming.signal;
in
{
  options.theming.signal = {
    enable = mkEnableOption "Signal Design System";

    mode = mkOption {
      type = types.enum [ "light" "dark" "auto" ];
      default = "dark";
      description = ''
        Color theme mode:
        - light: Use light mode colors
        - dark: Use dark mode colors
        - auto: Follow system preference (defaults to dark)
      '';
    };

    # Per-application enables
    ironbar = {
      enable = mkEnableOption "Signal theme for Ironbar";
      profile = mkOption {
        type = types.enum [ "compact" "relaxed" "spacious" ];
        default = "relaxed";
        description = "Display profile (compact=1080p, relaxed=1440p+, spacious=4K)";
      };
    };

    gtk = {
      enable = mkEnableOption "Signal theme for GTK";
      version = mkOption {
        type = types.enum [ "gtk3" "gtk4" "both" ];
        default = "both";
      };
    };

    helix.enable = mkEnableOption "Signal theme for Helix editor";
    fuzzel.enable = mkEnableOption "Signal theme for Fuzzel launcher";
    
    terminals = {
      ghostty.enable = mkEnableOption "Signal theme for Ghostty terminal";
      zellij.enable = mkEnableOption "Signal theme for Zellij";
    };

    # Brand governance
    brandGovernance = {
      policy = mkOption {
        type = types.enum [ "functional-override" "separate-layer" "integrated" ];
        default = "functional-override";
        description = ''
          Brand governance policy:
          - functional-override: Functional colors override brand colors
          - separate-layer: Brand colors as decorative layer
          - integrated: Brand colors can replace functional colors (with compliance)
        '';
      };

      decorativeBrandColors = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Decorative brand colors (logos, headers, etc.)";
        example = { brand-primary = "#5a7dcf"; };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Import palette from signal/palette repo
    _module.args.signalPalette = palette;

    # Import per-app modules conditionally
    imports = [
      (lib.mkIf cfg.ironbar.enable ./ironbar)
      (lib.mkIf cfg.gtk.enable ./gtk)
      (lib.mkIf cfg.helix.enable ./editors/helix.nix)
      (lib.mkIf cfg.fuzzel.enable ./desktop/fuzzel.nix)
      # ... other apps
    ];
  };
}
```

**Version Strategy:**
- v1.0.0 = Initial release (5 apps: ironbar, gtk, helix, fuzzel, ghostty)
- v1.1.0 = New app added (e.g., +kitty terminal)
- v1.2.0 = New features (e.g., brand governance enhancements)
- v2.0.0 = Breaking API changes (option renames, module restructure)

---

## Phase-by-Phase Implementation

### Phase 1: Foundation (Week 1-2)

**Goal:** Extract palette and core infrastructure

#### Week 1: signal/palette

**Day 1-2: Create Repository & Extract Colors**
- [ ] Create `signal-palette` repository
- [ ] Extract colors from `modules/shared/features/theming/palette/`
- [ ] Convert to `palette.json` format (OKLCH + hex)
- [ ] Add metadata (philosophy, accessibility notes)

**Day 3-4: Generate Exports**
- [ ] Write script to generate exports from `palette.json`
- [ ] Generate `exports/palette.nix`
- [ ] Generate `exports/palette.css` (CSS custom properties)
- [ ] Generate `exports/palette.js` (for future web use)

**Day 5-6: Documentation**
- [ ] Write README.md (philosophy, usage, exports)
- [ ] Write `docs/philosophy.md` ("Perception, engineered")
- [ ] Write `docs/oklch-explained.md`
- [ ] Write `docs/accessibility.md` (APCA guidelines)

**Day 7: Testing & Polish**
- [ ] Add contrast validation tests
- [ ] Setup GitHub Actions CI
- [ ] Tag v1.0.0
- [ ] Verify exports work

#### Week 2: signal/nix - Infrastructure

**Day 1-2: Create Repository & Structure**
- [ ] Create `signal-nix` repository
- [ ] Setup flake.nix with signal-palette dependency
- [ ] Create module structure (`modules/common.nix`, etc.)
- [ ] Setup lib/ helpers (brandGovernance, accessibility)

**Day 3-4: Common Module**
- [ ] Implement `modules/common.nix` (main interface)
- [ ] Create option system (enable, mode, per-app enables)
- [ ] Setup brand governance options
- [ ] Add tests for option validation

**Day 5-6: Documentation Foundation**
- [ ] Write README.md (installation, quick start, philosophy)
- [ ] Write `docs/installation.md`
- [ ] Write `docs/configuration.md`
- [ ] Setup examples/ directory structure

**Day 7: Testing**
- [ ] Test flake evaluation
- [ ] Test with empty config (just `enable = true`)
- [ ] Verify palette import works
- [ ] Setup GitHub Actions CI

### Phase 2: Flagship Apps (Week 3-4)

**Goal:** Extract and polish 5 core applications

#### Week 3: Ironbar (Flagship)

**Day 1-3: Extract Ironbar**
- [ ] Copy `modules/shared/features/theming/applications/desktop/ironbar-home/`
- [ ] Remove user-specific configurations
- [ ] Map `tokens.nix` to use signal-palette colors
- [ ] Generalize widget configuration
- [ ] Test with clean NixOS VM

**Day 4-5: Profiles & Polish**
- [ ] Create "compact" profile (1080p optimized)
- [ ] Create "relaxed" profile (1440p+ - current)
- [ ] Create "spacious" profile (4K optimized)
- [ ] Add profile selection option
- [ ] Test on different resolutions

**Day 6-7: Documentation & Screenshots**
- [ ] Take screenshots of all widgets
- [ ] Record demo GIF (workspace switching, volume, etc.)
- [ ] Write `docs/applications.md` - Ironbar section
- [ ] Create `examples/ironbar-showcase.nix`
- [ ] Document Niri synchronization

#### Week 4: GTK, Helix, Fuzzel, Ghostty

**Day 1-2: GTK Theme**
- [ ] Extract GTK3/GTK4 theme
- [ ] Map to signal-palette colors
- [ ] Test with GTK apps (Files, Settings, etc.)
- [ ] Screenshot comparisons

**Day 3: Helix Editor**
- [ ] Extract Helix theme
- [ ] Map syntax colors to categorical palette
- [ ] Test with multiple file types
- [ ] Screenshot code examples

**Day 4: Fuzzel Launcher**
- [ ] Extract Fuzzel theme
- [ ] Test integration
- [ ] Screenshot

**Day 5: Ghostty Terminal**
- [ ] Extract Ghostty theme
- [ ] Test with different shells
- [ ] Screenshot

**Day 6-7: Integration & Testing**
- [ ] Create `examples/full-desktop.nix` (all apps)
- [ ] Test all apps together on clean VM
- [ ] Verify consistency across apps
- [ ] Polish documentation

### Phase 3: Documentation & Polish (Week 5)

**Goal:** Professional documentation and examples

**Day 1-2: Core Documentation**
- [ ] Polish README.md with all features
- [ ] Write comprehensive `docs/configuration.md`
- [ ] Write `docs/brand-colors.md` (unique feature)
- [ ] Write `docs/troubleshooting.md`

**Day 3-4: Examples**
- [ ] `examples/basic.nix` - Minimal setup
- [ ] `examples/full-desktop.nix` - All apps
- [ ] `examples/custom-colors.nix` - Brand color overrides
- [ ] `examples/ironbar-showcase.nix` - Complete ironbar config
- [ ] Add comments explaining each option

**Day 5: Comparison Content**
- [ ] Create comparison table (Signal vs Catppuccin vs Gruvbox)
- [ ] Explain positioning ("professional/scientific")
- [ ] Document unique features

**Day 6-7: Visual Assets**
- [ ] Organize all screenshots in assets/
- [ ] Create comparison images (before/after)
- [ ] Create "hero" image for README
- [ ] Record demo video (optional but recommended)

### Phase 4: Launch Preparation (Week 6)

**Goal:** Final polish and launch readiness

**Day 1-2: CI/CD & Testing**
- [ ] Setup comprehensive CI/CD in signal/nix
- [ ] Add per-app tests
- [ ] Add integration tests (multiple apps together)
- [ ] Setup Cachix (optional)
- [ ] Verify all examples work

**Day 3-4: Issue Templates & Contributing**
- [ ] Create issue templates (bug, feature request)
- [ ] Write CONTRIBUTING.md
- [ ] Write CODE_OF_CONDUCT.md (optional)
- [ ] Setup GitHub Discussions
- [ ] Add LICENSE files (MIT recommended)

**Day 5: Final Review**
- [ ] Review all documentation for clarity
- [ ] Check all links work
- [ ] Verify examples are copy-pasteable
- [ ] Test on fresh NixOS install
- [ ] Spell check, grammar check

**Day 6-7: Soft Launch**
- [ ] Share in small Nix communities
- [ ] Post in relevant Discord/Matrix channels
- [ ] Get feedback from 5-10 early adopters
- [ ] Iterate based on feedback

---

## Technical Specifications

### Color Mappings

**How palette maps to applications:**

**Ironbar:**
```nix
# modules/ironbar/tokens.nix
{ signalPalette }:
{
  colors = {
    text = {
      primary = signalPalette.tonal."50";     # Lightest text
      secondary = signalPalette.tonal."300";  # Secondary text
      tertiary = signalPalette.tonal."500";   # Tertiary text
    };
    surface = {
      base = signalPalette.tonal."900";       # Main background
      emphasis = signalPalette.tonal."800";   # Elevated elements
    };
    accent = {
      focus = signalPalette.accent.focus;     # Interactive elements
      warning = signalPalette.accent.warning; # Warning states
      danger = signalPalette.accent.danger;   # Critical states
    };
  };
}
```

**GTK:**
```nix
# modules/gtk/default.nix
gtk.gtk3.extraCss = ''
  @define-color base_color ${signalPalette.tonal."900".hex};
  @define-color text_color ${signalPalette.tonal."50".hex};
  @define-color accent_color ${signalPalette.accent.focus.hex};
  /* ... */
'';
```

**Helix:**
```nix
# modules/editors/helix.nix
programs.helix.settings.theme = {
  "ui.background" = signalPalette.tonal."950".hex;
  "ui.text" = signalPalette.tonal."50".hex;
  "keyword" = signalPalette.categorical.syntax.keyword.hex;
  "function" = signalPalette.categorical.syntax.function.hex;
  /* ... */
};
```

### Brand Governance Implementation

**How to handle brand colors:**

```nix
# User config
theming.signal = {
  enable = true;
  
  brandGovernance = {
    policy = "functional-override";
    decorativeBrandColors = {
      brand-primary = "#custom-blue";
      brand-secondary = "#custom-orange";
    };
  };
};

# Implementation in lib/brandGovernance.nix
{
  # Functional colors ALWAYS used for:
  # - Interactive elements (buttons, links)
  # - Semantic states (success, warning, danger)
  # - Critical UI (text, backgrounds)
  
  # Brand colors ONLY used for:
  # - Logos
  # - Headers/banners
  # - Decorative accents (if policy allows)
}
```

### Accessibility Validation

**APCA Contrast Checks:**

```nix
# lib/accessibility.nix
{ lib }:
{
  # Calculate APCA contrast
  apcaContrast = text: background: 
    # Implementation of APCA algorithm
    # Returns contrast value (0-108)
  
  # Validate text is readable
  assertReadable = text: background: minContrast:
    let contrast = apcaContrast text background;
    in {
      assertion = contrast >= minContrast;
      message = "Insufficient contrast: ${toString contrast} < ${toString minContrast}";
    };
}

# Usage in modules
assertions = [
  (assertReadable 
    signalPalette.tonal."50"  # text
    signalPalette.tonal."900" # background
    60                        # minimum for body text
  )
];
```

---

## Timeline & Milestones

### Overview

**Total Timeline:** 6 weeks to public launch

| Phase | Duration | Deliverable |
|-------|----------|------------|
| Phase 1 | Week 1-2 | Palette repo + Infrastructure |
| Phase 2 | Week 3-4 | 5 core apps extracted & polished |
| Phase 3 | Week 5 | Documentation & examples complete |
| Phase 4 | Week 6 | Launch ready, soft launch, iterate |
| Launch | End Week 6 | Public announcement |

### Critical Path

```
Week 1: signal/palette v1.0.0 ────────┐
Week 2: signal/nix infrastructure ────┤
                                       ├─→ Week 5: Documentation
Week 3: Ironbar (flagship) ───────────┤
Week 4: GTK + 3 more apps ────────────┘
                                           Week 6: Launch
```

### Milestones

**M1: Palette Foundation (Week 1)**
- ✅ signal/palette repository created
- ✅ palette.json with all colors
- ✅ Exports generated (nix, css, js)
- ✅ Philosophy documented
- ✅ v1.0.0 tagged

**M2: Infrastructure Ready (Week 2)**
- ✅ signal/nix repository created
- ✅ Flake with palette dependency
- ✅ Module system in place
- ✅ Brand governance implemented
- ✅ CI/CD working

**M3: Flagship App (Week 3)**
- ✅ Ironbar fully extracted
- ✅ 3 profiles created (compact, relaxed, spacious)
- ✅ Screenshots captured
- ✅ Demo GIF recorded
- ✅ Documentation written

**M4: Full Coverage (Week 4)**
- ✅ 5 core apps themed (ironbar, gtk, helix, fuzzel, ghostty)
- ✅ All apps tested together
- ✅ Consistency verified
- ✅ Examples created

**M5: Documentation Complete (Week 5)**
- ✅ All docs written
- ✅ Examples tested
- ✅ Visual assets organized
- ✅ Comparison content created

**M6: Launch Ready (Week 6)**
- ✅ CI/CD comprehensive
- ✅ Issue templates created
- ✅ Early feedback incorporated
- ✅ Final polish done

**Launch: Public Announcement**
- 📢 NixOS Discourse post
- 📢 r/NixOS Reddit post
- 📢 r/unixporn post (visual appeal)
- 📢 Matrix/Discord announcements

---

## Launch Strategy

### Week 6: Soft Launch (Day 1-4)

**Goals:**
- Get early feedback from 10-20 users
- Identify rough edges
- Validate documentation
- Build initial community

**Channels:**
1. **Matrix (Day 1)**
   - Post in `#nix:nixos.org`
   - Post in relevant Wayland/Niri channels
   - Keep brief, link to repo

2. **Discord (Day 1)**
   - NixOS Discord
   - Relevant compositor discords
   - Share screenshots

3. **Personal Network (Day 2)**
   - Share with friends/colleagues using NixOS
   - Ask for brutal honest feedback

4. **Small Communities (Day 3-4)**
   - Relevant subreddits (r/NixOS daily thread)
   - NixOS Discourse "Show and Tell"
   - Get 5-10 people to try it

**Iteration (Day 5-7):**
- Fix any critical bugs found
- Clarify confusing documentation
- Add missing examples
- Tag v1.0.1 if needed

### Week 6: Public Launch (Day 7+)

**Announcement Post Template:**

```markdown
# Signal - A Scientific Design System for NixOS

> Perception, engineered.

I'm excited to announce Signal v1.0.0, a scientific, OKLCH-based design 
system for NixOS/Home Manager.

## What is Signal?

Signal is a design system where every color is the calculated solution to 
a functional problem. Built on OKLCH color space and accessibility science 
(APCA), it brings professional, consistent theming to your entire desktop.

[Screenshot of desktop here]

## What Makes Signal Different

Unlike traditional color schemes, Signal is:

- **OKLCH-Based**: Perceptually uniform colors (not RGB/HSL)
- **Accessibility-First**: APCA contrast calculations
- **Scientific**: Every color has a calculated purpose
- **Unique Brand Governance**: Separate brand vs functional colors
- **Atomic Design**: Proven methodology from ironbar

## Supported Applications

Initial release includes:
- 🎨 **Desktop**: Ironbar (3 profiles), GTK3/4
- ✏️  **Editors**: Helix
- 💻 **Terminals**: Ghostty
- 🚀 **Launchers**: Fuzzel

[More screenshots]

## Quick Start

```nix
{
  inputs.signal.url = "github:<username>/signal-nix";
  
  theming.signal = {
    enable = true;
    mode = "dark";
    ironbar.enable = true;
    gtk.enable = true;
  };
}
```

## Why OKLCH?

Traditional RGB/HSL colors aren't perceptually uniform - a lightness 
value of 50% looks different for different hues. OKLCH fixes this.

[Comparison image: RGB vs OKLCH]

## Positioning

- **Catppuccin**: Warm, friendly, pastel → cute/cozy
- **Gruvbox**: Retro, warm, vintage → nostalgic
- **Signal**: Professional, minimal, scientific → trustworthy

## Documentation

- 📖 [Installation Guide](link)
- ⚙️ [Configuration Reference](link)
- 🎨 [Philosophy](link)
- 🔬 [OKLCH Explained](link)

## Contributing

Signal is MIT licensed and contributions are welcome! Especially:
- Additional app integrations
- Accessibility improvements
- Documentation enhancements

## Links

- GitHub: [signal/nix](link)
- Palette: [signal/palette](link)
- Docs: [docs site](link)

Looking forward to your feedback!
```

**Distribution Channels:**

1. **NixOS Discourse** (Primary)
   - Category: Announcements
   - Full announcement post
   - Screenshots in post body
   - Link to GitHub

2. **Reddit r/NixOS**
   - Title: "[Release] Signal v1.0.0 - Scientific Design System for NixOS"
   - Same content as Discourse
   - Engage in comments

3. **Reddit r/unixporn** (Visual Focus)
   - Title: "[Niri] Signal Design System - OKLCH-based Professional Theme"
   - Lead with best screenshot
   - Emphasis on visual appeal and atomic design
   - Include dotfiles link

4. **Matrix Announcements**
   - Brief summary + link to full announcement
   - Share in all relevant channels

5. **Hacker News** (Optional, if confident)
   - Title: "Signal - OKLCH-based Design System for Linux"
   - Submit to "Show HN"
   - Only if ready for criticism!

### Post-Launch (Ongoing)

**Week 7-8: Engagement**
- Respond to issues/PRs within 24 hours
- Engage with community feedback
- Share user screenshots/configs

**Week 9-12: Phase 2 Planning**
- Based on feedback, prioritize next apps
- Plan Phase 2 additions
- Build contributor community

**Month 3+: Growth**
- Blog post series on design decisions
- Video tutorials (optional)
- Contribute to NixOS wiki
- Present at local Nix meetups

---

## Success Metrics

### Quantitative Metrics

**Repository Metrics:**
- GitHub stars (target: 50 in first month, 200 in 6 months)
- Forks (target: 10 in first month)
- Weekly clones (from flake usage)

**Usage Metrics:**
- Cachix cache hits (if setup)
- GitHub search mentions
- Issues/discussions activity

**Community Metrics:**
- Reddit upvotes (target: 50+ on announcement)
- Discourse replies/likes
- Contributor count

### Qualitative Metrics

**Impact:**
- Other configs adopting Signal
- Mentions in "awesome-nix" lists
- Derivations/forks appearing

**Quality:**
- Positive feedback on documentation
- Low bug report rate
- Clear use cases emerging

**Community:**
- Active discussions
- PRs from contributors
- Helpful community members

### Initial Goals (Month 1)

- [ ] 50+ GitHub stars on signal/nix
- [ ] 10+ users actively using Signal
- [ ] 5+ issues/discussions (shows engagement)
- [ ] 1+ contributor PR
- [ ] Featured in one "awesome" list

### Long-term Vision (Year 1)

- [ ] 200+ GitHub stars
- [ ] 50+ active users
- [ ] 10+ supported applications
- [ ] 3+ active contributors
- [ ] Referenced in NixOS wiki
- [ ] 1+ derivative projects

---

## Future Evolution

### Phase 2: Expand Coverage (Month 2-3)

**Additional Applications:**
- Terminals: kitty, alacritty, wezterm
- Editors: neovim, vscode (via extension)
- CLI: fzf, bat, yazi, lazygit (already exist, need polish)
- Desktop: mako, swaync, satty
- Browsers: Firefox (CSS for UI)

**Community Contributions:**
- Create "good first issue" labels
- Write contribution guide per app type
- Mentor new contributors

### Phase 3: Cross-Platform (Month 4-6)

**signal/web** - Static site theme
- CSS framework based on Signal palette
- Example website/portfolio
- Tailwind plugin
- Astro theme

**signal/react** (Future)
- React component library
- Styled with Signal colors
- Professional UI kit

**signal/figma** (Future)
- Figma plugin for Signal palette
- Design token import
- Professional design files

### Phase 4: Advanced Features (Month 6-12)

**Dynamic Color Schemes:**
- User-adjustable OKLCH values
- Real-time preview
- Accessibility validation

**CLI Tool:**
- `signal-export` - Generate configs
- `signal-validate` - Check accessibility
- `signal-preview` - Live theme preview

**Better Integration:**
- systemd color-scheme.target
- Automatic light/dark switching
- Per-app overrides

### Governance Model

**Maintainer Structure:**
- Core maintainer (you): Overall direction, palette, core modules
- App maintainers: Own specific app integrations
- Community contributors: PRs reviewed by maintainers

**Decision Making:**
- Core philosophy/colors: Maintainer decision
- New apps: Community input welcome
- Bug fixes: Fast track
- Breaking changes: Require discussion

---

## Checklist Summary

### Pre-Launch Checklist

**signal/palette:**
- [ ] Repository created
- [ ] palette.json complete with all colors
- [ ] All exports generated (nix, css, js)
- [ ] Documentation written (philosophy, OKLCH, accessibility)
- [ ] Tests passing
- [ ] v1.0.0 tagged
- [ ] MIT license

**signal/nix:**
- [ ] Repository created
- [ ] Flake working with palette dependency
- [ ] Module system complete
- [ ] 5 core apps extracted and tested
- [ ] All examples working
- [ ] Documentation complete
- [ ] CI/CD setup
- [ ] Issue templates created
- [ ] v1.0.0 tagged
- [ ] MIT license

**Visual Assets:**
- [ ] Hero image for README
- [ ] Per-app screenshots
- [ ] Comparison images
- [ ] Demo GIF/video
- [ ] Before/after comparisons

**Documentation:**
- [ ] README.md polished (both repos)
- [ ] Installation guide complete
- [ ] Configuration reference complete
- [ ] Philosophy explained
- [ ] OKLCH benefits documented
- [ ] Examples tested and working
- [ ] Troubleshooting guide
- [ ] CONTRIBUTING.md
- [ ] CHANGELOG.md

**Testing:**
- [ ] All apps tested individually
- [ ] All apps tested together
- [ ] Tested on clean NixOS VM
- [ ] Examples all work
- [ ] No broken links in docs
- [ ] CI passing

**Community:**
- [ ] Soft launch complete (10+ testers)
- [ ] Early feedback incorporated
- [ ] Discord/Matrix channels joined
- [ ] Announcement posts drafted

### Launch Day Checklist

**Morning:**
- [ ] Final check: All tests passing
- [ ] Final review: Documentation
- [ ] Tag final releases (v1.0.0)
- [ ] Verify GitHub releases created

**Afternoon:**
- [ ] Post to NixOS Discourse
- [ ] Post to r/NixOS
- [ ] Post to r/unixporn
- [ ] Share in Matrix channels
- [ ] Share in Discord servers
- [ ] Tweet/post on social media

**Evening:**
- [ ] Monitor for initial feedback
- [ ] Respond to comments/questions
- [ ] Triage any critical bugs
- [ ] Thank early adopters

### Post-Launch (Week 1)

- [ ] Respond to all issues within 24h
- [ ] Engage in discussions
- [ ] Fix critical bugs (v1.0.1 if needed)
- [ ] Thank contributors
- [ ] Share user screenshots
- [ ] Start planning Phase 2

---

## Notes & Decisions

### Design Decisions Log

**Why separate palette from nix?**
- Platform-agnostic colors can be reused
- Stable versioning for colors vs implementations
- Future-proof for web/react/other platforms

**Why not separate per app?**
- Too complex for single maintainer
- Version coordination nightmare
- User confusion (which versions work together?)
- Catppuccin uses monorepo for Nix

**Why MIT license?**
- Most permissive
- Allows commercial use
- Compatible with nixpkgs
- Standard in Nix community

**Why OKLCH vs other color spaces?**
- Perceptually uniform lightness
- Better for accessibility
- Modern standard (CSS Color 4)
- Future-proof

**Why "Signal" name?**
- Short, memorable
- Signal vs noise (clarity)
- Perception-focused
- Professional connotation

### Open Questions

**Q: Should we have a light mode in v1.0.0?**
A: Start with dark mode only, add light in v1.1.0 based on demand.

**Q: How to handle user customization?**
A: Brand governance system for organization colors, full palette override for power users.

**Q: What about non-Nix users?**
A: signal/palette as JSON/CSS is usable anywhere, just not automated.

**Q: Contributing guidelines for new apps?**
A: Write after v1.0.0, based on patterns from first 5 apps.

---

## Resources

### References

- [Catppuccin/nix](https://github.com/catppuccin/nix) - Monorepo pattern
- [OKLCH Color Space](https://oklch.com) - Color theory
- [APCA](https://github.com/Myndex/SAPC-APCA) - Accessibility contrast
- [Atomic Design](https://atomicdesign.bradfrost.com/) - Design methodology
- [Nix Manual](https://nixos.org/manual/nix/stable/) - Flake structure

### Tools

- [OKLCH Color Picker](https://oklch.com)
- [Contrast Checker](https://www.myndex.com/APCA/)
- [Nix Flake Utils](https://github.com/numtide/flake-utils)
- [Blueprint](https://github.com/numtide/blueprint) - Future consideration

### Community

- [NixOS Discourse](https://discourse.nixos.org)
- [r/NixOS](https://reddit.com/r/NixOS)
- [r/unixporn](https://reddit.com/r/unixporn)
- [NixOS Matrix](https://matrix.to/#/#community:nixos.org)

---

## Appendix

### Example User Configuration

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    signal.url = "github:<username>/signal-nix";
  };

  outputs = { nixpkgs, home-manager, signal, ... }: {
    homeConfigurations.user = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        signal.homeManagerModules.default
        {
          theming.signal = {
            enable = true;
            mode = "dark";
            
            # Enable apps
            ironbar = {
              enable = true;
              profile = "relaxed"; # 1440p optimized
            };
            gtk.enable = true;
            helix.enable = true;
            fuzzel.enable = true;
            terminals.ghostty.enable = true;
            
            # Optional: Brand colors
            brandGovernance = {
              policy = "functional-override";
              decorativeBrandColors = {
                brand-primary = "#custom-blue";
              };
            };
          };
        }
      ];
    };
  };
}
```

### Color Extraction Script

```bash
#!/usr/bin/env bash
# Extract colors from existing theming modules

# Convert Nix colors to JSON
nix eval --json .#theming.palette.tonal > tonal.json
nix eval --json .#theming.palette.accent > accent.json
nix eval --json .#theming.palette.categorical > categorical.json

# Combine into palette.json
jq -s '.[0] as $tonal | .[1] as $accent | .[2] as $cat |
  {
    name: "Signal Design System",
    version: "1.0.0",
    colorSpace: "OKLCH",
    tonal: $tonal,
    accent: $accent,
    categorical: $cat
  }' tonal.json accent.json categorical.json > palette.json
```

---

**END OF PLAN**

This document will be updated as the project progresses.
Last updated: 2026-01-16
