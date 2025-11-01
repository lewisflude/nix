# Catppuccin Theme Coverage Analysis

## Important: About `catppuccin.enable = true`

**`catppuccin.enable = true` DOES automatically enable all catppuccin modules** that default to it!

Most application modules default to `catppuccin.enable`, so when you set `catppuccin.enable = true`, they are automatically enabled. For example:

- `catppuccin.enable = true` - Enables base functionality AND defaults all modules to enabled
- `catppuccin.delta.enable` - Defaults to `catppuccin.enable` (so enabled automatically)
- `catppuccin.helix.enable` - Defaults to `catppuccin.enable` (so enabled automatically)
- `catppuccin.helix.flavor` - Defaults to `catppuccin.flavor` (inherits your flavor setting)

You can still override individual modules if needed:

- `catppuccin.delta.enable = false` - Disable delta even if base is enabled
- `catppuccin.helix.useItalics = true` - Override specific helix settings

**Since you have `catppuccin.enable = true` in your config, all modules that default to it should already be enabled!**

## Currently Themed ✅

### System-Level (NixOS)

- **waybar** - ✅ Using `catppuccin.waybar`
- **mako** - ✅ Using `catppuccin.mako`
- **swaync** - ✅ Using `catppuccin.swaync`
- **firefox** - ✅ Using `catppuccin.firefox`
- **GTK** - ✅ Using `catppuccin.gtk` + `magnetic-catppuccin-gtk`
- **Cursors** - ✅ Using `catppuccin.cursors.mochaMauve`

### Applications (Manual/Theme Config)

- **bat** - ✅ Manual theme: `"Catppuccin Mocha"`
- **cursor/vscode** - ✅ Manual theme: `"Catppuccin Mocha"`
- **fuzzel** - ✅ Manual colors from palette

## Missing Catppuccin Theming ❌

**Note**: Since you have `catppuccin.enable = true`, most modules should already be enabled automatically. However, some modules may need explicit configuration or might not be applied if the application isn't properly configured. Check each application to verify theming is working.

### Applications That Should Already Be Enabled (via `catppuccin.enable = true`)

These should be themed automatically, but verify they're working:

1. **delta** - Should be enabled via `catppuccin.enable`
2. **atuin** - Should be enabled via `catppuccin.enable`
3. **ghostty** - Should be enabled via `catppuccin.enable`
4. **helix** - Should be enabled via `catppuccin.enable`
5. **zellij** - Should be enabled via `catppuccin.enable`
6. **yazi** - Should be enabled via `catppuccin.enable`
7. **lazygit** - Should be enabled via `catppuccin.enable`
8. **eza** - Should be enabled via `catppuccin.enable`
9. **fzf** - Should be enabled via `catppuccin.enable`
10. **micro** - Should be enabled via `catppuccin.enable`
11. **zed** - Should be enabled via `catppuccin.enable`
12. **btop** - Should be enabled via `catppuccin.enable`
13. **wofi** - Should be enabled via `catppuccin.enable` (Linux only)
14. **chromium** - Should be enabled via `catppuccin.enable` (Linux only)
15. **thunderbird** - Should be enabled via `catppuccin.enable` (Linux only)

### Modules That May Need Explicit Configuration

Some modules might need explicit enabling or have platform-specific requirements:

- **mako** - You have `mako.enable = lib.mkIf platformLib.isLinux true` (explicit)
- **swaync** - You have `swaync.enable = lib.mkIf platformLib.isLinux true` (explicit)
- **waybar** - You have `waybar.mode = "createLink"` (explicit config)
- **firefox** - You have explicit profile configuration (explicit)

### System-Level (NixOS modules, not Home Manager)

These need to be configured in NixOS modules, not Home Manager:

1. **grub** (`catppuccin.grub`)
    - **Status**: Not configured
    - **Location**: `modules/nixos/core/boot.nix`
    - **Impact**: Bootloader theme not applied
    - **Note**: Only relevant if using GRUB bootloader

2. **plymouth** (`catppuccin.plymouth`)
    - **Status**: Not configured
    - **Impact**: Boot splash screen not themed
    - **Note**: Only relevant if Plymouth is enabled

3. **sddm** (`catppuccin.sddm`)
    - **Status**: Not configured
    - **Impact**: Display manager not themed (if using SDDM)
    - **Note**: You're using Niri, so SDDM may not be relevant

4. **tty** (`catppuccin.tty`)
    - **Status**: Not configured
    - **Impact**: Virtual console (TTY) colors not themed
    - **Note**: Useful for console sessions

### Additional Notes

- **swayidle/swaylock** - Already manually themed with catppuccin colors in `home/nixos/apps/swayidle.nix`
- **niri** - Already manually themed with catppuccin colors in `home/nixos/theme-constants.nix`

## Applications NOT in Catppuccin Module List ❌

These applications are installed but **do not have catppuccin/nix modules** available. They may have catppuccin themes available elsewhere (manually configurable), but catppuccin/nix can't automatically theme them:

### Desktop Applications

1. **mpv** - Video player
   - **Location**: `home/nixos/desktop-apps.nix:11`
   - **Note**: May have catppuccin theme via config file, but no catppuccin/nix module
   - **Catppuccin Port**: Available at <https://catppuccin.com/palette> → search "mpv"

