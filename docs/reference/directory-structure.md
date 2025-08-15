# Directory Structure Reference

Complete layout of the Nix configuration repository with explanations for each component.

## 📁 Root Directory

```
nix-config/
├── 📄 README.md                    # Main project README
├── 📄 flake.nix                    # Flake configuration (inputs/outputs)
├── 📄 flake.lock                   # Locked flake dependencies
├── 📁 docs/                        # 📚 Documentation (you are here)
├── 📁 hosts/                       # 🖥️  Host-specific configurations
├── 📁 modules/                     # ⚙️  System-level modules
├── 📁 home/                        # 🏠 Home Manager user configurations
├── 📁 shells/                      # 💻 Development environments
├── 📁 scripts/                     # 🔧 Utility and maintenance scripts
├── 📁 secrets/                     # 🔐 SOPS secrets management
├── 📁 lib/                         # 🛠️  Helper functions and utilities
├── 📁 templates/                   # 📝 Module templates
└── 📄 graph.svg                    # Generated dependency graph
```

## 🖥️ Host Configurations (`hosts/`)

Host-specific system configurations for individual machines.

```
hosts/
├── jupiter/                        # Linux workstation example
│   ├── configuration.nix           # Main host configuration
│   ├── hardware-configuration.nix  # Hardware-specific settings
│   └── default.nix                 # Host module exports
└── Lewiss-MacBook-Pro/             # macOS laptop example
    ├── configuration.nix           # Main host configuration
    └── default.nix                 # Host module exports
```

**Purpose:** Each directory represents a physical machine with its unique hostname, hardware, and specific requirements.

## ⚙️ System Modules (`modules/`)

Reusable system-level configurations organized by platform compatibility.

```
modules/
├── shared/                         # Cross-platform system modules
│   ├── core.nix                    # Essential Nix settings
│   ├── cachix.nix                  # Binary cache configuration
│   ├── dev.nix                     # Development tools
│   ├── docker.nix                  # Container support
│   ├── environment.nix             # System environment
│   ├── overlays.nix                # Package overlays
│   ├── shell.nix                   # System shell configuration
│   └── default.nix                 # Module exports
├── darwin/                         # macOS-specific system modules
│   ├── nix.nix                     # macOS Nix daemon configuration
│   ├── apps.nix                    # Homebrew/App Store integration
│   ├── system.nix                  # macOS system preferences
│   ├── users.nix                   # User account management
│   └── default.nix                 # Module exports
└── nixos/                          # Linux-specific system modules
    ├── core/                       # Essential system components
    │   ├── boot.nix                # Boot configuration
    │   ├── memory.nix              # Memory management
    │   ├── networking.nix          # Network configuration
    │   ├── power.nix               # Power management
    │   ├── security.nix            # Security settings
    │   └── default.nix             # Core module exports
    ├── desktop/                    # Desktop environment & UI
    │   ├── audio/                  # Audio configuration
    │   ├── desktop-environment.nix # DE configuration
    │   ├── graphics.nix            # GPU/graphics settings
    │   ├── hyprland.nix            # Hyprland compositor
    │   ├── niri.nix                # Niri compositor
    │   ├── theme.nix               # System theming
    │   ├── xwayland.nix            # X11 compatibility
    │   └── default.nix             # Desktop module exports
    ├── hardware/                   # Hardware-specific configurations
    │   ├── bluetooth.nix           # Bluetooth support
    │   ├── mouse.nix               # Mouse configuration
    │   ├── usb.nix                 # USB device management
    │   ├── yubikey.nix             # YubiKey support
    │   └── default.nix             # Hardware module exports
    ├── services/                   # Background services
    │   ├── home-assistant/         # Home Assistant integration
    │   ├── home-assistant.nix      # HA main configuration
    │   ├── music-assistant.nix     # Music streaming service
    │   ├── samba.nix               # File sharing
    │   ├── ssh.nix                 # SSH daemon
    │   └── default.nix             # Services module exports
    ├── development/                # Development & virtualization
    │   ├── gaming.nix              # Gaming support (Steam, etc.)
    │   ├── java.nix                # Java development
    │   ├── virtualisation.nix     # VM support
    │   ├── wine.nix                # Windows compatibility
    │   └── default.nix             # Development module exports
    ├── system/                     # System configuration & management
    │   ├── file-management.nix     # File system management
    │   ├── home-manager-cleanup.nix # HM maintenance
    │   ├── monitor-brightness.nix  # Display brightness control
    │   ├── nix.nix                 # NixOS Nix configuration
    │   ├── nix-optimization.nix    # Nix store optimization
    │   ├── nixpkgs.nix             # Nixpkgs configuration
    │   ├── sh.nix                  # Shell scripts
    │   ├── xdg.nix                 # XDG desktop integration
    │   ├── zfs.nix                 # ZFS filesystem
    │   └── default.nix             # System module exports
    └── default.nix                 # NixOS module exports
```

