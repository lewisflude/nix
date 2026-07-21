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
# CONFIGURATION METHOD: freeform-settings (Tier 3)
# HOME-MANAGER MODULE: programs.starship.settings
# UPSTREAM SCHEMA: https://starship.rs/config/
# SCHEMA VERSION: 1.17.0
# LAST VALIDATED: 2026-01-17
# NOTES: Home-Manager provides freeform settings attrset that serializes to TOML.
#        Starship supports palette-based theming. Must match starship schema exactly.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  colors = {
    surface-base = semantic.ui "panel-background" themeMode;
    text-primary = semantic.core "foreground" themeMode;
    text-secondary = semantic.text "secondary" themeMode;
    text-tertiary = semantic.text "tertiary" themeMode;
  };

  inherit (signalPalette) accent categorical;

  # Check if starship should be themed
  # Check if starship should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "starship" [
    "prompts"
    "starship"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.starship = {
      settings = {
        # Use Signal palette
        palette = "signal";

        # Define Signal color palette
        palettes.signal = {
          # Base colors
          background = colors.surface-base.hex;
          foreground = colors.text-primary.hex;
          text-secondary = colors.text-secondary.hex;
          text-tertiary = colors.text-tertiary.hex;

          # Accent colors
          focus = accent.secondary.Lc75.hex;
          success = accent.primary.Lc75.hex;
          warning = accent.warning.Lc75.hex;
          danger = accent.danger.Lc75.hex;
          info = accent.secondary.Lc75.hex;
          special = accent.tertiary.Lc75.hex;

          # Categorical colors
          cat-green = categorical.${themeMode}."data-viz-02".hex;
          cat-purple = categorical.${themeMode}."data-viz-06".hex;
          cat-yellow = categorical.${themeMode}."data-viz-08".hex;
        };

        # Prompt format
        format = lib.concatStrings [
          "$username"
          "$hostname"
          "$directory"
          "$git_branch"
          "$git_status"
          "$git_state"
          "$package"
          "$cmd_duration"
          "$line_break"
          "$character"
        ];

        # Character (prompt symbol)
        character = {
          success_symbol = "[❯](bold success)";
          error_symbol = "[❯](bold danger)";
          vimcmd_symbol = "[❮](bold special)";
        };

        # Directory
        directory = {
          style = "bold focus";
          truncation_length = 3;
          truncate_to_repo = true;
        };

        # Git branch
        git_branch = {
          format = "[$symbol$branch(:$remote_branch)]($style) ";
          symbol = " ";
          style = "bold special";
        };

        # Git status
        git_status = {
          format = "([$all_status$ahead_behind]($style) )";
          style = "bold warning";
          conflicted = "=";
          ahead = "⇡";
          behind = "⇣";
          diverged = "⇕";
          up_to_date = "";
          untracked = "?";
          stashed = "$";
          modified = "!";
          staged = "+";
          renamed = "»";
          deleted = "✘";
        };

        # Git state (rebasing, etc.)
        git_state = {
          format = "[$state( $progress_current/$progress_total)]($style) ";
          style = "bold danger";
        };

        # Command duration
        cmd_duration = {
          format = "[$duration]($style) ";
          style = "bold text-secondary";
          min_time = 500;
        };

        # Package version
        package = {
          format = "[$symbol$version]($style) ";
          symbol = " ";
          style = "bold cat-purple";
        };

        # Username
        username = {
          format = "[$user]($style)@";
          style_user = "bold info";
          show_always = false;
        };

        # Hostname
        hostname = {
          format = "[$hostname]($style) ";
          style = "bold info";
          ssh_only = true;
        };

        # Language/framework modules (sampling)
        nodejs = {
          format = "[$symbol($version )]($style)";
          symbol = " ";
          style = "bold cat-green";
        };

        python = {
          format = "[$symbol$pyenv_prefix($version )(\\($virtualenv\\) )]($style)";
          symbol = " ";
          style = "bold cat-yellow";
        };

        rust = {
          format = "[$symbol($version )]($style)";
          symbol = " ";
          style = "bold danger";
        };

        golang = {
          format = "[$symbol($version )]($style)";
          symbol = " ";
          style = "bold info";
        };

        # Time (if enabled)
        time = {
          format = "[$time]($style) ";
          style = "bold text-tertiary";
          disabled = true;
        };
      };
    };
  };
}
