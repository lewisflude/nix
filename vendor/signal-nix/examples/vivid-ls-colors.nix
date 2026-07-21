# Example: Using vivid for LS_COLORS with Signal theming
#
# This example demonstrates the preferred way to configure LS_COLORS using vivid.
# Vivid provides:
# - Comprehensive file type database (hundreds of extensions)
# - RGB hex color support with automatic terminal compatibility
# - Easy maintenance through YAML themes
# - Industry standard used by fd, eza, tree, and other tools
#
# For backward compatibility, the ls-colors module is still available but deprecated.
{
  theming.signal = {
    enable = true;
    autoEnable = true; # Auto-theme all enabled programs
    mode = "dark"; # or "light" or "auto"

    # Enable vivid with Signal colors
    cli.vivid = {
      enable = true;

      # Color mode for terminal compatibility
      # Use "24-bit" for modern terminals with true color support
      # Use "8-bit" for older terminals (256 colors)
      colorMode = "24-bit";

      # Cache the vivid output (default: true)
      # Generates LS_COLORS at build time and stores in a file,
      # significantly improving shell startup time (~20-50ms savings).
      # Disable this only if you need runtime theme switching.
      cache = true;

      # Shell integration - automatically sets LS_COLORS in your shell
      enableBashIntegration = true; # For bash users
      enableFishIntegration = true; # For fish users
      enableZshIntegration = true; # For zsh users
    };
  };

  # Make sure your shell is enabled for integration
  programs.bash.enable = true;
  programs.fish.enable = true;
  programs.zsh.enable = true;

  # Tools that automatically use LS_COLORS (when vivid is enabled):
  # - ls (GNU coreutils)
  # - tree
  # - fd
  # - bfs
  # - dust
  # - eza (also uses EZA_COLORS but respects LS_COLORS as fallback)
  # - Many file managers and shell completions
}
