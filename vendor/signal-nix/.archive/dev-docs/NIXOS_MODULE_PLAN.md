# NixOS Module Implementation Plan

> **Project Goal**: Extend Signal Design System to support NixOS system-level theming alongside existing Home Manager modules.

## Architecture Overview

Signal will provide two parallel module systems:

```
signal-nix/
├── homeManagerModules/     # Existing: User-level theming
│   └── default            # Terminal, editors, CLI tools, etc.
│
└── nixosModules/          # New: System-level theming
    ├── default            # All system theming
    ├── boot               # Bootloader, Plymouth, TTY
    ├── login              # Display managers
    ├── desktop            # System-level DE components
    └── system             # System services & utilities
```

## Design Principles

1. **Follow Native NixOS Options**: Use official NixOS module options wherever possible
2. **Colors Only**: Never configure behavior, layout, fonts, or enable services
3. **Official Documentation**: Research each component's official theming documentation
4. **Minimal Override**: Only set color-related options
5. **Parallel Architecture**: Keep NixOS and Home Manager modules separate
6. **Same Color System**: Use identical signal-palette colors across both

## Priority Levels

- **P0**: Essential, high-impact, commonly used
- **P1**: Important, frequently used
- **P2**: Nice-to-have, moderate usage
- **P3**: Low priority, niche use cases
- **P4**: Future consideration

---

## Implementation Roadmap

### Phase 1: Foundation & Boot (P0)

Essential system-level components that users see daily.

#### 1.1 Virtual Console / TTY Colors (P0)
**Impact**: High - Emergency access, virtual terminals  
**Complexity**: Low  
**Module**: `nixosModules.boot.console`

**NixOS Options**:
```nix
console.colors = [
  # Array of 16 ANSI colors (hex without #)
  "1a1c22"  # color0 - black
  "e06c75"  # color1 - red
  # ... colors 2-15
];
```

**Research Required**:
- [ ] NixOS documentation: `console.colors` format
- [ ] Verify hex format (with or without `#`)
- [ ] Test on actual TTY (Ctrl+Alt+F1)
- [ ] Ensure ANSI 16-color mapping matches terminals

**Implementation Notes**:
- Use Signal's existing ANSI palette from terminal modules
- Map to exact same colors as Ghostty/Alacritty for consistency
- No `#` prefix in hex values

**Files to Create**:
```
modules/nixos/boot/console.nix
```

---

#### 1.2 GRUB Bootloader Theme (P0)
**Impact**: High - First thing users see  
**Complexity**: Medium  
**Module**: `nixosModules.boot.grub`

**NixOS Options**:
```nix
boot.loader.grub = {
  theme = pkgs.nixos-grub2-theme;  # Or custom theme package
  backgroundColor = "#1a1c22";
  # Note: Limited color customization without custom theme
};
```

**Research Required**:
- [ ] GRUB2 theme.txt format specification
- [ ] How to create custom GRUB theme package in Nix
- [ ] Color options: text, selected, background, border
- [ ] Font rendering and fallbacks
- [ ] Test in VM (requires reboot to verify)

**Implementation Notes**:
- Create custom GRUB theme package with Signal colors
- Follow GRUB theme.txt format
- Provide theme as `pkgs.signal-grub-theme`
- Include both dark and light variants

**Files to Create**:
```
modules/nixos/boot/grub.nix
pkgs/grub-theme/default.nix
pkgs/grub-theme/theme.txt.nix  (generated)
```

**Theme.txt Structure**:
```
# Global properties
title-text: ""
desktop-image: "background.png"
desktop-color: "#1a1c22"
terminal-font: "Terminus Regular 16"

# Menu styling
+ boot_menu {
  left = 15%
  top = 20%
  width = 70%
  height = 60%
  item_color = "#c5cdd8"
  selected_item_color = "#6b87c8"
  item_font = "Terminus Regular 16"
  item_height = 32
  item_padding = 8
  item_spacing = 4
}
```

---

#### 1.3 Plymouth Boot Splash (P1)
**Impact**: Medium - Visual boot experience  
**Complexity**: High  
**Module**: `nixosModules.boot.plymouth`

