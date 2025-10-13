# Module Index

Complete reference of all NixOS and nix-darwin modules in this configuration.

## How to Use This Index

- **📁 Directory** = Contains multiple related modules
- **📄 File** = Single module configuration
- **✅ Complete** = Fully implemented and documented
- **🚧 WIP** = Work in progress
- **⚠️ Deprecated** = Scheduled for removal

## Import Patterns

**Standard:** Directories without `.nix` extension, files with `.nix` extension

```nix
imports = [
  ./directory        # ✅ Correct - directory import
  ./file.nix         # ✅ Correct - file import
  ./directory.nix    # ❌ Incorrect
  ./file             # ❌ Incorrect
];
```

---

## Shared Modules (`modules/shared/`)

Cross-platform modules that work on both NixOS and nix-darwin.

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `core.nix` | File | ✅ | Essential Nix settings and configuration |
| `shell.nix` | File | ✅ | System-level shell configuration |
| `dev.nix` | File | ✅ | Development tools and utilities |
| `environment.nix` | File | ✅ | Environment variables and system paths |
| `overlays.nix` | File | ✅ | Nixpkgs overlays (delegates to `overlays/`) |
| `cachix.nix` | File | ✅ | Binary cache configuration |
| `sops.nix` | File | ✅ | Secrets management with SOPS |

---

## Darwin Modules (`modules/darwin/`)

macOS-specific system modules.

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `nix.nix` | File | ✅ | macOS Nix daemon configuration |
| `apps.nix` | File | ✅ | Homebrew and App Store integration |
| `system.nix` | File | ✅ | macOS system preferences |
| `backup.nix` | File | ✅ | Time Machine and backup settings |
| `yubikey.nix` | File | ✅ | YubiKey support on macOS |
| `gaming.nix` | File | ✅ | Gaming tools and emulators |
| `karabiner.nix` | File | ✅ | Karabiner-Elements keyboard customization |
| `keyboard.nix` | File | ✅ | Keyboard configuration |

---

## NixOS Modules (`modules/nixos/`)

Linux-specific system modules, organized by category.

### Core System (`core/`)

Essential system components and configuration.

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `boot.nix` | File | ✅ | Boot loader and kernel configuration |
| `certificates.nix` | File | ✅ | SSL/TLS certificate management |
| `memory.nix` | File | ✅ | Memory management (swap, zram, etc.) |
| `networking.nix` | File | ✅ | Network configuration |
| `power.nix` | File | ✅ | Power management settings |
| `security.nix` | File | ✅ | System security settings |

### Desktop Environment (`desktop/`)

Desktop environment, window managers, and UI components.

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `audio/` | Dir | ✅ | Audio system configuration (PipeWire, ALSA) |
| `desktop-environment.nix` | File | ✅ | Desktop environment settings |
| `graphics.nix` | File | ✅ | GPU drivers and graphics configuration |
| `hyprland.nix` | File | ✅ | Hyprland Wayland compositor |
| `niri.nix` | File | ✅ | Niri Wayland compositor |
| `theme.nix` | File | ✅ | System-wide theming |
| `xwayland.nix` | File | ✅ | XWayland X11 compatibility layer |

### Hardware (`hardware/`)

Hardware-specific configurations and drivers.

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `bluetooth.nix` | File | ✅ | Bluetooth support and configuration |
| `mouse.nix` | File | ✅ | Mouse and input device settings |
| `usb.nix` | File | ✅ | USB device management |
| `yubikey.nix` | File | ✅ | YubiKey hardware support |

### Services (`services/`)

Background services and daemons.

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `home-assistant/` | Dir | ✅ | Home Assistant smart home platform |
| `home-assistant.nix` | File | ✅ | Home Assistant main configuration |
| `music-assistant.nix` | File | ✅ | Music Assistant streaming service |
| `samba.nix` | File | ✅ | Samba file sharing |
| `ssh.nix` | File | ✅ | SSH daemon configuration |

### Development (`development/`)

Development tools and virtualization.

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `gaming.nix` | File | ✅ | Gaming support (Steam, Proton, etc.) |
| `java.nix` | File | ✅ | Java development environment |
| `virtualisation.nix` | File | ✅ | VM and container support |
| `wine.nix` | File | ✅ | Wine Windows compatibility |

### System Management (`system/`)

System configuration, maintenance, and optimization.

#### Nix (`system/nix/`)

Nix-specific configuration and optimization.

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `nix.nix` | File | ✅ | NixOS Nix daemon configuration |
| `nix-optimization.nix` | File | ✅ | Nix store optimization and garbage collection |
| `nixpkgs.nix` | File | ✅ | Nixpkgs configuration (allowUnfree, etc.) |

#### Integration (`system/integration/`)

System integration and interoperability.

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `xdg.nix` | File | ✅ | XDG desktop portals and integration |

#### Maintenance (`system/maintenance/`)

System maintenance and cleanup tasks.

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `home-manager-cleanup.nix` | File | ✅ | Home Manager backup file cleanup |

#### Other System Modules

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `keyd.nix` | File | ✅ | Keyd keyboard remapping |
| `monitor-brightness.nix` | File | ✅ | Display brightness control |
| `zfs.nix` | File | ✅ | ZFS filesystem configuration |
| `sops.nix` | File | ✅ | SOPS secrets management (NixOS) |

