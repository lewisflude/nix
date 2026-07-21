{
  signalLib,
  signalPalette,
  semantic,
  nix-colorizer,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
# CONFIGURATION METHOD: raw-config (Tier 4)
# HOME-MANAGER MODULE: programs.zsh.initExtra (via powerlevel10k config)
# UPSTREAM SCHEMA: https://github.com/romkatv/powerlevel10k
# SCHEMA VERSION: 1.20.0
# LAST VALIDATED: 2026-01-29
# NOTES: Powerlevel10k uses ANSI 256-color codes (0-255).
#        This module provides semantic color mappings using standard ANSI codes.
#        Requires terminal theming to be enabled (ghostty, alacritty, etc.)
#        The terminal theme maps ANSI codes to Signal palette hex colors.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Auto-detect if powerlevel10k is enabled by checking zsh configuration
  # Look for p10k in zsh plugins, initExtra, or initExtraFirst
  hasPowerlevel10k =
    (config.programs.zsh.enable or false)
    && (
      # Check if p10k is in zsh plugins
      (builtins.any (
        plugin:
        (lib.hasInfix "powerlevel10k" (plugin.name or ""))
        || (lib.hasInfix "powerlevel10k" (plugin.src or ""))
      ) (config.programs.zsh.plugins or [ ]))
      # Check if p10k is referenced in initExtra/initExtraFirst
      || (lib.hasInfix "powerlevel10k" (config.programs.zsh.initExtra or ""))
      || (lib.hasInfix "powerlevel10k" (config.programs.zsh.initExtraFirst or ""))
      || (lib.hasInfix "p10k" (config.programs.zsh.initExtra or ""))
      || (lib.hasInfix "p10k" (config.programs.zsh.initExtraFirst or ""))
    );

  # Check if powerlevel10k should be themed
  # Use auto-detection OR explicit enable
  shouldTheme =
    cfg.enable
    && (
      cfg.prompts.powerlevel10k.enable # Explicitly enabled
      || (cfg.autoEnable && hasPowerlevel10k) # Auto-detected
    );

  # Map semantic concepts to standard ANSI color codes
  # These rely on terminal theming (ghostty/alacritty) to provide actual colors
  # Basic ANSI codes (0-15): Terminal emulator maps these to Signal palette
  # Extended codes (16-255): 256-color palette (less precise but works)

  # IMPORTANT: This approach assumes terminal theming is active
  # The terminal (themed by signal-nix) provides the actual hex colors
  # We just reference ANSI codes here, which the terminal interprets

  colorExport = {
    # Status colors - use terminal ANSI codes that signal-nix terminals provide
    success = 2; # ANSI green (mapped to signal success by terminal theme)
    warning = 3; # ANSI yellow (mapped to signal warning by terminal theme)
    error = 1; # ANSI red (mapped to signal error by terminal theme)
    info = 6; # ANSI cyan (mapped to signal info by terminal theme)

    # Text hierarchy
    grey_light = 7; # ANSI white (bright foreground)
    grey_mid = 8; # ANSI bright-black (dim text)
    grey_dark = 0; # ANSI black (background/very dim)

    # Directory colors
    dir_default = 4; # ANSI blue (directories)
    dir_shortened = 8; # ANSI bright-black (dimmed)
    dir_anchor = 6; # ANSI cyan (highlights)

    # VCS (Git) colors
    vcs_clean = 2; # ANSI green (clean state)
    vcs_modified = 3; # ANSI yellow (modified)
    vcs_untracked = 6; # ANSI cyan (untracked)
    vcs_conflicted = 1; # ANSI red (conflicts)

    # Context colors (user@host, shells)
    context_root = 9; # ANSI bright-red (root/danger)
    context_remote = 8; # ANSI bright-black (remote sessions)
    context_default = 8; # ANSI bright-black (normal context)

    # Shell indicators
    nix_shell = 12; # ANSI bright-blue (nix environment)
    direnv = 3; # ANSI yellow (environment modified)

    # Background
    background = 0; # ANSI black (segment backgrounds)
  };
in
{
  config = mkIf shouldTheme {
    # Export ANSI color codes for consumption by main config
    # Usage in powerlevel10k config:
    #   colors = config.theming.signal.colors.powerlevel10k or { fallback values };
    #   success = colors.success;  # Returns ANSI code
    theming.signal.colors.powerlevel10k = colorExport;

    # Add warning if terminal theming is not detected
    warnings =
      lib.optionals
        (
          !(config.programs.ghostty.enable or false)
          && !(config.programs.alacritty.enable or false)
          && !(config.programs.kitty.enable or false)
          && !(config.programs.wezterm.enable or false)
          && !(config.programs.foot.enable or false)
        )
        [
          ''
            Signal powerlevel10k theming requires a themed terminal emulator.
            Enable one of: programs.ghostty, programs.alacritty, programs.kitty, programs.wezterm, or programs.foot
            Signal will automatically theme your terminal to provide correct ANSI color mappings.
          ''
        ];
  };
}