**NixOS Options**:
```nix
boot.plymouth = {
  enable = true;
  theme = "signal";  # Custom theme name
  themePackages = [ pkgs.signal-plymouth-theme ];
};
```

**Research Required**:
- [ ] Plymouth .plymouth and .script file format
- [ ] How to create custom Plymouth theme in Nix
- [ ] Animation capabilities (progress bar, spinner)
- [ ] Image requirements (logo, background)
- [ ] Color interpolation in Plymouth scripts

**Implementation Notes**:
- Plymouth themes are complex (image + script)
- Start with simple solid color + logo design
- Progress bar uses Signal accent color
- Background uses Signal surface color

**Files to Create**:
```
modules/nixos/boot/plymouth.nix
pkgs/plymouth-theme/default.nix
pkgs/plymouth-theme/signal.plymouth
pkgs/plymouth-theme/signal.script
pkgs/plymouth-theme/images/logo.png
```

**Plymouth Script Example**:
```
Window.SetBackgroundTopColor(0.10, 0.11, 0.13);  # surface-Lc05
Window.SetBackgroundBottomColor(0.10, 0.11, 0.13);

# Progress bar
progress_bar.color = {
  r = 0.42,  # Signal focus color
  g = 0.53,
  b = 0.78
};
```

---

### Phase 2: Display Managers (P0)

Login screens are high-impact user touchpoints.

#### 2.1 GDM (GNOME Display Manager) (P0)
**Impact**: High - Most popular display manager  
**Complexity**: High  
**Module**: `nixosModules.login.gdm`

**NixOS Options**:
```nix
services.xserver.displayManager.gdm = {
  enable = true;  # User sets this
  # Theming via GSettings overrides
};

# Apply via extraGSettingsOverrides
services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
  [org.gnome.desktop.interface]
  gtk-theme='Signal-Dark'
'';
```

**Research Required**:
- [ ] GDM uses GTK4 - research GTK4 theming
- [ ] GResource compilation for GTK themes
- [ ] GSettings schema for GDM overrides
- [ ] CSS overrides for login screen
- [ ] Background image vs solid color

**Implementation Notes**:
- GDM theming is complex - uses GTK theme
- May need to generate GTK4 theme (see Phase 3)
- CSS overrides in `/etc/gdm/greeter.dconf-defaults`
- Background color via GSettings

**Files to Create**:
```
modules/nixos/login/gdm.nix
pkgs/gdm-background/default.nix
```

---

#### 2.2 SDDM (KDE Display Manager) (P0)
**Impact**: High - KDE/Qt users  
**Complexity**: Medium  
**Module**: `nixosModules.login.sddm`

**NixOS Options**:
```nix
services.displayManager.sddm = {
  enable = true;  # User sets this
  theme = "signal";
  settings = {
    Theme = {
      Current = "signal";
      CursorTheme = "breeze";
    };
  };
};
```

**Research Required**:
- [ ] SDDM theme.conf format
- [ ] QML component structure for SDDM themes
- [ ] Required QML files (Main.qml, Login.qml, etc.)
- [ ] Color properties in QML
- [ ] Background image handling

**Implementation Notes**:
- SDDM themes are QML-based (Qt)
- Simpler than GDM (declarative QML)
- Package theme and reference it

**Files to Create**:
```
modules/nixos/login/sddm.nix
pkgs/sddm-theme/default.nix
pkgs/sddm-theme/Main.qml
pkgs/sddm-theme/theme.conf
pkgs/sddm-theme/metadata.desktop
```

**Main.qml Example**:
```qml
Rectangle {
    color: "#1a1c22"  // Signal surface
    
    TextField {
        color: "#c5cdd8"  // Signal text
        selectionColor: "#6b87c8"  // Signal focus
    }
}
```

---

#### 2.3 LightDM (P1)
**Impact**: Medium - Still used  
**Complexity**: Medium  
**Module**: `nixosModules.login.lightdm`

**NixOS Options**:
```nix
services.xserver.displayManager.lightdm = {
  enable = true;
  greeters.gtk = {
    theme.name = "Signal-Dark";
  };
};
```

**Research Required**:
- [ ] LightDM greeter options (GTK, webkit, etc.)
- [ ] GTK greeter theme configuration
- [ ] Background configuration
- [ ] Icon theme integration

