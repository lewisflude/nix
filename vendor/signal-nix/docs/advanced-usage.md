# Advanced Usage

Power user features and advanced configuration patterns for Signal.

## Table of Contents

- [Custom Color Mappings](#custom-color-mappings)
- [Multi-Machine Configurations](#multi-machine-configurations)
- [Conditional Theming](#conditional-theming)
- [Integration with Other Modules](#integration-with-other-modules)
- [Performance Optimization](#performance-optimization)
- [Debugging and Troubleshooting](#debugging-and-troubleshooting)
- [Contributing New Applications](#contributing-new-applications)

## Custom Color Mappings

### Accessing Signal Colors Directly

You can access Signal colors in your own modules:

```nix
{ config, lib, ... }:

let
  # Access Signal's resolved colors
  signalColors = config.theming.signal.colors;
in
{
  # Use Signal colors in custom configuration
  programs.my-app.colors = {
    background = signalColors.tonal."surface-Lc05".hex;
    foreground = signalColors.tonal."text-Lc75".hex;
    accent = signalColors.accent.focus.Lc75.hex;
  };
}
```

### Using the Semantic Bridge

The semantic bridge provides high-level color mappings:

```nix
{ config, lib, signalLib, semantic, ... }:

let
  cfg = config.theming.signal;
  mode = signalLib.resolveThemeMode cfg.mode;
in
{
  programs.my-app.colors = {
    background = (semantic.core "background" mode).hex;
    foreground = (semantic.core "foreground" mode).hex;
    error = (semantic.status "error" mode).hex;
    success = (semantic.status "success" mode).hex;
  };
}
```

See [semantic-bridge-guide.md](semantic-bridge-guide.md) for all semantic mappings.

### Color Format Conversion

Signal provides utilities for different color formats:

```nix
{ signalLib, ... }:

let
  color = "#6b87c8";
in
{
  # Convert to space-separated RGB (for Zellij)
  rgbSpaced = signalLib.hexToRgbSpaceSeparated color;
  # Result: "107 135 200"

  # Add alpha channel (for Fuzzel)
  withAlpha = signalLib.hexWithAlpha color 0.95;
  # Result: "6b87c8f2"

  # Validate hex color
  isValid = signalLib.isValidHexColor color;
  # Result: true
}
```

## Multi-Machine Configurations

### Shared Base Configuration

Create a shared Signal configuration:

```nix
# shared/signal.nix
{
  theming.signal = {
    enable = true;
    autoEnable = true;
    mode = "dark";
  };

  programs = {
    helix.enable = true;
    bat.enable = true;
    fzf.enable = true;
  };
}
```

### Per-Machine Overrides

Override for specific machines:

```nix
# hosts/desktop/default.nix
{
  imports = [ ../../shared/signal.nix ];

  # Desktop-specific: Add more programs
  programs = {
    kitty.enable = true;
    lazygit.enable = true;
  };
}

# hosts/laptop/default.nix
{
  imports = [ ../../shared/signal.nix ];

  # Laptop-specific: Use light mode
  theming.signal.mode = "light";

  programs = {
    alacritty.enable = true;
  };
}

# hosts/server/default.nix
{
  imports = [ ../../shared/signal.nix ];

  # Server-specific: Disable GUI programs
  theming.signal = {
    editors.helix.enable = true;
    terminals.kitty.enable = false;
  };
}
```

### Machine-Specific Modules

Use NixOS/Home Manager's module system:

```nix
# flake.nix
{
  outputs = { nixpkgs, home-manager, signal, ... }: {
    homeConfigurations = {
      "user@desktop" = home-manager.lib.homeManagerConfiguration {
        modules = [
          signal.homeManagerModules.default
          ./shared/signal.nix
          ./hosts/desktop/home.nix
        ];
      };

      "user@laptop" = home-manager.lib.homeManagerConfiguration {
        modules = [
          signal.homeManagerModules.default
          ./shared/signal.nix
          ./hosts/laptop/home.nix
        ];
      };
    };
  };
}
```

## Conditional Theming

### Based on Hostname

```nix
{ config, lib, ... }:

{
  theming.signal = {
    enable = true;
    autoEnable = true;
    mode = if config.networking.hostName == "laptop"
           then "light"
           else "dark";
  };
}
```

### Based on Time of Day

```nix
{ config, lib, pkgs, ... }:

let
  # This is evaluated at build time, not runtime
  # For runtime switching, use external tools
  hour = lib.toInt (builtins.substring 0 2 (builtins.readFile /proc/driver/rtc));
  isDaytime = hour >= 6 && hour < 18;
in
{
  theming.signal = {
    enable = true;
    autoEnable = true;
    mode = if isDaytime then "light" else "dark";
  };
}
```

**Note:** This evaluates at build time. For runtime theme switching, use system theme detection tools.

### Based on Environment

```nix
{ config, lib, ... }:

let
  isWorkMachine = config.networking.hostName == "work-laptop";
in
{
  theming.signal = {
    enable = true;
    autoEnable = true;
    mode = "dark";

    # Disable certain themes on work machine
    browsers.firefox.enable = !isWorkMachine;
  };
}
```

### Per-User Configuration

```nix
{ config, lib, ... }:

{
  home-manager.users.alice = {
    imports = [ signal.homeManagerModules.default ];
    theming.signal = {
      enable = true;
      mode = "light";
    };
  };

  home-manager.users.bob = {
    imports = [ signal.homeManagerModules.default ];
    theming.signal = {
      enable = true;
      mode = "dark";
    };
  };
}
```

## Integration with Other Modules

### With Catppuccin-nix

Use Signal for some programs, Catppuccin for others:

```nix
{ config, lib, signal, catppuccin, ... }:

{
  imports = [
    signal.homeManagerModules.default
    catppuccin.homeManagerModules.catppuccin
  ];

  # Signal for editors and terminals
  theming.signal = {
    enable = true;
    editors.helix.enable = true;
    terminals.kitty.enable = true;
  };

  # Catppuccin for other programs
  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  programs = {
    helix.enable = true;    # Signal theme
    kitty.enable = true;    # Signal theme
    bat.enable = true;      # Catppuccin theme
  };
}
```

### With Stylix

Signal and Stylix serve different purposes:

```nix
{ config, lib, signal, stylix, ... }:

{
  imports = [
    signal.homeManagerModules.default
    stylix.homeManagerModules.stylix
  ];

  # Stylix for system-wide theming (fonts, wallpapers, etc.)
  stylix = {
    enable = true;
    image = ./wallpaper.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  };

  # Signal for color-only theming
  theming.signal = {
    enable = true;
    autoEnable = true;
    mode = "dark";
  };
}
```

### With Custom Modules

Create your own modules that use Signal colors:

```nix
# modules/my-app.nix
{ config, lib, signalLib, semantic, ... }:

let
  cfg = config.programs.my-app;
  signalCfg = config.theming.signal;
  mode = signalLib.resolveThemeMode signalCfg.mode;
in
{
  options.programs.my-app = {
    enable = lib.mkEnableOption "My App";
    useSignalColors = lib.mkEnableOption "Use Signal colors";
  };

  config = lib.mkIf (cfg.enable && cfg.useSignalColors && signalCfg.enable) {
    programs.my-app.colors = {
      background = (semantic.core "background" mode).hex;
      foreground = (semantic.core "foreground" mode).hex;
      accent = (semantic.core "focus" mode).hex;
    };
  };
}
```

## Performance Optimization

### Lazy Evaluation

Signal modules use lazy evaluation. Disabled modules don't evaluate:

```nix
{
  theming.signal = {
    enable = true;
    # Only enabled modules evaluate
    editors.helix.enable = true;
    # These don't evaluate (no performance cost)
    editors.neovim.enable = false;
    editors.vim.enable = false;
  };
}
```

### Build Time Optimization

Signal doesn't rebuild packages, only generates config files:

```bash
# Fast rebuild (only config generation)
home-manager switch

# No package rebuilds needed
# Signal only changes config files
```

### Reducing Evaluation Time

For large configurations, use explicit enables instead of autoEnable:

```nix
{
  theming.signal = {
    enable = true;
    autoEnable = false;  # Faster evaluation

    # Explicitly enable only what you need
    editors.helix.enable = true;
    terminals.kitty.enable = true;
  };
}
```

## Debugging and Troubleshooting

### Check Signal Configuration

```bash
# Check if Signal is enabled
nix eval .#homeConfigurations.user.config.theming.signal.enable

# Check theme mode
nix eval .#homeConfigurations.user.config.theming.signal.mode

# Check specific app theming
nix eval .#homeConfigurations.user.config.theming.signal.editors.helix.enable
```

### Trace Module Evaluation

```bash
# Show evaluation trace
home-manager switch --show-trace

# Show all evaluation steps
nix-instantiate --eval --strict --show-trace
```

### Inspect Generated Configuration

```bash
# Check generated Helix config
cat ~/.config/helix/config.toml

# Check generated Kitty config
cat ~/.config/kitty/kitty.conf

# Check generated Bat themes
ls ~/.config/bat/themes/
```

### Debug Color Values

```nix
{ config, lib, ... }:

let
  signalColors = config.theming.signal.colors;
in
{
  # Print color values at build time
  warnings = [
    "Background: ${signalColors.tonal."surface-Lc05".hex}"
    "Foreground: ${signalColors.tonal."text-Lc75".hex}"
  ];
}
```

### Test Color Application

```bash
# Test Helix colors
helix --health

# Test terminal colors
printf '\e[31mRed\e[0m \e[32mGreen\e[0m \e[34mBlue\e[0m\n'

# Test Bat syntax highlighting
bat ~/.config/helix/config.toml
```

## Contributing New Applications

### Research Phase

1. **Check Home Manager module:**
   ```bash
   nix eval nixpkgs#legacyPackages.x86_64-linux.home-manager.options.programs.<app>
   ```

2. **Find upstream documentation:**
   - Look for theming/color configuration docs
   - Find config file format and structure
   - Identify color options

3. **Determine tier:**
   - Tier 1: Native theme support
   - Tier 2: Structured color options
   - Tier 3: Freeform settings
   - Tier 4: Raw config strings

See [tier-system.md](tier-system.md) for details.

### Implementation Phase

1. **Create module file:**
   ```bash
   touch modules/<category>/<app>.nix
   ```

2. **Use module template:**
   See [templates/module-template.nix](../templates/module-template.nix)

3. **Add metadata:**
   ```nix
   # CONFIGURATION METHOD: <tier>
   # HOME-MANAGER MODULE: programs.<app>
   # UPSTREAM SCHEMA: <url>
   # SCHEMA VERSION: <version>
   # LAST VALIDATED: <date>
   ```

4. **Implement color mapping:**
   ```nix
   { config, lib, signalLib, semantic, ... }:

   let
     cfg = config.theming.signal;
     mode = signalLib.resolveThemeMode cfg.mode;

     shouldTheme =
       cfg.<category>.<app>.enable ||
       (cfg.autoEnable && (config.programs.<app>.enable or false));
   in
   {
     config = lib.mkIf (cfg.enable && shouldTheme) {
       programs.<app> = {
         # Your color configuration
       };
     };
   }
   ```

5. **Test both modes:**
   ```bash
   # Test dark mode
   home-manager switch

   # Test light mode
   # (change mode = "light" in config)
   home-manager switch
   ```

### Documentation Phase

1. **Add to theming-reference.md**
2. **Update README.md**
3. **Create example if needed**
4. **Add tests**

See [CONTRIBUTING_APPLICATIONS.md](../CONTRIBUTING_APPLICATIONS.md) for complete guide.

## Advanced Patterns

### Programmatic Color Generation

```nix
{ lib, signalLib, semantic, ... }:

let
  mode = "dark";

  # Generate ANSI colors programmatically
  ansiColors = lib.genAttrs
    [ "black" "red" "green" "yellow" "blue" "magenta" "cyan" "white" ]
    (color: (semantic.terminal "ansi-${color}" mode).hex);

  # Generate bright ANSI colors
  brightColors = lib.genAttrs
    [ "black" "red" "green" "yellow" "blue" "magenta" "cyan" "white" ]
    (color: (semantic.terminal "ansi-bright-${color}" mode).hex);
in
{
  programs.my-terminal = {
    colors = ansiColors // brightColors;
  };
}
```

### Dynamic Module Loading

```nix
{ config, lib, ... }:

let
  enabledEditors = lib.filter (e: config.programs.${e}.enable or false)
    [ "helix" "neovim" "vim" "vscode" ];
in
{
  theming.signal = {
    enable = true;
    autoEnable = false;

    editors = lib.genAttrs enabledEditors (_: { enable = true; });
  };
}
```

### Color Validation

```nix
{ lib, signalLib, ... }:

let
  validateColor = color:
    assert signalLib.isValidHexColor color;
    color;
in
{
  programs.my-app.colors = {
    background = validateColor "#0a0d12";
    foreground = validateColor "#c5cdd8";
  };
}
```

## Next Steps

- **[Architecture](architecture.md)** - Understand Signal's internals
- **[Contributing](../CONTRIBUTING.md)** - Contribute to Signal
- **[CONTRIBUTING_APPLICATIONS.md](../CONTRIBUTING_APPLICATIONS.md)** - Add new applications
- **[Signal Palette](https://github.com/lewisflude/signal-palette)** - Color system details
