# Zed Editor - Dendritic Pattern
# Fast, collaborative code editor
_: {
  flake.modules.homeManager.zed =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.nixd
        pkgs.nixfmt
      ];

      programs.zed-editor = {
        enable = true;
        package = null;

        mutableUserSettings = true;

        userSettings = {
          ui_font_size = 14;
          ui_font_family = "Iosevka Nerd Font Mono";
          buffer_font_size = 12;

          telemetry = {
            metrics = false;
            diagnostics = false;
          };

          languages = {
            Nix = {
              language_servers = [ "nixd" ];
              formatter = {
                external = {
                  command = "nixfmt";
                };
              };
            };
          };

          lsp = {
            nixd = {
              initialization_options = {
                formatting = {
                  command = [ "nixfmt" ];
                };
              };
            };
          };
        };
      };
    };

  flake.modules.darwin.zed = _: {
    homebrew.casks = [ "zed" ];
  };
}