**Implementation Notes**:
- Reuse GTK theme from Home Manager
- Configure greeter to use Signal GTK theme

**Files to Create**:
```
modules/nixos/login/lightdm.nix
```

---

#### 2.4 GREETD/tuigreet (P2)
**Impact**: Low - Wayland-native users  
**Complexity**: Low  
**Module**: `nixosModules.login.greetd`

**NixOS Options**:
```nix
services.greetd = {
  enable = true;
  settings = {
    default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet ...";
    };
  };
};
```

**Research Required**:
- [ ] tuigreet color configuration options
- [ ] ANSI color support
- [ ] Border and UI element colors

**Implementation Notes**:
- TUI greeter - similar to terminal theming
- Pass color flags to tuigreet command
- May support environment variables for colors

**Files to Create**:
```
modules/nixos/login/greetd.nix
```

---

### Phase 3: System-Wide Desktop Theming (P1)

Components that affect the entire desktop environment.

#### 3.1 System-Wide GTK Theme (P1)
**Impact**: High - Affects all GTK apps  
**Complexity**: High  
**Module**: `nixosModules.desktop.gtk`

**NixOS Options**:
```nix
# System-wide GTK theme (affects GDM, root apps, etc.)
environment.systemPackages = [ pkgs.signal-gtk-theme ];

# GSettings defaults
services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
  [org.gnome.desktop.interface]
  gtk-theme='Signal-Dark'
'';
```

**Research Required**:
- [ ] GTK3 CSS theme structure
- [ ] GTK4 CSS differences
- [ ] GResource compilation
- [ ] Color variable naming conventions
- [ ] Theme installation paths

**Implementation Notes**:
- Can reuse Home Manager GTK theme colors
- Package as system-wide theme
- Install to `/run/current-system/sw/share/themes/`

**Files to Create**:
```
modules/nixos/desktop/gtk.nix
pkgs/gtk-theme/default.nix
pkgs/gtk-theme/gtk-3.0/gtk.css
pkgs/gtk-theme/gtk-4.0/gtk.css
```

---

#### 3.2 System-Wide Qt Theme (P1)
**Impact**: Medium - KDE/Qt apps  
**Complexity**: High  
**Module**: `nixosModules.desktop.qt`

**NixOS Options**:
```nix
qt = {
  enable = true;
  platformTheme = "qt5ct";
  style = "signal";
};
```

**Research Required**:
- [ ] Qt5/Qt6 styling system
- [ ] QSS (Qt Style Sheets) format
- [ ] Creating custom Qt theme
- [ ] Color palette configuration

**Implementation Notes**:
- Qt theming is complex
- May use QSS stylesheets
- Consider using qt5ct/qt6ct

**Files to Create**:
```
modules/nixos/desktop/qt.nix
pkgs/qt-theme/default.nix
pkgs/qt-theme/signal.qss
```

---

#### 3.3 Cursor Theme (P2)
**Impact**: Low - Visual polish  
**Complexity**: Low  
**Module**: `nixosModules.desktop.cursor`

**NixOS Options**:
```nix
environment.systemPackages = [ pkgs.signal-cursor-theme ];
```

**Research Required**:
- [ ] Xcursor format and tools
- [ ] Cursor sizes and variants
- [ ] How to generate cursor themes
- [ ] Color application to cursors

**Implementation Notes**:
- Low priority - cursors are small
- Can use existing cursor theme with color filter
- Or generate custom cursors

**Files to Create**:
```
modules/nixos/desktop/cursor.nix
pkgs/cursor-theme/default.nix
```

---

#### 3.4 Icon Theme (P2)
**Impact**: Low - Visual consistency  
**Complexity**: High  
**Module**: `nixosModules.desktop.icons`

**NixOS Options**:
```nix
environment.systemPackages = [ pkgs.signal-icon-theme ];
```

**Research Required**:
- [ ] Icon theme specification (freedesktop)
- [ ] SVG color replacement
- [ ] Icon sizes and variants
- [ ] Inheritance from base icon theme

**Implementation Notes**:
- Very low priority - huge undertaking
- Consider color-filtered existing theme
- Or just provide accent color icons

**Files to Create**:
```
modules/nixos/desktop/icons.nix
pkgs/icon-theme/default.nix
```

