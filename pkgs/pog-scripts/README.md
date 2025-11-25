# Pog Scripts

This directory contains CLI tools built with [pog](https://github.com/jpetrucciani/pog) - a Nix library for creating comprehensive CLI tools.

## Features

All scripts built with pog get these features automatically:

- 🚀 Rich flag parsing (short & long flags)
- 📖 Auto-generated help text (`--help`)
- 🔄 Tab completion
- 🎯 Interactive prompts (using `gum`)
- 🎨 Terminal colors and styling
- 🛠 Boolean flags, defaults, required flags
- ⚡ Environment variable overrides
- 🔍 Built-in verbose mode (`-v`)

## Available Scripts

### `cleanup-duplicates` - Remove Old Package Versions

Remove old/unused package versions from Nix store while keeping latest versions.

**Usage:**

```bash
# Interactive cleanup (with confirmations)
sudo nix run .#cleanup-duplicates

# Dry run to see what would be deleted
sudo nix run .#cleanup-duplicates -- --dry_run

# Non-interactive (auto-confirm)
sudo nix run .#cleanup-duplicates -- --auto_confirm

# Help
nix run .#cleanup-duplicates -- --help
```

**Flags:**

- `-y, --auto_confirm` - Auto-confirm all prompts
- `-d, --dry_run` - Show what would be deleted without making changes
- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help

**What it cleans:**

- Old LibreOffice versions (keeps latest)
- Old Ollama versions (keeps latest)
- Old NVIDIA drivers (keeps current kernel version)
- Old LLVM/Clang versions (keeps latest)
- Old OpenJDK versions (keeps latest)
- Old Iosevka fonts (keeps latest)
- Old Zoom versions (keeps latest)
- Debug packages (cmake debug)
- Old Rust toolchains (if not referenced)

### `analyze-services` - Service Usage Analyzer

Analyze Nix store service usage to identify optimization opportunities.

**Usage:**

```bash
# Analyze services
nix run .#analyze-services

# Verbose output
nix run .#analyze-services -- --verbose

# Help
nix run .#analyze-services -- --help
```

**What it analyzes:**

- Currently running services vs configured
- Large packages that might be optional
- Multiple versions of packages (LibreOffice, Ollama, etc.)
- Development tools usage
- Store size and recommendations

### `visualize-modules` - Module Dependency Graph

Generate dependency graph of all modules in the configuration.

**Usage:**

```bash
# Generate all formats (default)
nix run .#visualize-modules

# Specific format
nix run .#visualize-modules -- --format svg
nix run .#visualize-modules -- --format png
nix run .#visualize-modules -- --format dot

# Custom output directory
nix run .#visualize-modules -- --output_dir docs/generated

# Help
nix run .#visualize-modules -- --help
```

**Flags:**

- `-f, --format` - Output format (svg, png, dot, all) [default: all]
- `-o, --output_dir` - Output directory [default: docs/generated]
- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help

**Output files:**

- `module-dependencies.dot` - Graphviz DOT file
- `module-dependencies.svg` - SVG visualization (if graphviz available)
- `module-dependencies.png` - PNG visualization (if graphviz available)
- `module-summary.txt` - Text summary of modules

### `calculate-qbittorrent-config` - qBittorrent Speed Optimizer

Calculate optimal qBittorrent settings based on speed tests and system resources using the Azureus calculator algorithm.

**Usage:**

```bash
# Auto-detect everything (runs VPN speed test)
nix run .#calculate-qbittorrent-config

# Manual upload speed (skip speed test)
nix run .#calculate-qbittorrent-config -- -u 8216

# Different optimization priorities
nix run .#calculate-qbittorrent-config -- -p speed      # Maximum speed
nix run .#calculate-qbittorrent-config -- -p balanced   # Current settings
nix run .#calculate-qbittorrent-config -- -p hdd-safe   # Conservative

# Output formats
nix run .#calculate-qbittorrent-config -- -o nix      # Nix config (default)
nix run .#calculate-qbittorrent-config -- -o json     # JSON output
nix run .#calculate-qbittorrent-config -- -o summary  # Human-readable

# Test direct connection instead of VPN
nix run .#calculate-qbittorrent-config -- -n ""

# Generate and save config
nix run .#calculate-qbittorrent-config -- -o nix > ~/qbt-config.nix

# Help
nix run .#calculate-qbittorrent-config -- --help
```

**Flags:**

- `-i, --interface` - Network interface [default: vlan2]
- `-n, --vpn_namespace` - VPN namespace [default: qbt, use "" for direct]
- `-u, --upload_speed` - Manual upload speed in KB/s (skip test)
- `-p, --priority` - Optimization mode: speed, balanced, hdd-safe [default: speed]
- `-o, --output_format` - Output: nix, json, summary [default: nix]
- `--skip_test` - Skip speed test (requires -u)
- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help

**What it does:**

1. Runs upload speed test through VPN or direct connection
2. Detects system resources (RAM, CPU cores, storage type)
3. Calculates optimal settings using Azureus algorithm:
   - Upload slots = Upload Speed ÷ 5 KB/s
   - Active torrents = Upload slots ÷ 3
   - Connections optimized for stability
4. Outputs ready-to-paste Nix configuration

**Optimization Modes:**

| Mode | Active Torrents | Upload Slots | Use Case |
|------|----------------|--------------|----------|
| `speed` | 547 | 1,643 | Maximum performance (based on 8,216 KB/s upload) |
| `balanced` | 150 | 300 | Balanced HDD health + streaming |
| `hdd-safe` | 100 | 200 | Conservative for old/slow HDDs |

**Example Output (nix format):**

```nix
# Generated by calculate-qbittorrent-config v1.0.0
# Upload speed: 8216 KB/s (82.16 Mbit/s)
# System: 64GB RAM, 32 CPU cores, hdd storage
# Priority: speed

qbittorrent = {
  uploadSpeedLimit = 8216;
  maxConnections = 600;
  maxConnectionsPerTorrent = 100;
  maxUploads = 1643;
  maxUploadsPerTorrent = 10;
  maxActiveTorrents = 547;
  maxActiveUploads = 273;

  physicalMemoryLimit = 8192;
  asyncIOThreadsCount = 32;
  hashingThreadsCount = 8;
  diskCacheSize = 4096;
};
```

### `update-all` - Update All Dependencies

Update all dependencies in your Nix configuration: flake inputs, custom packages, and ZSH plugins.

**Usage:**

```bash
# Update everything
nix run .#update-all

# Dry run to see what would be updated
nix run .#update-all -- --dry_run

# Skip specific update types
nix run .#update-all -- --skip_flake      # Skip flake.lock
nix run .#update-all -- --skip_packages   # Skip custom packages
nix run .#update-all -- --skip_plugins    # Skip ZSH plugins

# Help
nix run .#update-all -- --help
```

**What it updates:**

1. **Flake inputs** (`flake.lock`) - All your flake dependencies
2. **Custom packages** - Packages with `fetchFromGitHub` using `nix-update`
   - Home Assistant home-llm component
   - (Add more packages to the PACKAGES array in the script)
3. **ZSH plugins** - Managed by nvfetcher

**Flags:**

- `-d, --dry_run` - Show what would be updated without making changes
- `-f, --skip_flake` - Skip flake.lock update
- `-k, --skip_packages` - Skip custom package updates
- `-p, --skip_plugins` - Skip ZSH plugins update
- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help

**Examples:**

```bash
# Safe dry-run to preview changes
nix run .#update-all -- --dry_run

# Update only custom packages
nix run .#update-all -- --skip_flake --skip_plugins

# Update everything and see detailed output
nix run .#update-all -- -v
```

### `new-module` - Module Scaffolding Tool

Create new Nix modules from templates with interactive prompts and validation.

**Usage:**

```bash
# Run directly
nix run .#new-module

# With arguments
nix run .#new-module -- --type feature --name kubernetes

# Interactive mode (prompts for missing args)
nix run .#new-module

# Dry run
nix run .#new-module -- --type service --name grafana --dry_run

# Help
nix run .#new-module -- --help
```

**Flags:**

- `-t, --type` - Module type (feature, service, overlay, test) [required]
- `-n, --name` - Module name [required]
- `-f, --force` - Overwrite existing module
- `--dry_run` - Show what would be created without creating
- `-v, --verbose` - Enable verbose output
- `-h, --help` - Show help

**Examples:**

```bash
# Create a new feature module
nix run .#new-module -- -t feature -n kubernetes

# Create with force overwrite
nix run .#new-module -- --type service --name grafana --force

# Preview what would be created
nix run .#new-module -- -t overlay -n custom-pkgs --dry_run

# Interactive selection (uses gum for pretty prompts)
nix run .#new-module
```

**Tab Completion:**
The `--type` flag has tab completion for valid types:

```bash
nix run .#new-module -- --type <TAB>
# Shows: feature service overlay test
```

## Architecture

### File Structure

```
pkgs/pog-scripts/
├── README.md              # This file
├── update-all.nix         # Update all dependencies
├── new-module.nix         # Module scaffolding tool
├── setup-cachix.nix       # Setup cachix binary cache
├── cleanup-duplicates.nix # Remove old package versions
├── analyze-services.nix   # Analyze service usage
├── visualize-modules.nix  # Generate module dependency graphs
└── [future scripts...]
```

### How It Works

1. **Nix Definition**: Each script is defined as a Nix expression using `pog.lib.pog`
2. **Flake Integration**: Scripts are exposed via `flake.nix` as apps
3. **Runtime**: When run, pog generates a bash script with all features baked in
4. **Execution**: `nix run .#script-name` builds and runs the script

### Example Structure

```nix
{ pkgs, pog, config-root }:

pog.lib.pog {
  name = "my-tool";
  version = "1.0.0";
  description = "Does something useful";

  flags = [
    {
      name = "option";
      description = "Some option";
      required = true;
      completion = ''echo "choice1 choice2"'';
    }
  ];

  runtimeInputs = with pkgs; [ coreutils jq ];

  script = helpers: with helpers; ''
    # Access flags as variables
    echo "Option value: $option"

    # Use helpers
    ${flag "verbose"} && debug "Verbose mode!"
    green "Success!"
  '';
}
```

## Helpers Available

Pog provides many helpers in the `script` function:

### Colors

- `red`, `green`, `yellow`, `blue`, `purple`, `cyan`, `grey`
- Background: `red_bg`, `green_bg`, etc.
- Styles: `bold`, `dim`, `italic`, `underlined`

### Functions

- `debug` - Print debug message (only if `-v`)
- `die` - Exit with error message and code
- `confirm` - Interactive confirmation prompt
- `spinner` - Show spinner while running command

### File Checks

- `${file.exists "VAR"}` - Check if file exists
- `${file.notExists "VAR"}` - Check if file doesn't exist
- `${file.empty "VAR"}` - Check if file is empty

### Flag Checks

- `${flag "name"}` - Check if boolean flag is set
- `${var.empty "name"}` - Check if variable is empty

## Adding New Scripts

1. **Create the Nix file:**

```bash
touch pkgs/pog-scripts/my-tool.nix
```

2. **Define the script:**

```nix
{ pkgs, pog, config-root }:

pog.lib.pog {
  name = "my-tool";
  description = "Brief description";

  flags = [
    # Define your flags
  ];

  script = helpers: with helpers; ''
    # Your script logic
  '';
}
```

3. **Add to flake outputs** (`lib/output-builders.nix`):

```nix
mkApps = builtins.mapAttrs (system: _hostGroup: let
  pkgs = nixpkgs.legacyPackages.${system};
  pog = inputs.pog.lib.${system};
in {
  # ... existing apps
  my-tool = {
    type = "app";
    program = "${
      import ../pkgs/pog-scripts/my-tool.nix {
        inherit pkgs pog;
        config-root = toString ../.;
      }
    }/bin/my-tool";
  };
})
```

4. **Test it:**

```bash
nix run .#my-tool -- --help
```

## Migrating Bash Scripts to Pog

### Before (Bash)

```bash
#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <name>"
  exit 1
fi

NAME="$1"
echo "Processing $NAME..."
```

### After (Pog)

```nix
{ pkgs, pog, ... }:

pog.lib.pog {
  name = "my-tool";

  flags = [{
    name = "name";
    required = true;
    description = "Name to process";
  }];

  script = ''
    echo "Processing $name..."
  '';
}
```

**Benefits:**

- ✅ Auto-generated help text
- ✅ Flag validation
- ✅ Tab completion
- ✅ Interactive prompts for missing required flags
- ✅ Consistent interface
- ✅ Better error messages

## Best Practices

1. **Use Descriptive Names**: Flag names should be clear and descriptive
2. **Add Completions**: Provide completion for flags that have fixed choices
3. **Make It Interactive**: Use prompts for required flags to make tools user-friendly
4. **Provide Examples**: Add examples in the description
5. **Use Helpers**: Leverage pog helpers instead of raw bash
6. **Dry Run**: Add `--dry_run` flags for destructive operations
7. **Verbose Mode**: Use `debug` for additional info when `-v` is passed

## Resources

- [pog GitHub](https://github.com/jpetrucciani/pog)
- [pog Examples](https://github.com/jpetrucciani/nix/tree/main/mods/pog)
- [Flake Apps Documentation](https://nixos.wiki/wiki/Flakes#Apps)

## Troubleshooting

### Script doesn't run

```bash
# Check if the app is available
nix flake show | grep -A5 apps

# Try building it directly
nix build .#new-module
```

### Flag not working

- Check flag definition has `name` field
- Ensure flag name doesn't conflict with built-ins (`verbose`, `help`, `color`)
- Use `debug` helper to print flag values

### Completion not working

- Completion command must output space-separated values
- Test completion command independently first
- Make sure runtime inputs include necessary tools

### Interactive prompt fails

- Ensure `gum` is in `runtimeInputs`
- Test prompt command independently
- Provide `promptError` message for debugging
