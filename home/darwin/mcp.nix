# MCP Configuration for macOS (Darwin)
#
# This module configures Model Context Protocol (MCP) servers for macOS hosts.
# It uses the shared wrappers module and provides platform-specific integration
# via LaunchAgents for persistent server management.
#
# Architecture:
# - Shared wrappers from modules/shared/mcp/wrappers.nix
# - Configuration via services.mcp (home/common/modules/mcp.nix)
# - LaunchAgent for automatic server registration on login
# - Health checks via wrapper scripts (--health-check flag)
#
# Active Servers:
# - memory: Knowledge graph-based persistent memory (npx)
# - docs-mcp-server: Documentation indexing (npx, requires OPENAI_API_KEY)
# - openai: General OpenAI integration (npx, requires OPENAI_API_KEY)
# - rustdocs: Rust documentation for Bevy (Nix build, requires OPENAI_API_KEY)
#
# Disabled Servers (awaiting uv package fix):
# - kagi: Search and summarization (requires uv)
# - nixos: NixOS package search (requires uv)
#
# Configuration Targets:
# - Cursor: ~/.cursor/mcp.json
# - Claude Code: ~/Library/Application Support/Claude/claude_desktop_config.json
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

  # Import shared wrappers module
  wrappers = import ../../modules/shared/mcp/wrappers.nix {
    inherit pkgs lib systemConfig;
  };

  # Port key mapping: server name -> constants.ports.mcp.<key>
  # This maps server names to their corresponding port constant keys
  portKeys = {
    memory = "memory";
    "docs-mcp-server" = "docs";
    openai = "openai";
    rustdocs = "rustdocs";
    kagi = "kagi";
    nixos = "nixos";
  };

  # Server definitions with feature flags
  # Each server has:
  # - enabled: Whether to include in configuration
  # - available: Whether dependencies are satisfied
  # - wrapper: Path to wrapper script
  # - portKey: Key for looking up port in constants.ports.mcp
  # - config: MCP server configuration
  servers = {
    memory = {
      enabled = true;
      available = true;
      wrapper = wrappers.memoryWrapper;
      portKey = portKeys.memory;
      config = {
        command = "${wrappers.memoryWrapper}/bin/memory-mcp-wrapper";
        args = [ ];
        port = constants.ports.mcp.memory;
      };
    };

    "docs-mcp-server" = {
      enabled = true;
      available = systemConfig.sops.secrets ? OPENAI_API_KEY;
      wrapper = wrappers.docsMcpWrapper;
      portKey = portKeys."docs-mcp-server";
      config = {
        command = "${wrappers.docsMcpWrapper}/bin/docs-mcp-wrapper";
        args = [ ];
        port = constants.ports.mcp.docs;
      };
    };

    openai = {
      enabled = true;
      available = systemConfig.sops.secrets ? OPENAI_API_KEY;
      wrapper = wrappers.openaiWrapper;
      portKey = portKeys.openai;
      config = {
        command = "${wrappers.openaiWrapper}/bin/openai-mcp-wrapper";
        args = [ ];
        port = constants.ports.mcp.openai;
      };
    };

    rustdocs = {
      enabled = true;
      available = systemConfig.sops.secrets ? OPENAI_API_KEY;
      wrapper = wrappers.rustdocsWrapper;
      portKey = portKeys.rustdocs;
      config = {
        command = "${wrappers.rustdocsWrapper}/bin/rustdocs-mcp-wrapper";
        args = [
          "bevy@0.16.1"
          "-F"
          "default"
        ];
        port = constants.ports.mcp.rustdocs;
      };
    };

    # Disabled servers - awaiting uv package availability
    kagi = {
      enabled = false;
      available = false;
      wrapper = wrappers.kagiWrapper;
      portKey = portKeys.kagi;
      config = { };
    };

    nixos = {
      enabled = false;
      available = false;
      wrapper = wrappers.nixosWrapper;
      portKey = portKeys.nixos;
      config = { };
    };
  };

  # Filter to only enabled and available servers
  activeServers = lib.filterAttrs (_name: server: server.enabled && server.available) servers;

  # Extract server configs for services.mcp
  serverConfigs = lib.mapAttrs (_name: server: server.config) activeServers;

  # Health check script for all active servers
  healthCheckScript = pkgs.writeShellApplication {
    name = "mcp-health-check";
    text = ''
      set -euo pipefail

      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "MCP Server Health Check (Darwin)"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo

      failed=0
      total=0

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: server: ''
          total=$((total + 1))
          echo "Checking ${name}..."
          if ${server.wrapper}/bin/${server.wrapper.name} --health-check >/dev/null 2>&1; then
            echo "  ✓ ${name}: healthy"
          else
            echo "  ✗ ${name}: unhealthy"
            failed=$((failed + 1))
          fi
          echo
        '') activeServers
      )}

      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "Results: $((total - failed))/$total servers healthy"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

      if [ $failed -gt 0 ]; then
        exit 1
      fi
    '';
  };

in
{
  home = {
    # Install wrapper packages
    packages = [
      pkgs.nodejs
    ]
    ++ (lib.mapAttrsToList (_name: server: server.wrapper) activeServers)
    ++ [ healthCheckScript ];

    # Health check script in user's path
    file."bin/mcp-health-check" = {
      source = healthCheckScript;
      executable = true;
    };
  };

  # Configure MCP servers via services.mcp
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

    # Active server configurations
    servers = serverConfigs;
  };

  # LaunchAgent for automatic health checks and monitoring
  # Runs health check 5 minutes after login and every 6 hours
  launchd.agents.mcp-health-check = {
    enable = true;
    config = {
      ProgramArguments = [ "${healthCheckScript}" ];
      StartInterval = 21600; # 6 hours in seconds
      RunAtLoad = false;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/mcp-health-check.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mcp-health-check.err.log";
    };
  };

  # Home activation hook to display MCP status
  home.activation.mcpStatus = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "MCP Server Configuration (Darwin)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "Active Servers:"
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: server: ''
        echo "  • ${name} (port ${toString constants.ports.mcp.${server.portKey}})"
      '') activeServers
    )}
    echo
    echo "Disabled Servers:"
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: _server: ''
        echo "  • ${name} (unavailable: awaiting dependencies)"
      '') (lib.filterAttrs (_name: server: !server.enabled || !server.available) servers)
    )}
    echo
    echo "Configuration Files:"
    echo "  • Cursor: ~/.cursor/mcp.json"
    echo "  • Claude Code: ~/Library/Application Support/Claude/claude_desktop_config.json"
    echo
    echo "Health Check:"
    echo "  Run: ~/bin/mcp-health-check"
    echo "  Logs: ~/Library/Logs/mcp-health-check.log"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
  '';
}