2. **discord** - Chat application
   - **Location**: `home/nixos/desktop-apps.nix:19`
   - **Note**: No catppuccin module, but Discord has built-in theme support
   - **Catppuccin Port**: Available - can be applied via Discord's appearance settings

3. **telegram-desktop** - Chat application
   - **Location**: `home/nixos/desktop-apps.nix:20`
   - **Note**: Telegram has built-in themes, but no catppuccin/nix module
   - **Catppuccin Port**: Available - can be applied via Telegram settings

4. **libreoffice** - Office suite
   - **Location**: `home/nixos/desktop-apps.nix:13`
   - **Note**: GTK theme may affect it, but no specific catppuccin module
   - **Catppuccin Port**: May benefit from GTK theme

5. **gimp** - Image editor
   - **Location**: `home/nixos/desktop-apps.nix:16`
   - **Note**: GTK theme may affect it, but no specific catppuccin module
   - **Catppuccin Port**: May benefit from GTK theme

6. **krita** - Image editor
   - **Location**: `home/nixos/desktop-apps.nix:17`
   - **Note**: May have catppuccin theme via config, but no catppuccin/nix module
   - **Catppuccin Port**: Check if available

7. **obsidian** - Note-taking application
   - **Location**: `home/common/apps/obsidian.nix`
   - **Note**: Obsidian has community themes, but no catppuccin/nix module
   - **Catppuccin Port**: Available - search "Obsidian Catppuccin" in Obsidian community themes

8. **swayimg** - Image viewer
   - **Location**: `home/nixos/desktop-apps.nix:12`
   - **Note**: No catppuccin module available

9. **thunar** - File manager
   - **Location**: `home/nixos/desktop-apps.nix:31`
   - **Note**: GTK theme may affect it, but no specific catppuccin module
   - **Catppuccin Port**: May benefit from GTK theme

10. **qjackctl** - Audio routing
    - **Location**: `home/nixos/desktop-apps.nix:36`
    - **Note**: GTK theme may affect it, but no specific catppuccin module

11. **mangohud** - Gaming overlay
    - **Location**: `home/nixos/apps/gaming.nix:13`
    - **Note**: May have catppuccin theme via config, but no catppuccin/nix module
    - **Catppuccin Port**: Check if available

### System Services

12. **cliphist** - Clipboard manager
    - **Location**: `home/nixos/desktop-apps.nix:49`
    - **Note**: Uses fuzzel/dmenu for UI (already themed via fuzzel)

### Recommendations for Desktop Applications

1. **GTK Applications** (libreoffice, gimp, thunar, qjackctl): Already benefit from GTK theme (`catppuccin.gtk`) ✅
2. **Discord**: Use built-in appearance settings or community themes
3. **Telegram**: Use built-in theme settings
4. **Obsidian**: Install Catppuccin theme from Obsidian community themes
5. **MPV**: Configure manually via config file if catppuccin theme is available
6. **Mangohud**: May support custom colors via config file

## Implementation Notes

### Using Catppuccin Modules

Since you have `catppuccin.enable = true`, most modules are already enabled automatically. However, you can override specific settings if needed:

```nix
catppuccin = {
  flavor = "mocha";
  accent = "mauve";
  enable = true;  # This enables all modules that default to it!

  # Override specific module settings if needed:
  helix.useItalics = true;  # Enable italics in helix
  # delta.enable = false;  # Disable delta if needed

  # Platform-specific modules (already configured):
  waybar.mode = "createLink";
  mako.enable = lib.mkIf platformLib.isLinux true;
  swaync.enable = lib.mkIf platformLib.isLinux true;
  firefox = lib.mkIf platformLib.isLinux {
    profiles.default = {
      enable = true;
      accent = "mauve";
      flavor = "mocha";
    };
  };

  # System-level (NixOS module, not Home Manager)
  # Note: These would be configured in NixOS modules, not here
  # grub.enable = true;  # Configure in modules/nixos/core/boot.nix
  # plymouth.enable = true;  # Configure in NixOS if Plymouth is enabled
  # tty.enable = true;  # Configure in NixOS for virtual console
};
```

### Manual Configuration

Some applications may need manual configuration if the module doesn't fully support them:

- Check the catppuccin/nix documentation for specific configuration options
- Some may require removing manual theme settings to let the module handle it

## Recommendations

1. **Verify automatic theming**: Since `catppuccin.enable = true` should enable all modules, verify that theming is actually working in your applications
2. **Check for conflicts**: Some apps may have manual theme settings that conflict with catppuccin modules (e.g., zellij uses "default" theme, micro uses "default" colorscheme)
3. **Remove manual configs**: If catppuccin modules handle theming, remove manual theme settings to avoid conflicts
4. **Desktop applications**: Focus on desktop apps that don't have catppuccin modules (discord, telegram, obsidian, mpv, etc.)

## Verification

Since modules should be enabled automatically, verify theming works:

- Check terminal colors (ghostty, zellij)
- Check editor themes (helix, zed, micro)
- Check file manager colors (yazi, eza)
- Check git tools (delta, lazygit)
- Check system monitors (btop, htop)
- Check launchers (wofi, fuzzel)