---

### Phase 4: System Tools & Services (P2)

System-level utilities and background services.

#### 4.1 System-Wide dmenu/rofi (P2)
**Impact**: Medium - Launcher users  
**Complexity**: Low  
**Module**: `nixosModules.system.launchers`

**NixOS Options**:
```nix
programs.dmenu = {
  enable = true;  # User sets
  # No color options - must use wrapper script
};

programs.rofi = {
  enable = true;
  theme = "signal";
};
```

**Research Required**:
- [ ] dmenu color command-line flags
- [ ] rofi theme format (.rasi)
- [ ] System-wide vs user config

**Implementation Notes**:
- rofi has theme files
- dmenu uses command-line colors
- May conflict with Home Manager user settings

**Files to Create**:
```
modules/nixos/system/dmenu.nix
modules/nixos/system/rofi.nix
pkgs/rofi-theme/signal.rasi
```

---

#### 4.2 System-Wide nano (P2)
**Impact**: Low - Emergency editing  
**Complexity**: Low  
**Module**: `nixosModules.system.nano`

**NixOS Options**:
```nix
programs.nano = {
  enable = true;
  nanorc = ''
    # Syntax highlighting colors
    color brightwhite ...
  '';
};
```

**Research Required**:
- [ ] nanorc syntax highlighting format
- [ ] Available color names
- [ ] Regex patterns for syntax

**Implementation Notes**:
- Simple text-based config
- Only affects root/system nano

**Files to Create**:
```
modules/nixos/system/nano.nix
```

---

#### 4.3 System-Wide vim (P2)
**Impact**: Low - Emergency editing  
**Complexity**: Medium  
**Module**: `nixosModules.system.vim`

**NixOS Options**:
```nix
programs.vim = {
  enable = true;
  defaultEditor = true;
  # No direct color options
};

# Must create colorscheme file
```

**Research Required**:
- [ ] Vim colorscheme format
- [ ] System-wide colorscheme installation
- [ ] Minimal viable colorscheme

**Implementation Notes**:
- Create vim colorscheme
- Install system-wide
- Low priority - users customize heavily

**Files to Create**:
```
modules/nixos/system/vim.nix
pkgs/vim-colorscheme/signal.vim
```

---

### Phase 5: Advanced System Components (P3)

Specialized components for specific use cases.

#### 5.1 systemd Journal Colors (P3)
**Impact**: Low - Developers/admins  
**Complexity**: Low  
**Module**: `nixosModules.system.journald`

**NixOS Options**:
```nix
# journalctl uses SYSTEMD_COLORS env var
environment.variables.SYSTEMD_COLORS = "1";
```

**Research Required**:
- [ ] journalctl color configuration
- [ ] Environment variables for colors
- [ ] Terminal-based coloring

**Implementation Notes**:
- journalctl respects terminal colors
- May not need explicit configuration

**Files to Create**:
```
modules/nixos/system/journald.nix
```

---

#### 5.2 OpenRGB (Keyboard Backlighting) (P3)
**Impact**: Low - Gaming/RGB hardware  
**Complexity**: Medium  
**Module**: `nixosModules.system.openrgb`

**NixOS Options**:
```nix
services.hardware.openrgb = {
  enable = true;
  # No direct theme support
};
```

**Research Required**:
- [ ] OpenRGB profile format
- [ ] Color application API
- [ ] Per-key RGB mapping

**Implementation Notes**:
- Very specialized
- Low priority
- Create OpenRGB profile with Signal colors

**Files to Create**:
```
modules/nixos/system/openrgb.nix
pkgs/openrgb-profile/signal.orp
```

---

#### 5.3 swaylock System Service (P3)
**Impact**: Low - Wayland lock screen  
**Complexity**: Low  
**Module**: `nixosModules.system.swaylock`

**NixOS Options**:
```nix
# Usually user-level, but can be system
security.pam.services.swaylock = {};
```

**Research Required**:
- [ ] swaylock color options
- [ ] System-wide vs user config
- [ ] PAM integration

**Implementation Notes**:
- Usually Home Manager territory
- System config for defaults only

**Files to Create**:
```
modules/nixos/system/swaylock.nix
```

---