**Key Principles:**
- **`shared/`**: Pure cross-platform modules only
- **Platform-specific**: Contains OS-specific implementations
- **Hierarchical organization**: Related functionality grouped logically
- **Single responsibility**: Each module handles one specific area

## 🏠 Home Manager Configurations (`home/`)

User-level configurations managed by Home Manager.

```
home/
├── common/                         # Cross-platform user configurations
│   ├── apps/                       # Application configurations
│   │   ├── bat.nix                 # Cat replacement with syntax highlighting
│   │   ├── cursor/                 # Cursor editor configuration
│   │   │   ├── ai-settings.nix     # AI assistant settings
│   │   │   ├── constants.nix       # Shared constants
│   │   │   ├── extensions.nix      # VSCode extensions
│   │   │   ├── language-settings.nix # Language-specific settings
│   │   │   ├── settings.nix        # Editor settings
│   │   │   ├── user-config.nix     # User configuration
│   │   │   └── default.nix         # Cursor module exports
│   │   ├── direnv.nix              # Directory-based environments
│   │   ├── fzf.nix                 # Fuzzy finder
│   │   ├── helix.nix               # Helix editor
│   │   ├── obsidian.nix            # Note-taking app
│   │   ├── ripgrep.nix             # Fast grep replacement
│   │   └── zoxide.nix              # Smart cd replacement
│   ├── development/                # Development tools & environments
│   │   ├── go.nix                  # Go programming language
│   │   ├── language-standards.nix  # Code formatting standards
│   │   ├── language-tools.nix      # Language-specific tooling
│   │   ├── lua.nix                 # Lua programming language
│   │   ├── node.nix                # Node.js/JavaScript
│   │   ├── python.nix              # Python programming
│   │   ├── version-control.nix     # Git and related tools
│   │   └── default.nix             # Development module exports
│   ├── shell/                      # Shell configuration
│   │   ├── scripts.nix             # Custom shell scripts
│   │   ├── sh.nix                  # Shell aliases and functions
│   │   └── default.nix             # Shell module exports
│   ├── system/                     # System integration
│   │   ├── uwsm.nix                # Universal Wayland Session Manager
│   │   ├── video-conferencing.nix  # Video call applications
│   │   ├── yubikey.nix             # YubiKey integration
│   │   └── default.nix             # System module exports
│   ├── modules/                    # Custom HM modules
│   │   └── mcp.nix                 # Model Context Protocol
│   ├── lib/                        # Shared libraries and functions
│   │   ├── p10k.zsh                # Powerlevel10k configuration
│   │   └── zsh/functions.zsh       # Custom Zsh functions
│   ├── apps.nix                    # Application package lists
│   ├── git.nix                     # Git configuration
│   ├── gpg.nix                     # GPG/PGP configuration
│   ├── nh.nix                      # Nix helper tool
│   ├── shell.nix                   # Shell configuration
│   ├── sops.nix                    # Secrets management
│   ├── ssh.nix                     # SSH client configuration
│   ├── terminal.nix                # Terminal applications
│   ├── theme.nix                   # Color schemes and theming
│   └── default.nix                 # Common HM module exports
├── darwin/                         # macOS-specific user configurations
│   ├── apps.nix                    # macOS-specific applications
│   ├── mcp.nix                     # Model Context Protocol (macOS)
│   ├── yubikey.nix                 # macOS YubiKey integration
│   └── default.nix                 # Darwin HM module exports
├── nixos/                          # Linux-specific user configurations
│   ├── niri/                       # Niri compositor configuration
│   │   └── keybinds.nix            # Niri keybind configuration
│   ├── system/                     # Linux system integration
│   │   ├── auto-update.nix         # Automatic system updates
│   │   ├── keyboard.nix            # Keyboard configuration
│   │   ├── mangohud.nix            # Gaming overlay
│   │   ├── usb.nix                 # USB device handling
│   │   ├── yubikey-touch-detector.nix # YubiKey status detection
│   │   └── default.nix             # Linux system module exports
│   ├── browser.nix                 # Web browser configuration
│   ├── desktop-apps.nix            # Linux desktop applications
│   ├── launcher.nix                # Application launcher
│   ├── mako.nix                    # Notification daemon
│   ├── mcp.nix                     # Model Context Protocol (Linux)
│   ├── niri.nix                    # Niri compositor
│   ├── style.css                   # Custom CSS styles
│   ├── swappy.nix                  # Screenshot annotation
│   ├── swayidle.nix                # Idle management
│   ├── theme-constants.nix         # Linux theming constants
│   ├── waybar.nix                  # Status bar
│   ├── yazi.nix                    # Terminal file manager
│   └── default.nix                 # NixOS HM module exports
└── default.nix                     # Home Manager exports
```

