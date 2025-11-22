# MCP Configuration for macOS (mcps.nix flake integration)
#
# This module uses roman/mcps.nix for version-pinned MCP servers.
# Servers provided by mcps.nix: git, github, filesystem, fetch, sequential-thinking, time, LSPs
# Custom servers: memory, nixos, kagi, openai, docs-mcp-server
{
  pkgs,
  config,
  systemConfig,
  lib,
  system,
  inputs,
  constants,
  ...
}:

let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
  claudeConfigDir = platformLib.dataDir config.home.username + "/Claude";

  # Custom wrappers for Darwin (using home.file)
  kagiWrapperScript = ''
    #!/usr/bin/env bash
    set -euo pipefail

    if [ -r "${systemConfig.sops.secrets.KAGI_API_KEY.path or ""}" ]; then
      export KAGI_API_KEY="$(${pkgs.coreutils}/bin/cat "${
        systemConfig.sops.secrets.KAGI_API_KEY.path or ""
      }")"
    fi

    export UV_PYTHON="${pkgs.python3}/bin/python3"
    exec ${pkgs.uv}/bin/uvx --from kagimcp==0.2.0 kagimcp "$@"
  '';

  docsWrapperScript = ''
    #!/usr/bin/env bash
    set -euo pipefail

    if [ -r "${systemConfig.sops.secrets.OPENAI_API_KEY.path or ""}" ]; then
      export OPENAI_API_KEY="$(${pkgs.coreutils}/bin/cat "${
        systemConfig.sops.secrets.OPENAI_API_KEY.path or ""
      }")"
    fi

    exec ${pkgs.nodejs}/bin/npx -y @arabold/docs-mcp-server@0.3.1 "$@"
  '';

  # Custom servers not provided by mcps.nix
  customServers = {
    # Memory server - not in mcps.nix
    memory = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-memory@0.1.0"
      ];
      port = constants.ports.mcp.memory;
    };

    # NixOS-specific MCP server
    nixos = {
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--from"
        "mcp-nixos==0.2.0"
        "mcp-nixos"
      ];
      port = constants.ports.mcp.nixos;
      env = {
        UV_PYTHON = "${pkgs.python3}/bin/python3";
      };
    };

    # Kagi MCP server with SOPS integration
    kagi = {
      command = "${config.home.homeDirectory}/bin/kagi-mcp-wrapper";
      args = [ ];
      port = constants.ports.mcp.kagi;
    };

    # Docs MCP server with SOPS integration
    docs-mcp-server = {
      command = "${config.home.homeDirectory}/bin/docs-mcp-wrapper";
      args = [ ];
      port = constants.ports.mcp.docs;
    };
  };

in
{
  # Import mcps.nix home-manager module
  imports = [ inputs.mcps.homeManagerModules.claude ];

  home = {
    # Install required packages
    packages = [
      pkgs.uv
      pkgs.nodejs
    ];

    # Create wrapper scripts with proper permissions
    file = {
      "bin/kagi-mcp-wrapper" = {
        text = kagiWrapperScript;
        executable = true;
      };
      "bin/docs-mcp-wrapper" = {
        text = docsWrapperScript;
        executable = true;
      };
    };
  };

  # Configure mcps.nix servers
  programs.claude-code = {
    enable = true;

    mcps = {
      # Version control
      git.enable = true;

      # Filesystem access
      filesystem = {
        enable = true;
        allowedPaths = [
          "${config.home.homeDirectory}/Code"
          "${config.home.homeDirectory}/.config"
          "${config.home.homeDirectory}/Documents"
        ];
      };

      # GitHub integration
      github = {
        enable = true;
        tokenFilepath = systemConfig.sops.secrets.GITHUB_TOKEN.path;
      };

      # Web fetching
      fetch.enable = true;

      # Sequential thinking
      sequential-thinking.enable = true;

      # Time utilities
      time = {
        enable = true;
        timezone = constants.timezone or "UTC";
      };

      # Language servers
      lsp-typescript = {
        enable = true;
        workspace = "${config.home.homeDirectory}/Code";
      };

      lsp-nix = {
        enable = true;
        workspace = "${config.home.homeDirectory}/nix";
      };

      lsp-rust = {
        enable = true;
        workspace = "${config.home.homeDirectory}/Code";
      };

      lsp-python = {
        enable = true;
        workspace = "${config.home.homeDirectory}/Code";
      };
    };
  };

  # Legacy services.mcp configuration for Cursor compatibility
  services.mcp = {
    enable = true;

    # Target applications
    targets = {
      cursor = {
        directory = "${config.home.homeDirectory}/.cursor";
        fileName = "mcp.json";
      };
      claude = {
        directory = claudeConfigDir;
        fileName = "claude_desktop_config.json";
      };
    };

    # Add custom servers to legacy config
    servers = customServers;
  };
}
