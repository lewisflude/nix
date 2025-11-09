# Applications Not Using Signal Theme

This document lists all applications, packages, and services in the configuration that do **not** currently use the Signal theme system.

## Summary

- **Total apps with Signal theme support**: 15 (from registry)
- **Apps configured but not using Signal theme**: Multiple (see below)
- **Apps manually using theme colors**: 4 (mpv, swayidle, swappy, fuzzel, niri)

## Applications with Signal Theme Support Available (But May Not Be Enabled)

These applications have Signal theme modules available in `modules/shared/features/theming/applications/` but may not be actively using them:

### Editors

- ? **cursor** - Has theme module
- ? **helix** - Has theme module
- ? **zed** - Has theme module

### Terminals

- ? **ghostty** - Has theme module
- ? **zellij** - Has theme module

### Desktop (Wayland/Linux)

- ? **fuzzel** - Has theme module (but manually configured in `home/nixos/launcher.nix`)
- ? **ironbar** - Has theme module (but manually configured in `home/nixos/ironbar.nix`)
- ? **mako** - Has theme module (but not using it in `home/nixos/mako.nix`)
- ? **swaync** - Has theme module (but not using it in `home/nixos/swaync.nix`)
- ? **swappy** - Has theme module (but manually configured in `home/nixos/apps/swappy.nix`)
- ? **gtk** - Has theme module

### CLI Tools

- ? **bat** - Has theme module
- ? **fzf** - Has theme module
- ? **lazygit** - Has theme module
- ? **yazi** - Has theme module (but not using it in `home/nixos/yazi.nix`)

## Applications NOT Using Signal Theme

### Desktop Applications

#### Launchers

- **wofi** (`home/nixos/apps/wofi.nix`) - Just enabled, no theming
  - Status: No theme module available
  - Note: Using fuzzel instead, which has theme support

#### Window Managers/Compositors

- **niri** (`home/nixos/niri.nix`) - Uses `theme-constants.nix` but not Signal theme system
  - Status: Manually configured with theme colors via `theme-constants.nix`
  - Note: Could potentially use Signal theme system

#### Media Players

- **mpv** (`home/nixos/apps/mpv.nix`) - Manually uses theme colors via `themeContext`
  - Status: Uses theme colors but not through Signal theme system
  - Note: Could be migrated to use Signal theme module

#### System Services

- **swayidle** (`home/nixos/apps/swayidle.nix`) - Manually uses theme colors via `themeContext`
  - Status: Uses theme colors but not through Signal theme system
  - Note: Could be migrated to use Signal theme module

- **wlsunset** (`home/nixos/apps/wlsunset.nix`) - Color temperature tool
  - Status: No theming needed (color temperature adjustment)

- **cliphist** (`home/nixos/desktop-apps.nix`) - Clipboard manager
  - Status: No theme module available

- **polkit-gnome** (`home/nixos/apps/polkit-gnome.nix`) - Authentication agent
  - Status: No theme module available

#### Desktop Applications (Packages)

- **gimp** - Image editor
  - Status: No theme module available
  - Note: GTK theme would apply if GTK theming is enabled

- **discord** - Chat application
  - Status: No theme module available

- **telegram-desktop** - Messaging app
  - Status: No theme module available

- **file-roller** - Archive manager
  - Status: No theme module available
  - Note: GTK theme would apply if GTK theming is enabled

- **thunar** - File manager
  - Status: No theme module available
  - Note: GTK theme would apply if GTK theming is enabled

- **aseprite** - Pixel art editor
  - Status: No theme module available

- **wl-screenrec** - Screen recorder
  - Status: No theme module available

- **swaylock-effects** - Screen locker
  - Status: Colors configured via swayidle, not Signal theme system

#### Browsers

- **chromium** (`home/nixos/browser.nix`) - Web browser
  - Status: No theme module available
  - Note: Browser themes are typically managed within the browser

### CLI Tools & Utilities

#### Development Tools

- **obsidian** (`home/common/apps/obsidian.nix`) - Note-taking app
  - Status: No theme module available

- **thunderbird** - Email client
  - Status: No theme module available

- **atuin** (`home/common/apps/atuin.nix`) - Shell history
  - Status: No theme module available

- **direnv** (`home/common/apps/direnv.nix`) - Environment management
  - Status: No theme module available

- **eza** (`home/common/apps/eza.nix`) - `ls` replacement
  - Status: No theme module available

- **jq** (`home/common/apps/jq.nix`) - JSON processor
  - Status: No theme module available

- **ripgrep** (`home/common/apps/ripgrep.nix`) - Text search
  - Status: No theme module available

- **lazydocker** (`home/common/apps/lazydocker.nix`) - Docker TUI
  - Status: No theme module available

- **awscli** (`home/common/apps/aws.nix`) - AWS CLI
  - Status: No theme module available

- **gh** (`home/common/apps/gh.nix`) - GitHub CLI
  - Status: No theme module available

- **codex** (`home/common/apps/codex.nix`) - Code search
  - Status: No theme module available

- **claude-code** (`home/common/apps/claude-code.nix`) - Claude integration
  - Status: No theme module available

- **gemini-cli** (`home/common/apps/gemini-cli.nix`) - Gemini CLI
  - Status: No theme module available

- **cachix** (`home/common/apps/cachix.nix`) - Binary cache
  - Status: No theme module available

- **yq** (`home/common/apps/yq.nix`) - YAML processor
  - Status: No theme module available

