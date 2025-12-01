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
  constants,
  ...
}:

let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
  claudeConfigDir = platformLib.dataDir config.home.username + "/Claude";

  # Custom wrappers for Darwin (using home.file)
  # TEMPORARILY DISABLED: uv build failing
  kagiWrapperScript = ''
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Kagi MCP server temporarily disabled due to uv build failure" >&2
    exit 1
  '';

  # kagiWrapperScript = ''
  #   #!/usr/bin/env bash
  #   set -euo pipefail
  #
  #   if [ -r "${systemConfig.sops.secrets.KAGI_API_KEY.path or ""}" ]; then
  #     export KAGI_API_KEY="$(${pkgs.coreutils}/bin/cat "${
  #       systemConfig.sops.secrets.KAGI_API_KEY.path or ""
  #     }")"
  #   fi
  #
  #   export UV_PYTHON="${pkgs.python3}/bin/python3"
  #   exec ${pkgs.uv}/bin/uvx --from kagimcp==0.2.0 kagimcp "$@"
  # '';

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
    # TEMPORARILY DISABLED: uv build failing
    # nixos = {
    #   command = "${pkgs.uv}/bin/uvx";
    #   args = [
    #     "--from"
    #     "mcp-nixos==0.2.0"
    #     "mcp-nixos"
    #   ];
    #   port = constants.ports.mcp.nixos;
    #   env = {
    #     UV_PYTHON = "${pkgs.python3}/bin/python3";
    #   };
    # };

    # Kagi MCP server with SOPS integration
    # TEMPORARILY DISABLED: uv build failing
    # kagi = {
    #   command = "${config.home.homeDirectory}/bin/kagi-mcp-wrapper";
    #   args = [ ];
    #   port = constants.ports.mcp.kagi;
    # };

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
  # NOTE: Disabled due to missing pkgs.mcp-servers
  # imports = [ inputs.mcps.homeManagerModules.claude ];

  home = {
    # Install required packages
    packages = [
      # pkgs.uv  # Temporarily disabled due to build failure
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
  # NOTE: claude-code is now available via programs.claude-code in home/common/apps/claude-code.nix
  # MCP servers also disabled since they require pkgs.mcp-servers which is not provided by nixpkgs
  # programs.claude-code = {
  #   enable = true;
  #
  #   mcps = {
  #     # Disabled: require pkgs.mcp-servers which is not provided by overlay
  #     git.enable = false;
  #     filesystem.enable = false;
  #     github.enable = false;
  #     fetch.enable = false;
  #     sequential-thinking.enable = false;
  #     time.enable = false;
  #     lsp-typescript.enable = false;
  #     lsp-nix.enable = false;
  #     lsp-rust.enable = false;
  #     lsp-python.enable = false;
  #   };
  # };

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
