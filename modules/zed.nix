# Zed Editor - Dendritic Pattern
# Fast, collaborative code editor
_: {
  flake.modules.homeManager.zed = _: {
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
          CSS = {
            language_servers = [
              "tailwindcss-intellisense-css"
              "!vscode-css-language-server"
              "..."
            ];
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
          tailwindcss-language-server = {
            settings = {
              classFunctions = [
                "cva"
                "cx"
                "clsx"
                "cn"
                "tw"
              ];
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