- **nh** (`home/common/nh.nix`) - Nix helper
  - Status: No theme module available

- **delta** (`home/common/git.nix`) - Git diff viewer
  - Status: No theme module available

#### System Monitoring

- **htop** (`home/common/apps/packages.nix`) - Process monitor
  - Status: No theme module available

- **btop** (`home/common/apps/packages.nix`) - System monitor
  - Status: No theme module available

#### Shell & Core Tools

- **zsh** (`home/common/shell/sh.nix`) - Shell
  - Status: No theme module available
  - Note: Terminal colors would come from ghostty theme

- **git** (`home/common/git.nix`) - Version control
  - Status: No theme module available

- **ssh** (`home/common/ssh.nix`) - SSH client
  - Status: No theme module available

- **gpg** (`home/common/gpg.nix`) - Encryption
  - Status: No theme module available

### Gaming Applications

- **steam** (`home/nixos/apps/gaming.nix`) - Game platform
  - Status: No theme module available

- **mangohud** (`home/nixos/apps/gaming.nix`) - Performance overlay
  - Status: No theme module available

- **protonup-qt** (`home/nixos/apps/gaming.nix`) - Proton updater
  - Status: No theme module available

- **sunshine** (`home/nixos/apps/gaming.nix`) - Game streaming
  - Status: No theme module available

- **moonlight-qt** (`home/nixos/apps/gaming.nix`) - Game streaming client
  - Status: No theme module available

- **dwarf-fortress** (`home/nixos/apps/gaming.nix`) - Game
  - Status: No theme module available

### System Services

#### Audio

- **pipewire** - Audio server
  - Status: No theme module available

- **pwvucontrol** (`home/nixos/system/audio.nix`) - Audio control
  - Status: No theme module available

- **pulsemixer** (`home/nixos/system/audio.nix`) - Audio mixer
  - Status: No theme module available

- **pamixer** (`home/nixos/system/audio.nix`) - Audio mixer
  - Status: No theme module available

- **playerctl** (`home/nixos/system/audio.nix`) - Media control
  - Status: No theme module available

#### System Integration

- **gnome-keyring** (`home/nixos/system/gnome-keyring.nix`) - Keyring service
  - Status: No theme module available

- **network-manager-applet** (`home/nixos/system/networking.nix`) - Network manager
  - Status: No theme module available

- **udiskie** (`home/nixos/system/usb.nix`) - USB disk manager
  - Status: No theme module available

- **gpg-agent** (`home/common/gpg.nix`) - GPG agent
  - Status: No theme module available

#### MCP Services

- **mcp** (`home/nixos/mcp.nix`) - Model Context Protocol servers
  - Status: No theme module available

### NixOS System Services

These are system-level services that typically don't need theming:

- **home-assistant** (`modules/nixos/services/home-assistant.nix`)
- **music-assistant** (`modules/nixos/services/music-assistant.nix`)
- **samba** (`modules/nixos/services/samba.nix`)
- **ssh** (`modules/nixos/services/ssh.nix`)
- **cockpit** (`modules/nixos/services/cockpit.nix`)
- **restic** (backup service)
- Various container services

## Applications Manually Using Theme Colors (Not Through Signal Theme System)

These applications use theme colors but not through the Signal theme module system:

1. **fuzzel** (`home/nixos/launcher.nix`) - Uses `themeContext` directly
2. **mpv** (`home/nixos/apps/mpv.nix`) - Uses `themeContext` directly
3. **swayidle** (`home/nixos/apps/swayidle.nix`) - Uses `themeContext` directly
4. **swappy** (`home/nixos/apps/swappy.nix`) - Uses `themeContext` directly
5. **niri** (`home/nixos/niri.nix`) - Uses `theme-constants.nix` (which uses Signal theme but not the module system)

## Recommendations

### High Priority (Easy Wins)

These apps have Signal theme modules available but aren't using them:

1. **mako** - Has module, just needs to enable `theming.signal.applications.mako.enable`
2. **swaync** - Has module, just needs to enable `theming.signal.applications.swaync.enable`
3. **yazi** - Has module, just needs to enable `theming.signal.applications.yazi.enable`
4. **ironbar** - Has module, but manually configured; could migrate to use module

### Medium Priority (Migration Needed)

These apps manually use theme colors and could be migrated to use Signal theme modules:

1. **fuzzel** - Currently manually configured, has module available
2. **swappy** - Currently manually configured, has module available
3. **mpv** - Currently manually configured, no module available (would need to create one)
4. **swayidle** - Currently manually configured, no module available (would need to create one)
5. **niri** - Uses theme-constants, could potentially use Signal theme system

### Low Priority (No Theme Support Available)

These apps don't have theme modules and would require creating new modules:

- Desktop applications (gimp, discord, telegram, etc.)
- CLI tools (atuin, direnv, eza, etc.)
- System services (most don't need theming)
- Gaming applications

## Notes

- **GTK Applications**: If `theming.signal.applications.gtk.enable` is enabled, GTK applications (gimp, thunar, file-roller, etc.) will automatically use the Signal theme via GTK CSS overrides.

- **Terminal Applications**: CLI tools that run in terminals (e.g., eza, jq, ripgrep) will inherit colors from the terminal theme (ghostty) if the terminal is themed.

- **Browser Themes**: Browsers like Chromium typically manage their own themes internally and don't integrate with system theming systems.

- **System Services**: Most system services (home-assistant, samba, etc.) are web-based or headless and don't need theming.
