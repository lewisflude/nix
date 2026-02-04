# Zed Editor - Dendritic Pattern
# Fast, collaborative code editor
{ config, ... }:
{
  flake.modules.homeManager.zed =
    { lib, pkgs, ... }:
    {
      programs.zed-editor = {
        enable = true;
        installRemoteServer = true;

        extraPackages = [
          pkgs.nixd
          pkgs.nixfmt
          pkgs.vtsls
          pkgs.vscode-langservers-extracted
          pkgs.basedpyright
          pkgs.ruff
          pkgs.rust-analyzer
        ];

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
            TypeScript = {
              language_servers = [
                "vtsls"
                "..."
              ];
              formatter = "language_server";
            };
            Python = {
              language_servers = [
                "basedpyright"
                "ruff"
              ];
              format_on_save = "on";
              formatter = {
                external = {
                  command = "ruff";
                  arguments = [
                    "format"
                    "--stdin-filename"
                    "{buffer_path}"
                  ];
                };
              };
            };
            Rust = {
              format_on_save = "on";
              formatter = "language_server";
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
            rust-analyzer = {
              initialization_options = {
                check = {
                  command = "clippy";
                };
              };
            };
            vtsls = {
              binary = {
                path = lib.getExe pkgs.vtsls;
                arguments = [ "--stdio" ];
              };
            };
            eslint = {
              binary = {
                path = "${pkgs.vscode-langservers-extracted}/bin/vscode-eslint-language-server";
                arguments = [ "--stdio" ];
              };
            };
          };
        };
      };
    };
}