### Phase 6: Niche/Future Components (P4)

Low-priority or experimental components.

#### 6.1 Framebuffer Applications (P4)
- fbterm
- fbida
- Direct framebuffer apps

#### 6.2 Serial Console (P4)
- Serial terminal colors
- IPMI/SOL console

#### 6.3 UEFI Theme (P4)
- Very hardware-specific
- Limited support

---

## Implementation Strategy

### Stage 1: Foundation (Week 1-2)
1. Create NixOS module structure
2. Implement console colors (1.1)
3. Test basic architecture

### Stage 2: Boot Experience (Week 3-4)
4. Implement GRUB theme (1.2)
5. Test in VM
6. Document boot theming

### Stage 3: Display Managers (Week 5-8)
7. Implement SDDM (2.2) - easier than GDM
8. Implement GDM (2.1)
9. Test both display managers
10. Document login theming

### Stage 4: System Desktop (Week 9-10)
11. Package GTK theme system-wide (3.1)
12. Test with GDM integration
13. Document system theming

### Stage 5: System Tools (Week 11-12)
14. Implement remaining P2 items
15. Create comprehensive tests
16. Write migration guide

### Stage 6: Polish & Release (Week 13-14)
17. Documentation
18. Examples
19. Announcement

---

## Module Structure

### Directory Layout
```
signal-nix/
├── modules/
│   ├── home-manager/          # Rename from current structure
│   │   ├── common/
│   │   ├── editors/
│   │   └── ...
│   │
│   └── nixos/                 # New NixOS modules
│       ├── common/
│       │   └── default.nix    # Core NixOS options
│       ├── boot/
│       │   ├── console.nix
│       │   ├── grub.nix
│       │   └── plymouth.nix
│       ├── login/
│       │   ├── gdm.nix
│       │   ├── sddm.nix
│       │   ├── lightdm.nix
│       │   └── greetd.nix
│       ├── desktop/
│       │   ├── gtk.nix
│       │   ├── qt.nix
│       │   ├── cursor.nix
│       │   └── icons.nix
│       └── system/
│           ├── dmenu.nix
│           ├── rofi.nix
│           ├── nano.nix
│           └── vim.nix
│
├── pkgs/                      # New theme packages
│   ├── grub-theme/
│   ├── plymouth-theme/
│   ├── sddm-theme/
│   ├── gtk-theme/
│   └── ...
│
└── flake.nix                  # Export nixosModules
```

### Flake Structure
```nix
{
  outputs = {
    # Existing
    homeManagerModules = {
      default = ...;
      signal = ...;
    };
    
    # New
    nixosModules = {
      default = ...;           # All NixOS modules
      boot = ...;              # Just boot components
      login = ...;             # Just display managers
      desktop = ...;           # Just desktop theming
      system = ...;            # Just system tools
    };
    
    # Theme packages
    packages = forAllSystems (system: {
      signal-grub-theme = ...;
      signal-plymouth-theme = ...;
      signal-sddm-theme = ...;
      signal-gtk-theme = ...;
    });
  };
}
```

---

## Configuration Examples

### Full System Theming
```nix
{
  imports = [
    signal.nixosModules.default
    signal.homeManagerModules.default
  ];

  # System-level theming
  theming.signal.nixos = {
    enable = true;
    mode = "dark";
    autoEnable = true;  # Theme all enabled system components
    
    boot = {
      console.enable = true;
      grub.enable = true;
      plymouth.enable = true;
    };
    
    login = {
      gdm.enable = true;  # Or sddm, lightdm
    };
    
    desktop = {
      gtk.enable = true;
      qt.enable = true;
    };
  };

  # User-level theming (Home Manager)
  home-manager.users.alice = {
    theming.signal = {
      enable = true;
      mode = "dark";
      autoEnable = true;
    };
  };
}
```

### Boot-Only Theming
```nix
{
  imports = [ signal.nixosModules.boot ];

  theming.signal.nixos.boot = {
    console.enable = true;
    grub.enable = true;
    plymouth.enable = true;
  };
}
```

---

## Testing Strategy

### 1. VM Testing
- Create test VMs with different configurations
- Test boot sequences
- Test display managers
- Screenshot verification

