{ pkgs, ... }:

{
  programs.zed-editor = {
    enable = true;

    # Fix: This symlinks Zed's remote server binary to the expected location,
    # which is often required for stable extension/LSP behavior in Nix.
    installRemoteServer = true;

    # Ensure LSPs and tools are available to Zed's environment
    extraPackages = with pkgs; [
      nixd
      nixpkgs-fmt
      # Tools to bypass the npm E401 authentication errors
      vtsls
      tailwindcss-language-server
      vscode-langservers-extracted # Provides ESLint
      nodePackages.typescript-language-server
      basedpyright
      ruff
      rust-analyzer
    ];
    mutableUserSettings = false;

    userSettings = {
      # Performance - Optimized for your hardware
      "ui_font_size" = 16;
      "ui_font_family" = "Iosevka Nerd Font Mono";
      "buffer_font_size" = 14;

      "telemetry" = {
        "metrics" = false;
        "diagnostics" = false;
      };

      # Language Specifics
      "languages" = {
        "Nix" = {
          "language_servers" = [ "nixd" ];
          "formatter" = {
            "external" = {
              "command" = "nixpkgs-fmt";
            };
          };
        };
        "TypeScript" = {
          # Use vtsls as primary to avoid the broken internal vtsls download
          "language_servers" = [
            "vtsls"
            "..."
          ];
          "formatter" = "language_server";
        };
        "Python" = {
          "language_servers" = [
            "basedpyright"
            "ruff"
          ];
          "format_on_save" = "on";
          "formatter" = {
            "external" = {
              "command" = "ruff";
              "arguments" = [
                "format"
                "--stdin-filename"
                "{buffer_path}"
              ];
            };
          };
        };
        "Rust" = {
          "format_on_save" = "on";
          "formatter" = "language_server";
        };
      };

      # LSP Configuration
      "lsp" = {
        "nixd" = {
          "initialization_options" = {
            "formatting" = {
              "command" = [ "nixpkgs-fmt" ];
            };
          };
        };
        "rust-analyzer" = {
          "initialization_options" = {
            "check" = {
              "command" = "clippy";
            };
          };
        };
        # Explicit paths to bypass npm/download failures
        "vtsls" = {
          "binary" = {
            "path" = "${pkgs.vtsls}/bin/vtsls";
            "arguments" = [ "--stdio" ];
          };
        };
        "tailwindcss-language-server" = {
          "binary" = {
            "path" = "${pkgs.tailwindcss-language-server}/bin/tailwindcss-language-server";
            "arguments" = [ "--stdio" ];
          };
        };
        "eslint" = {
          "binary" = {
            "path" = "${pkgs.vscode-langservers-extracted}/bin/vscode-eslint-language-server";
            "arguments" = [ "--stdio" ];
          };
        };
      };
    };
  };
}
