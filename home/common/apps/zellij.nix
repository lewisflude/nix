{
  pkgs,
  lib,
  ...
}: {
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    enableZshIntegration = true;

    # Core settings managed by Nix
    # Note: Using lib.mkForce to override defaults
    settings = lib.mkForce {
      theme = "default";
      default_mode = "locked";
      mouse_mode = true;
      scroll_buffer_size = 100000;
      scroll_rebuffer_on_resize = true;
      pane_frames = true;
      copy_on_select = true;
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
        pane split_direction="vertical" {
          cwd "~"
          command "zsh"
        }
      }
    '';
  };
}
