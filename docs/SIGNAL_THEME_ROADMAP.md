# Signal Theme Roadmap

Comprehensive list of applications to be themed with Signal colors, organized by directory structure.

## Already Implemented ?

### Editors

- ? Cursor/VS Code (`applications/editors/cursor.nix`)
- ? Helix (`applications/editors/helix.nix`)
- ? Zed (`applications/editors/zed.nix`)

### Terminals

- ? Ghostty (`applications/terminals/ghostty.nix`)
- ? Zellij (`applications/terminals/zellij.nix`)

### Desktop (Wayland/Linux)

- ? Fuzzel (`applications/desktop/fuzzel.nix`)
- ? GTK (`applications/desktop/gtk.nix`)
- ? Ironbar (`applications/desktop/ironbar-nixos.nix`, `ironbar-home.nix`)
- ? Mako (`applications/desktop/mako.nix`)
- ? SwayNC (`applications/desktop/swaync.nix`)
- ? Swappy (`applications/desktop/swappy.nix`)
- ? Swaylock (`home/nixos/apps/swayidle.nix`)

### CLI Tools

- ? bat (`applications/cli/bat.nix`)
- ? fzf (`applications/cli/fzf.nix`)
- ? lazygit (`applications/cli/lazygit.nix`)
- ? yazi (`applications/cli/yazi.nix`)

### Media

- ? MPV (`home/nixos/apps/mpv.nix`)

### Window Managers

- ? Niri (`home/nixos/niri.nix` via theme-constants)

---

## To Be Implemented

### `modules/shared/features/theming/applications/editors/`

- [ ] `micro.nix` - Micro editor (JSON config)
- [ ] `nvim.nix` - Neovim (Lua theme file)

### `modules/shared/features/theming/applications/terminals/`

- [ ] `alacritty.nix` - Alacritty terminal (YAML config)
- [ ] `foot.nix` - Foot terminal (INI config)
- [ ] `kitty.nix` - Kitty terminal (conf file)
- [ ] `rio.nix` - Rio terminal (TOML config)
- [ ] `wezterm.nix` - WezTerm (Lua config)
- [ ] `xfce4-terminal.nix` - XFCE4 Terminal

### `modules/shared/features/theming/applications/desktop/`

- [ ] `dunst.nix` - Dunst notification daemon (INI config)
- [ ] `hyprland.nix` - Hyprland compositor (borders, shadows, etc.)
- [ ] `hyprlock.nix` - Hyprlock screen locker
- [ ] `imv.nix` - imv image viewer
- [ ] `polybar.nix` - Polybar status bar (INI config)
- [ ] `rofi.nix` - Rofi launcher (rasi theme file)
- [ ] `sway.nix` - Sway window manager (borders, colors)
- [ ] `tofi.nix` - Tofi launcher
- [ ] `waybar.nix` - Waybar status bar (CSS/JSON)
- [ ] `wlogout.nix` - wlogout logout menu (CSS)
- [ ] `kvantum.nix` - Kvantum Qt theme engine

### `modules/shared/features/theming/applications/cli/`

- [ ] `aerc.nix` - aerc email client (INI config)
- [ ] `atuin.nix` - atuin shell history (TOML config)
- [ ] `bottom.nix` - bottom (btm) system monitor (TOML config)
- [ ] `btop.nix` - btop system monitor (theme file)
- [ ] `cava.nix` - cava audio visualizer (INI config)
- [ ] `delta.nix` - delta git diff viewer (gitconfig)
- [ ] `eza.nix` - eza ls replacement (env vars for colors)
- [ ] `gh-dash.nix` - gh-dash GitHub dashboard (YAML config)
- [ ] `gitui.nix` - gitui TUI (Ron config)
- [ ] `glamour.nix` - glamour markdown renderer (JSON style)
- [ ] `halloy.nix` - Halloy IRC client (TOML config)
- [ ] `k9s.nix` - k9s Kubernetes TUI (YAML config)
- [ ] `lazydocker.nix` - lazydocker TUI (YAML config)
- [ ] `lsd.nix` - lsd ls replacement (YAML config)
- [ ] `newsboat.nix` - newsboat RSS reader (config file)
- [ ] `nushell.nix` - Nushell (nu config)
- [ ] `skim.nix` - skim fuzzy finder (env vars)
- [ ] `spotify-player.nix` - spotify-player TUI (TOML config)
- [ ] `starship.nix` - Starship prompt (TOML config)
- [ ] `television.nix` - television fuzzy finder
- [ ] `tmux.nix` - tmux terminal multiplexer (tmux.conf)
- [ ] `vivid.nix` - vivid LS_COLORS generator (YAML theme)
- [ ] `zsh-syntax-highlighting.nix` - zsh-syntax-highlighting (zsh vars)
- [ ] `fish.nix` - Fish shell (fish config)

### `modules/shared/features/theming/applications/browsers/`

- [ ] `brave.nix` - Brave browser (extension/custom CSS)
- [ ] `chromium.nix` - Chromium (extension/custom CSS)
- [ ] `firefox.nix` - Firefox (userChrome.css + userContent.css)
- [ ] `floorp.nix` - Floorp browser (userChrome.css)
- [ ] `librewolf.nix` - LibreWolf (userChrome.css)
- [ ] `qutebrowser.nix` - qutebrowser (Python config.py)
- [ ] `vivaldi.nix` - Vivaldi browser (custom CSS)

