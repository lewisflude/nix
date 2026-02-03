# Cursor Editor - Dendritic Pattern
# AI-powered code editor based on VSCode
{ config, ... }:
{
  flake.modules.homeManager.cursor = { lib, pkgs, config, ... }:
    let
      # Extension definitions
      extensions = [
        {
          name = "biome";
          publisher = "biomejs";
          version = "2025.10.241456";
          sha256 = "sha256-qOEafaDm6wl7oFIp8B1N8S/a8VkfGkqCU0kVMaVI46w=";
        }
        {
          name = "vscode-tailwindcss";
          publisher = "bradlc";
          version = "0.14.29";
          sha256 = "sha256-4x5GcXZk68d3VXdFAoLqDm7uSmXLM2kPLGb52OhvIHs=";
        }
        {
          name = "nix-ide";
          publisher = "jnoortheen";
          version = "0.5.5";
          sha256 = "sha256-q8b1qsXpEZm44ijj0RcEUl/5ySqx/Pf8pGd5pPWqBxs=";
        }
        {
          name = "direnv";
          publisher = "mkhl";
          version = "0.17.0";
          sha256 = "sha256-9sFcfTMeLBGw2ET1snqQ6Uk//D/vcD9AVsZfnUNrWNg=";
        }
        {
          name = "vscode-yaml";
          publisher = "redhat";
          version = "1.19.1";
          sha256 = "sha256-0rIv22xYKF0PbOvUl5yJa7x7fwKsZk1Mc9m6N7sGy/Q=";
        }
        {
          name = "lua";
          publisher = "sumneko";
          version = "3.15.0";
          sha256 = "sha256-R/wPfQDJzZT+Pw46PdlhDPb+eN6JGCZ9Qm3K3qqmrNk=";
        }
        {
          name = "even-better-toml";
          publisher = "tamasfe";
          version = "0.21.2";
          sha256 = "sha256-bF0Z1fPxP0RaKv/VBfpFOOiLqjL2lSXrNr98Pqb+xFs=";
        }
        {
          name = "pretty-ts-errors";
          publisher = "yoavbls";
          version = "0.7.0";
          sha256 = "sha256-WH9Jf9pKE18xBr1CzTilr0VjkMHY3j0D4fEGWD+4NlE=";
        }
      ];

      # Keybindings
      keybindings = [
        {
          key = "ctrl+shift+c";
          command = "copyFilePath";
        }
        {
          key = "ctrl+k ctrl+shift+c";
          command = "copyRelativeFilePath";
        }
      ];

      # User settings
      userSettings = {
        "workbench.colorTheme" = "Default Dark Modern";
        "editor.fontFamily" = "'Iosevka Nerd Font Mono', 'monospace'";
        "editor.fontSize" = 12;
        "editor.lineHeight" = 1.6;
        "editor.formatOnSave" = true;
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "files.autoSave" = "afterDelay";
        "files.autoSaveDelay" = 1000;
        "terminal.integrated.fontFamily" = "'Iosevka Nerd Font Mono'";

        # Nix
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = lib.getExe pkgs.nixd;
        "nix.formatterPath" = lib.getExe pkgs.nixpkgs-fmt;

        # TypeScript
        "[typescript]" = {
          "editor.defaultFormatter" = "biomejs.biome";
        };
        "[typescriptreact]" = {
          "editor.defaultFormatter" = "biomejs.biome";
        };

        # Python
        "python.languageServer" = "Pylance";

        # Direnv
        "direnv.restart.automatic" = true;
      };
    in
    {
      programs.vscode = {
        enable = true;
        package = pkgs.cursor;
        inherit extensions keybindings userSettings;
      };

      # CLI wrapper
      home.packages = [ pkgs.cursor-cli ];
    };
}