---

## Home Manager Modules

User-level configurations. See [`home/`](../home/) for the complete structure.

### Common (`home/common/`)

Cross-platform user configurations.

#### Apps (`home/common/apps/`)

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `packages.nix` | File | ✅ | Package installations (extracted from apps.nix) |
| `cursor/` | Dir | ✅ | Cursor editor configuration |
| `bat.nix` | File | ✅ | Bat (better cat) configuration |
| `direnv.nix` | File | ✅ | Direnv environment management |
| `fzf.nix` | File | ✅ | Fuzzy finder configuration |
| `ripgrep.nix` | File | ✅ | Ripgrep search tool |
| `helix.nix` | File | ✅ | Helix editor configuration |
| `obsidian.nix` | File | ✅ | Obsidian note-taking app |
| `aws.nix` | File | ✅ | AWS CLI configuration |
| `docker.nix` | File | ✅ | Docker configuration |
| `atuin.nix` | File | ✅ | Atuin shell history |
| `lazygit.nix` | File | ✅ | Lazygit TUI configuration |
| `lazydocker.nix` | File | ✅ | Lazydocker TUI configuration |
| `micro.nix` | File | ✅ | Micro editor configuration |
| `eza.nix` | File | ✅ | Eza (better ls) configuration |
| `jq.nix` | File | ✅ | jq JSON processor |
| `zellij.nix` | File | ✅ | Zellij terminal multiplexer |

#### Development (`home/common/development/`)

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `version-control.nix` | File | ✅ | Git and related tools |
| `python.nix` | File | ✅ | Python development environment |
| `go.nix` | File | ✅ | Go development environment |
| `node.nix` | File | ✅ | Node.js/JavaScript development |
| `lua.nix` | File | ✅ | Lua development environment |
| `language-tools.nix` | File | ✅ | Language servers and tooling |
| `language-standards.nix` | File | ✅ | Code formatting standards |

#### Custom Modules (`home/common/modules/`)

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `mcp.nix` | File | ✅ | Model Context Protocol module definition |

#### Other Common Modules

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `git.nix` | File | ✅ | Git configuration |
| `shell.nix` | File | ✅ | Shell configuration (Zsh, etc.) |
| `ssh.nix` | File | ✅ | SSH client configuration |
| `gpg.nix` | File | ✅ | GPG/PGP configuration |
| `sops.nix` | File | ✅ | SOPS secrets (Home Manager) |
| `theme.nix` | File | ✅ | User theming (Catppuccin) |
| `terminal.nix` | File | ✅ | Terminal emulators |
| `nh.nix` | File | ✅ | Nix helper tool |
| `nix-config.nix` | File | ✅ | User Nix configuration |
| `modules.nix` | File | ✅ | Module imports |

### Darwin (`home/darwin/`)

macOS-specific user configurations.

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `apps.nix` | File | ✅ | macOS-specific applications |
| `mcp.nix` | File | ✅ | MCP configuration (Darwin) |
| `yubikey.nix` | File | ✅ | YubiKey integration (macOS) |
| `keyboard.nix` | File | ✅ | Keyboard configuration |
| `karabiner.nix` | File | ✅ | Karabiner-Elements setup |

### NixOS (`home/nixos/`)

Linux-specific user configurations.

| Module | Type | Status | Description |
|--------|------|--------|-------------|
| `niri/` | Dir | ✅ | Niri compositor configuration |
| `system/` | Dir | ✅ | Linux system integration |
| `apps/` | Dir | ✅ | Linux-specific applications |
| `browser.nix` | File | ✅ | Web browser configuration |
| `desktop-apps.nix` | File | ✅ | Desktop applications |
| `launcher.nix` | File | ✅ | Application launcher (Wofi, etc.) |
| `mcp.nix` | File | ✅ | MCP configuration (NixOS) |
| `waybar.nix` | File | ✅ | Waybar status bar |
| `yazi.nix` | File | ✅ | Yazi file manager |

---

## Module Organization Best Practices

### When to Create a Directory

Create a directory when:
- You have 3+ related modules
- The feature has sub-components (e.g., `audio/`, `niri/`)
- You want to group configuration logically

### When to Keep as a File

Keep as a file when:
- Single, focused configuration
- No sub-components needed
- Simple, standalone feature

### Naming Conventions

- Use kebab-case: `my-feature.nix`
- Be descriptive: `nix-optimization.nix` not `optimize.nix`
- Avoid generic names: `integration/` not `misc/`

---

## Adding a New Module

1. **Decide location:**
   - System-level → `modules/{shared,darwin,nixos}/`
   - User-level → `home/{common,darwin,nixos}/`

2. **Choose structure:**
   - Single file for simple modules
   - Directory with `default.nix` for complex modules

3. **Follow import pattern:**
   ```nix
   imports = [
     ./new-directory    # Directory
     ./new-file.nix     # File
   ];
   ```

4. **Update this index:**
   - Add entry to appropriate section
   - Include description and status

5. **Test:**
   ```bash
   nix flake check
   ```

---

## Deprecated Modules

| Module | Reason | Alternative |
|--------|--------|-------------|
| `modules/nixos/system/file-management.nix` | Empty file | Removed |

---

**Last Updated:** 2025-01-14  
**Maintainer:** Lewis Flude
