# MCP Configuration for macOS (nix-darwin)
#
# This module configures MCP (Model Context Protocol) servers for macOS systems
# using nix-darwin and home-manager. It provides activation hooks for registration
# and wrapper scripts for secret management.
#
# Features:
# - Automatic MCP server registration with Claude CLI
# - Integration with Cursor and Claude Code applications
# - SOPS secret management for API keys
# - Platform-specific wrapper scripts for Darwin
#
# Differences from NixOS:
# - Uses home.file for wrappers instead of writeShellApplication
# - Uses home-manager activation hooks instead of systemd services
# - GitHub server runs via Docker container
#
# See also:
# - modules/shared/mcp/: Shared module definitions
# - home/nixos/mcp.nix: NixOS-specific configuration
{
  pkgs,
  config,
  systemConfig,
  lib,
  system,
  ...
}:

let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
  claudeConfigDir = platformLib.dataDir config.home.username + "/Claude";

  # Import shared MCP utilities
  servers = import ../../modules/shared/mcp/servers.nix { inherit pkgs config; };

  inherit (lib)
    concatStringsSep
    mapAttrsToList
    escapeShellArg
    optionalString
    ;

  # Darwin-specific wrapper for Kagi (using home.file instead of writeShellApplication)
  # This is required because Darwin has different file permission requirements
  kagiWrapperScript = ''
    #!/usr/bin/env bash
    set -euo pipefail

    if [ -r "${systemConfig.sops.secrets.KAGI_API_KEY.path or ""}" ]; then
      export KAGI_API_KEY="$(${pkgs.coreutils}/bin/cat "${
        systemConfig.sops.secrets.KAGI_API_KEY.path or ""
      }")"
    fi

    export UV_PYTHON="${pkgs.python3}/bin/python3"
    exec ${pkgs.uv}/bin/uvx --from kagimcp kagimcp "$@"
  '';

  # Darwin-specific wrapper for Docs MCP server
  docsWrapperScript = ''
    #!/usr/bin/env bash
    set -euo pipefail

    if [ -r "${systemConfig.sops.secrets.OPENAI_API_KEY.path or ""}" ]; then
      export OPENAI_API_KEY="$(${pkgs.coreutils}/bin/cat "${
        systemConfig.sops.secrets.OPENAI_API_KEY.path or ""
      }")"
    fi

    exec ${servers.nodejs}/bin/npx -y @arabold/docs-mcp-server@latest "$@"
  '';

in
{
  home = {
    # Install required packages
    packages = [
      pkgs.uv
      servers.nodejs
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

    # Register MCP servers with Claude CLI on activation
    activation.setupClaudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      let
        cfg = config.services.mcp;

        # Generate Claude CLI add commands for each server
        mcpAddCommands = concatStringsSep "\n        " (
          mapAttrsToList (
            name: serverCfg:
            let
              command = escapeShellArg serverCfg.command;
              argsStr = concatStringsSep " " (map escapeShellArg serverCfg.args);
              argsPart = optionalString (argsStr != "") "-- ${argsStr}";
              envVars = concatStringsSep " " (
                mapAttrsToList (key: value: "export ${escapeShellArg key}=${escapeShellArg value};") serverCfg.env
              );
            in
            ''${envVars} claude mcp add ${escapeShellArg name} -s user ${command} ${argsPart} || echo "Failed to add ${name} server"''
          ) cfg.servers
        );
      in
      ''
        if command -v claude >/dev/null 2>&1; then
          echo "[mcp] Registering MCP servers with Claude Code..."

          # Clean up old configuration files
          ${pkgs.findutils}/bin/find ~/.config/claude -name "*.json" -delete 2>/dev/null || true

          $DRY_RUN_CMD ${pkgs.writeShellScript "setup-claude-mcp" ''
            set -euo pipefail

            echo "[mcp] Removing existing MCP servers..."
            for server in ${
              concatStringsSep " " (mapAttrsToList (name: _: escapeShellArg name) cfg.servers)
            }; do
              claude mcp remove "$server" -s user 2>/dev/null || true
              claude mcp remove "$server" -s project 2>/dev/null || true
              claude mcp remove "$server" 2>/dev/null || true
            done

            echo "[mcp] Running MCP server registration commands..."
            ${mcpAddCommands}

            echo "[mcp] Claude MCP server registration complete"
          ''}
        else
          echo "[mcp] WARNING: Claude CLI not found, skipping MCP server registration"
        fi
      ''
    );
  };

  # Configure MCP service
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

    # Server configurations
    servers = servers.commonServers // {
      # Override time server for Darwin (platform-specific port)
      time = {
        command = "${pkgs.uv}/bin/uvx";
        args = [
          "--from"
          "mcp-server-time"
          "mcp-server-time"
        ];
        port = servers.ports.time-darwin;
        env = {
          UV_PYTHON = "${pkgs.python3}/bin/python3";
        };
      };

      # Override sequential-thinking for Darwin (platform-specific port)
      sequential-thinking = {
        command = "${servers.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
        port = servers.ports.sequential-thinking-darwin;
      };

      # Darwin-specific Kagi server (uses home.file wrapper)
      kagi = {
        command = "${config.home.homeDirectory}/bin/kagi-mcp-wrapper";
        args = [ ];
        port = servers.ports.kagi;
      };

      # Darwin-specific Docs MCP server (uses home.file wrapper)
      docs-mcp-server = {
        command = "${config.home.homeDirectory}/bin/docs-mcp-wrapper";
        args = [ ];
        port = servers.ports.docs;
      };

      # Darwin uses Docker for GitHub MCP server
      github = {
        command = "${pkgs.docker}/bin/docker";
        args = [
          "run"
          "-i"
          "--rm"
          "-e"
          "GITHUB_TOKEN"
          "ghcr.io/github/github-mcp-server"
        ];
        port = servers.ports.github;
        env = {
          GITHUB_TOKEN = systemConfig.sops.secrets.GITHUB_TOKEN.path or "";
        };
      };
    };
  };
}
