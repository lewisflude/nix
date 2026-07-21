# Getting Started with Signal

This guide will help you set up Signal theming on NixOS, nix-darwin, or standalone Home Manager.

## Prerequisites

- **Nix with Flakes enabled**
- **Home Manager** (or NixOS/nix-darwin with Home Manager module)
- Basic familiarity with Nix configuration

### Enable Flakes

If you haven't enabled flakes yet, add this to your configuration:

**NixOS** (`/etc/nixos/configuration.nix`):
```nix
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
```

**nix-darwin** (`~/.config/darwin/flake.nix`):
```nix
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
```

**Standalone Home Manager** (`~/.config/nix/nix.conf`):
```
experimental-features = nix-command flakes
```

## Installation

### Option 1: NixOS with Home Manager

**Step 1: Add Signal to your flake inputs**

Edit your `/etc/nixos/flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    signal.url = "github:lewisflude/signal-nix";
  };

  outputs = { nixpkgs, home-manager, signal, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.users.yourusername = {
            imports = [ signal.homeManagerModules.default ];

            # Enable your programs
            programs = {
              helix.enable = true;
              kitty.enable = true;
              bat.enable = true;
            };

            # Enable Signal theming
            theming.signal = {
              enable = true;  # Automatically themes all enabled programs
              mode = "dark";
            };
          };
        }
      ];
    };
  };
}
```

**Step 2: Rebuild your system**

```bash
sudo nixos-rebuild switch --flake /etc/nixos#yourhostname
```

### Option 2: nix-darwin with Home Manager

**Step 1: Add Signal to your flake inputs**

Edit your `~/.config/darwin/flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    signal.url = "github:lewisflude/signal-nix";
  };

  outputs = { nixpkgs, darwin, home-manager, signal, ... }: {
    darwinConfigurations.yourhostname = darwin.lib.darwinSystem {
      system = "aarch64-darwin";  # or "x86_64-darwin"
      modules = [
        ./configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.users.yourusername = {
            imports = [ signal.homeManagerModules.default ];

            programs = {
              helix.enable = true;
              alacritty.enable = true;
              bat.enable = true;
            };

            theming.signal = {
              enable = true;
              autoEnable = true;
              mode = "dark";
            };
          };
        }
      ];
    };
  };
}
```

**Step 2: Rebuild your system**

```bash
darwin-rebuild switch --flake ~/.config/darwin#yourhostname
```

### Option 3: Standalone Home Manager

**Step 1: Create or edit your flake**

Create `~/.config/home-manager/flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    signal.url = "github:lewisflude/signal-nix";
  };

  outputs = { nixpkgs, home-manager, signal, ... }: {
    homeConfigurations.yourusername = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        signal.homeManagerModules.default
        {
          home = {
            username = "yourusername";
            homeDirectory = "/home/yourusername";
            stateVersion = "24.05";
          };

          programs = {
            helix.enable = true;
            kitty.enable = true;
            bat.enable = true;
          };

          theming.signal = {
            enable = true;
            autoEnable = true;
            mode = "dark";
          };
        }
      ];
    };
  };
}
```

**Step 2: Activate your configuration**

```bash
home-manager switch --flake ~/.config/home-manager#yourusername
```

## Verification

After rebuilding, verify Signal is working:

### 1. Check if Signal is enabled

```bash
# NixOS
nix eval /etc/nixos#nixosConfigurations.yourhostname.config.home-manager.users.yourusername.theming.signal.enable

# Standalone Home Manager
nix eval ~/.config/home-manager#homeConfigurations.yourusername.config.theming.signal.enable
```

Should output: `true`

### 2. Check generated config files

Look for Signal colors in your application configs:

```bash
# Helix
cat ~/.config/helix/config.toml | grep -A 5 "\[theme\]"

# Kitty
cat ~/.config/kitty/kitty.conf | grep "color"

# Bat
ls ~/.config/bat/themes/
```

### 3. Test in applications

Open your themed applications and verify colors:

```bash
# Test Helix
helix

# Test Kitty
kitty

# Test Bat
bat ~/.config/helix/config.toml
```

## Configuration Options

### Automatic Theming (Recommended)

Enable Signal once and it automatically themes all your enabled programs:

```nix
theming.signal = {
  enable = true;
  autoEnable = true;  # Theme all enabled programs
  mode = "dark";      # "light", "dark", or "auto"
};
```

### Selective Theming

Choose exactly which programs to theme:

```nix
theming.signal = {
  enable = true;
  mode = "dark";

  # Explicitly enable specific programs
  editors.helix.enable = true;
  terminals.kitty.enable = true;
  cli.bat.enable = true;
};
```

### Selective Disabling

Theme everything except specific programs:

```nix
theming.signal = {
  enable = true;
  autoEnable = true;
  mode = "dark";

  # Disable theming for these
  cli.bat.enable = false;
  terminals.kitty.enable = false;
};
```

## Theme Modes

- **`"dark"`** - Dark background, light text (recommended)
- **`"light"`** - Light background, dark text
- **`"auto"`** - Follow system preference (currently defaults to dark)

Switch modes by changing the `mode` option and rebuilding:

```nix
theming.signal.mode = "light";
```

Then rebuild:

```bash
# NixOS
sudo nixos-rebuild switch

# nix-darwin
darwin-rebuild switch

# Standalone Home Manager
home-manager switch
```

## Troubleshooting

### Colors not showing

1. **Restart the application** - Most apps need a restart to load new colors
2. **Check true color support** - Ensure your terminal supports 24-bit color
3. **Verify config generation** - Check that Signal generated the config files

### Program not themed

1. **Enable the program** - Set `programs.<app>.enable = true`
2. **Enable Signal theming** - Set `theming.signal.enable = true`
3. **Enable autoEnable or explicit theming** - Set `autoEnable = true` or `<category>.<app>.enable = true`
4. **Rebuild** - Run your rebuild command

### Flake not found

Enable flakes in your Nix configuration (see [Prerequisites](#prerequisites)).

### Evaluation errors

Run with `--show-trace` to see detailed errors:

```bash
nixos-rebuild switch --show-trace
```

For more troubleshooting help, see the [Troubleshooting Guide](troubleshooting.md).

## Next Steps

- **[Configuration Guide](configuration-guide.md)** - Explore all configuration options
- **[Supported Applications](theming-reference.md)** - See what apps Signal can theme
- **[Examples](../examples/)** - Real-world configuration examples
- **[Architecture](architecture.md)** - Understand how Signal works

## Getting Help

- **Documentation** - Check the [docs](.) for guides and references
- **Issues** - Report bugs on [GitHub Issues](https://github.com/lewisflude/signal-nix/issues)
- **Examples** - Browse [example configurations](../examples/)
