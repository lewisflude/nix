{ ... }: {
  # Darwin-specific terminal configuration
  # Base configuration is imported from ../common/terminal.nix
  
  programs.ghostty.settings = {
    # Darwin-specific font configuration
    font-family = "Iosevka Nerd Font Mono";
    font-size = "16";
    
    # macOS-specific display settings
    window-colorspace = "display-p3";
    window-padding-x = "10";
    window-padding-y = "10";
    background-opacity = "1.0";
    background-blur = "0";

    # Cursor configuration
    cursor-style = "block";
    cursor-style-blink = "true";

    # Terminal behavior
    copy-on-select = "true";
    scrollback-limit = "10000";

    # Performance settings
    window-vsync = "true";

    # Window configuration
    window-decoration = "true";
    window-save-state = "always";

    # Theme
    theme = "catppuccin-mocha";
    
    # Override package to null for Darwin
    package = null;
  };
}
