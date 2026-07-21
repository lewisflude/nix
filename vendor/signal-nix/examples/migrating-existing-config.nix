# Signal Design System - Migration Example
# Adding Signal to an existing Home Manager configuration

{
  description = "Adding Signal to an existing Home Manager setup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    signal.url = "github:lewisflude/signal-nix"; # ← Add this line
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      signal, # ← Add this parameter
      ...
    }:
    {
      homeConfigurations.yourname = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;

        modules = [
          # Your existing home.nix
          ./home.nix

          # Your existing program configurations
          ./programs/editors.nix
          ./programs/terminals.nix
          ./programs/cli-tools.nix

          # Add Signal module ← This is all you need to add
          signal.homeManagerModules.default

          # Option 1: Configure Signal inline
          {
            theming.signal = {
              enable = true; # Automatically themes all your enabled programs
              mode = "dark";
            };
          }

          # Option 2: Or import from a separate file (recommended)
          # ./theming.nix
        ];
      };
    };
}

# ============================================================================
# ALTERNATIVE: If you prefer a separate theming.nix file (recommended)
# ============================================================================
#
# Create: ~/.config/home-manager/theming.nix
#
# { config, ... }:
#
# {
#   theming.signal = {
#     enable = true;  # Automatically themes all your existing enabled programs
#     mode = "dark";
#
#     # Optional: Disable specific programs if needed
#     # cli.bat.enable = false;  # Keep my custom bat theme
#   };
# }
#
# Then in flake.nix:
#   modules = [
#     signal.homeManagerModules.default
#     ./home.nix
#     ./theming.nix  # ← Add this
#   ];

# ============================================================================
# WHAT CHANGES
# ============================================================================
#
# Before Signal:
#   - You enable programs: programs.helix.enable = true
#   - Programs use their default themes
#
# After Signal (with default auto-theming):
#   - You still enable programs: programs.helix.enable = true
#   - Signal automatically applies colors to enabled programs
#   - No changes needed to your existing program configs!
#
# Signal automatically detects which programs you've enabled and applies
# its colors to them. Zero configuration needed!

# ============================================================================
# GRADUAL MIGRATION APPROACH
# ============================================================================
#
# If you're not sure about theming everything at once, you can migrate gradually:
#
# Step 1: Enable Signal (themes everything automatically)
# {
#   theming.signal = {
#     enable = true;  # Themes all your programs
#     mode = "dark";
#   };
# }
#
# Step 2: If you prefer, disable specific programs
# {
#   theming.signal = {
#     enable = true;
#     mode = "dark";
#     cli.bat.enable = false;  # Keep bat's default theme
#   };
# }
#
# Step 3: For complete manual control (advanced)
# {
#   theming.signal = {
#     enable = true;
#     autoEnable = false;  # Disable automatic theming
#     editors.helix.enable = true;  # Manually enable each app
#   };
# }

# ============================================================================
# EXAMPLE: Real existing config
# ============================================================================
#
# Let's say you have this existing home.nix:
#
# { config, pkgs, ... }:
# {
#   home = {
#     username = "alice";
#     homeDirectory = "/home/alice";
#     stateVersion = "24.11";
#   };
#
#   programs = {
#     helix.enable = true;
#     kitty.enable = true;
#     bat.enable = true;
#     fzf.enable = true;
#     starship.enable = true;
#
#     # You might have custom configs here
#     helix.settings = {
#       # Your custom keybindings, etc.
#     };
#   };
# }
#
# After adding Signal, it becomes:
#
# { config, pkgs, ... }:
# {
#   home = {
#     username = "alice";
#     homeDirectory = "/home/alice";
#     stateVersion = "24.11";
#   };
#
#   programs = {
#     # Your programs stay exactly the same!
#     helix.enable = true;
#     kitty.enable = true;
#     bat.enable = true;
#     fzf.enable = true;
#     starship.enable = true;
#
#     # Your custom configs are preserved
#     helix.settings = {
#       # Your custom keybindings work alongside Signal colors
#     };
#   };
#
#   # Just add this block - Signal handles the rest
#   theming.signal = {
#     enable = true;  # Automatically themes all enabled programs
#     mode = "dark";
#   };
# }

# ============================================================================
# REVERTING (if you change your mind)
# ============================================================================
#
# To remove Signal theming:
#
# 1. Set enable = false:
#    theming.signal.enable = false;
#
# 2. Or remove the Signal module entirely:
#    modules = [
#      # signal.homeManagerModules.default  # ← Comment out
#      ./home.nix
#    ];
#
# 3. Rebuild:
#    home-manager switch
#
# Your programs will revert to their default themes.

# ============================================================================
# COMMON MIGRATION SCENARIOS
# ============================================================================

# Scenario 1: You have an existing theme (like Catppuccin)
# ---------------------------------------------------------
# {
#   # Keep your existing theme initially
#   catppuccin.enable = true;
#
#   # Add Signal for specific programs
#   theming.signal = {
#     enable = true;
#     editors.helix.enable = true;  # Try Signal on helix
#   };
#
#   # Disable Catppuccin for helix to avoid conflict
#   catppuccin.helix.enable = false;
# }

# Scenario 2: You use stylix
# ---------------------------------------------------------
# {
#   # Stylix handles wallpaper-based system theming
#   stylix = {
#     enable = true;
#     image = ./wallpaper.jpg;
#   };
#
#   # Signal handles application-specific colors
#   theming.signal = {
#     enable = true;
#     mode = "dark";
#
#     # Be selective to avoid conflicts
#     editors.helix.enable = true;
#     cli.bat.enable = true;
#   };
# }

# Scenario 3: You have custom per-app themes
# ---------------------------------------------------------
# {
#   programs = {
#     helix.enable = true;
#     kitty.enable = true;
#
#     # You have a custom kitty theme you want to keep
#     kitty.theme = "MyCustomTheme";
#   };
#
#   theming.signal = {
#     enable = true;  # autoEnable is true by default
#
#     # Exclude kitty from Signal theming
#     terminals.kitty.enable = false;
#   };
# }

# ============================================================================
# REBUILD INSTRUCTIONS
# ============================================================================
#
# After modifying your flake.nix:
#
# 1. Update flake.lock to fetch Signal:
#    nix flake update
#
# 2. Rebuild your Home Manager configuration:
#    home-manager switch --flake .#yourname
#
# 3. Restart your applications to see the new colors
#
# That's it! Your programs should now use Signal colors.