## 💻 Development Environments (`shells/`)

Reproducible development shells for different languages and purposes.

```
shells/
├── envrc-templates/                # Templates for direnv integration
│   ├── node                        # Node.js project template
│   ├── python                      # Python project template
│   ├── rust                        # Rust project template
│   └── ...                         # Additional language templates
├── projects/                       # Project-specific shells
│   └── react-native.nix            # React Native development
├── utils/                          # Utility shells
│   └── shell-selector.nix          # Interactive shell selection
├── README.md                       # Development environment guide
└── default.nix                     # Shell exports and definitions
```

**Available Shells:**
- **Languages:** `node`, `python`, `rust`, `go`, `java`
- **Frameworks:** `nextjs`, `react-native`
- **Purposes:** `web`, `api-backend`, `devops`, `solana`
- **Utilities:** `shell-selector`

## 🔧 Utility Scripts (`scripts/`)

Organized utility and maintenance scripts.

```
scripts/
├── build/                          # Build-related scripts (future)
├── maintenance/                    # System maintenance scripts
│   └── debug-love2d-refs.sh        # Debug Love2D references
├── mcp/                            # Model Context Protocol servers
│   ├── mcp_love2d_docs.py          # Love2D documentation server
│   └── mcp_lua_docs.py             # Lua documentation server
└── utils/                          # General utility scripts
    └── filter_about_support.sh     # Support filtering utility
```

## 🔐 Secrets Management (`secrets/`)

SOPS-encrypted secrets and certificates.

```
secrets/
├── certificates/                   # SSL/TLS certificates
│   └── mitmproxy-ca-cert.pem       # MitM proxy certificate
└── secrets.yaml                    # Encrypted secrets file (example)
```

## 🛠️ Utilities (`lib/`)

Helper functions and shared utilities.

```
lib/
├── functions.nix                   # Platform detection and utilities
├── hosts.nix                       # Host configuration helpers
├── output-builders.nix             # Flake output builders
└── system-builders.nix             # System configuration builders
```

## 📝 Templates (`templates/`)

Module templates for creating new configurations.

```
templates/
├── common-module.nix               # Template for shared modules
├── home-common-module.nix          # Template for Home Manager modules
└── ...                             # Additional templates
```

## 📚 Documentation (`docs/`)

Comprehensive documentation structure.

```
docs/
├── README.md                       # Documentation index (you are here)
├── guides/                         # User guides
│   ├── quick-start.md              # Getting started quickly
│   ├── configuration.md            # Configuration guide
│   ├── development.md              # Development environments
│   ├── secrets.md                  # Secrets management
│   └── ...                         # Additional guides
├── reference/                      # Reference documentation
│   ├── directory-structure.md      # This file
│   ├── architecture.md             # System architecture
│   ├── modules.md                  # Module reference
│   └── ...                         # Additional references
└── ai-assistants/                  # AI assistant documentation
    ├── README.md                   # Unified AI assistant guide
    ├── project-context.md          # Deep architecture context
    └── common-tasks.md             # Common development patterns
```

---

**Navigation:**
- **🏠 Back to:** [Documentation Index](../README.md)
- **📖 See also:** [Architecture Overview](architecture.md), [Module Reference](modules.md)
