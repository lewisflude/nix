{
  pkgs,
  lib,
  ...
}: {
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    enableZshIntegration = false; # Disable auto-start to prevent session proliferation

    # Core settings managed by Nix
    # Note: Using lib.mkForce to override defaults
    # Theme is handled by catppuccin module (catppuccin.enable = true)
    settings = lib.mkForce {
      default_mode = "locked";
      mouse_mode = true;
      scroll_buffer_size = 100000;
      scroll_rebuffer_on_resize = true;
      pane_frames = true;
      copy_on_select = true;

      # Session management settings
      session_serialization = true; # Auto-save sessions
      simplified_ui = false; # Show useful session info
      on_force_close = "quit"; # Clean exit behavior
    };

    # Keybindings from KDL configuration file
    # Kept separate for easier maintenance and proper KDL syntax
    extraConfig = builtins.readFile ./zellij-config.kdl;

    # Default layout configuration
    layouts.default = ''
      layout {
        pane focus=true {
          cwd "~"
          command "zsh"
        }
      }
    '';
  };
}