### 2. Real Hardware Testing
- Test on actual machines
- Verify TTY colors (Ctrl+Alt+F1)
- Test boot sequence
- Test display manager login

### 3. Integration Tests
```nix
# tests/nixos/console-colors.nix
{
  name = "console-colors";
  nodes.machine = {
    imports = [ signal.nixosModules.boot ];
    theming.signal.nixos.boot.console.enable = true;
  };
  
  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("grep -q '1a1c22' /etc/console-setup/colors")
  '';
}
```

### 4. Visual Regression Testing
- Screenshot comparison
- Color accuracy verification
- Cross-platform consistency

---

## Documentation Requirements

### 1. Main README Update
- Add NixOS module section
- Show both Home Manager and NixOS usage
- Clear separation of concerns

### 2. NixOS Getting Started Guide
```markdown
# NixOS Setup

## System-Level Theming

Signal can theme NixOS system components...

### Quick Start
[configuration examples]

### What Gets Themed
[list of components]
```

### 3. Per-Component Documentation
- Each component needs:
  - What it themes
  - Configuration options
  - Screenshots
  - Troubleshooting

### 4. Migration Guide
- How to adopt NixOS modules
- Conflicts with Home Manager
- Best practices

---

## Success Criteria

### Phase 1 (MVP)
- [ ] Console colors work
- [ ] GRUB theme applies
- [ ] Basic NixOS module structure
- [ ] Tests pass
- [ ] Documentation exists

### Phase 2 (Complete)
- [ ] All P0 items implemented
- [ ] All P1 items implemented
- [ ] Comprehensive tests
- [ ] Full documentation
- [ ] Example configurations

### Phase 3 (Polish)
- [ ] P2 items implemented
- [ ] Visual regression tests
- [ ] Screenshots for all components
- [ ] Community feedback incorporated

---

## Open Questions

1. **Conflict Resolution**: How do NixOS modules interact with Home Manager modules?
   - Example: System GTK theme vs user GTK theme
   - Resolution: NixOS provides defaults, Home Manager overrides

2. **Color Consistency**: How to ensure colors match between system and user?
   - Both use same signal-palette
   - Same resolveThemeMode logic
   - Shared color resolution library

3. **Testing**: How to test boot components without rebooting?
   - VM testing with snapshots
   - File content verification
   - Mock services for unit tests

4. **Package Distribution**: Should theme packages be separate outputs?
   - Yes - allows users to use themes without full module
   - Packages available as `pkgs.signal-grub-theme`

5. **Performance**: Impact of system-wide themes on boot time?
   - Minimal - themes are pre-built
   - No runtime generation
   - Monitor in tests

---

## Next Steps

1. **Create initial structure**
   ```bash
   mkdir -p modules/nixos/{common,boot,login,desktop,system}
   mkdir -p pkgs/{grub-theme,plymouth-theme,sddm-theme}
   ```

2. **Start with console colors** (simplest component)
   - Implement `modules/nixos/boot/console.nix`
   - Test in VM
   - Verify colors match terminal modules

3. **Update flake.nix**
   - Add nixosModules outputs
   - Export packages

4. **Create first test**
   - NixOS test for console colors
   - Verify configuration applies

5. **Document as we go**
   - Keep this plan updated
   - Document each component
   - Create examples

---

## Resources & References

### NixOS Documentation
- https://nixos.org/manual/nixos/stable/
- https://search.nixos.org/options
- https://nixos.wiki/

### Component-Specific
- GRUB Theming: https://www.gnu.org/software/grub/manual/grub/html_node/Theme-file-format.html
- Plymouth: https://www.freedesktop.org/wiki/Software/Plymouth/
- SDDM Themes: https://github.com/sddm/sddm/wiki/Themes
- GDM Theming: https://wiki.archlinux.org/title/GDM#Theme
- GTK Themes: https://docs.gtk.org/gtk3/css-overview.html

### Existing Theme Projects (for reference)
- Catppuccin NixOS: https://github.com/catppuccin/nix
- Stylix: https://github.com/danth/stylix
- base16 templates: https://github.com/base16-project

---

## Contributors

This plan will be executed by the Signal development team with community contributions welcome.

**Current Status**: Planning Phase  
**Last Updated**: 2026-01-17  
**Version**: 1.0