### `modules/shared/features/theming/applications/apps/`

- [ ] `discord.nix` - Discord (BetterDiscord CSS theme)
- [ ] `element-desktop.nix` - Element Desktop (custom CSS)
- [ ] `freetube.nix` - FreeTube YouTube client (CSS)
- [ ] `gimp.nix` - GIMP (gtkrc theme file)
- [ ] `mangohud.nix` - MangoHud game overlay (conf file)
- [ ] `obs.nix` - OBS Studio (Qt theme stylesheet)
- [ ] `obsidian.nix` - Obsidian (CSS snippets)
- [ ] `sioyek.nix` - Sioyek PDF viewer (config file)
- [ ] `telegram.nix` - Telegram Desktop (.tdesktop-theme file)
- [ ] `thunderbird.nix` - Thunderbird (userChrome.css)
- [ ] `vesktop.nix` - Vesktop Discord client (Vencord CSS)
- [ ] `zathura.nix` - Zathura PDF viewer (config file)

### `modules/nixos/features/theming/system/`

- [ ] `grub.nix` - GRUB bootloader theme
- [ ] `limine.nix` - Limine bootloader theme
- [ ] `plymouth.nix` - Plymouth boot splash
- [ ] `sddm.nix` - SDDM display manager theme
- [ ] `tty.nix` - TTY console colors (setcolors)
- [ ] `fcitx5.nix` - fcitx5 input method theme

### `pkgs/signal-theme-assets/`

- [ ] `cursors/` - Signal-themed cursor theme (Xcursor format)

---

## Priority Levels

### High Priority (Apps you currently use)

Based on your installed packages:

1. **atuin** - Shell history (you have it configured)
2. **btop** - System monitor (you have it installed)
3. **lazydocker** - Docker TUI (you have it configured)
4. **eza** - ls replacement (you have it configured)
5. **discord** - Chat (you have it installed)
6. **telegram-desktop** - Messaging (you have it installed)
7. **obsidian** - Notes (you have it installed)
8. **chromium** - Browser (you have it configured)

### Medium Priority (Common utilities)

- **tmux** - Terminal multiplexer
- **starship** - Shell prompt
- **delta** - Git diff viewer
- **dunst** - Notification daemon (if switching from mako)
- **rofi/tofi** - App launchers (alternatives to fuzzel)
- **firefox** - Browser theming

### Low Priority (Specialized tools)

- System boot themes (GRUB, Plymouth, SDDM)
- Less common terminals (foot, rio, wezterm)
- Specialized apps (k9s, aerc, newsboat, etc.)

### Very Low Priority (Not installed)

- Apps you don't have installed
- Alternative WMs/compositors (Hyprland, Sway if not using)

---

## Implementation Strategy

### Phase 1: Your Active Apps (Priority 1)

Focus on apps you use daily that aren't currently themed.

### Phase 2: Common CLI Tools (Priority 2)

Terminal tools that would benefit from consistent theming.

### Phase 3: Desktop Apps (Priority 2-3)

GUI applications like Discord, Telegram, Obsidian.

### Phase 4: Browser Themes (Priority 2)

Custom CSS/themes for browsers.

### Phase 5: System Integration (Priority 3)

Boot themes, display managers, TTY colors.

### Phase 6: Comprehensive Coverage (Priority 4)

All remaining applications for completeness.

---

## Notes on Implementation

### Applications Requiring Special Handling

**Electron Apps (Discord, Obsidian, Vesktop, Element):**

- Need custom CSS injection methods
- May require third-party tools (BetterDiscord, CSS snippets)
- Consider creating a shared Electron CSS base

**Qt Apps (OBS, Telegram):**

- Can use Kvantum for consistent Qt theming
- Telegram supports native .tdesktop-theme format
- OBS uses Qt stylesheets

**Browsers:**

- Firefox/LibreWolf/Floorp: userChrome.css + userContent.css
- Chromium-based: Extension or custom CSS injection
- qutebrowser: Native Python config support

**System Components:**

- GRUB: Custom theme package required
- Plymouth: Theme with Signal graphics
- SDDM: QML-based theme
- TTY: kernel setcolors or ANSI escape sequences

### Testing Strategy

For each application:

1. Verify config file location
2. Test color application
3. Check light/dark mode switching
4. Document any special requirements
5. Add to registry.nix
6. Create test case if applicable

---

## Already Themed Applications (Reference)

Total: **16 applications** fully themed

- 3 editors (Cursor, Helix, Zed)
- 2 terminals (Ghostty, Zellij)
- 6 desktop components (Fuzzel, GTK, Ironbar, Mako, SwayNC, Swappy, Swaylock)
- 4 CLI tools (bat, fzf, lazygit, yazi)
- 1 media player (MPV)
- 1 window manager (Niri)

## To Be Themed

Total: **70 applications** pending

- 2 editors
- 6 terminals
- 11 desktop/WM components
- 23 CLI tools
- 7 browsers
- 12 GUI applications
- 5 system components
- 1 cursor theme
- 3 duplicates to remove (cache entries, catppuccin references)

---

## Next Steps

1. ? Create roadmap document
2. Mark applications you actively use
3. Implement high-priority apps first
4. Test each implementation
5. Update registry.nix as apps are added
6. Document special cases
7. Create comprehensive test suite
