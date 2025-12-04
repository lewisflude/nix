# MCP Configuration for NixOS (Linux)
#
# This module configures Model Context Protocol (MCP) servers for NixOS hosts.
# It uses the shared wrappers module and provides platform-specific integration
# via systemd services for persistent server management.
#
# Architecture:
# - Shared wrappers from modules/shared/mcp/wrappers.nix
# - Configuration via services.mcp (home/common/modules/mcp.nix)
# - Systemd user services for automatic server registration
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
# - Claude Code: ~/.config/claude/claude_desktop_config.json
#
# Systemd Services:
# - mcp-health-check.timer: Periodic health checks (every 6 hours)
# - mcp-health-check.service: Health check execution
{
  pkgs,
  config,
  lib,
  constants,
  systemConfig,
  ...
}:

let
  inherit (pkgs.stdenv) isLinux;

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
      echo "MCP Server Health Check (NixOS)"
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
      pkgs.coreutils
      pkgs.gawk
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
      claude-code = {
        directory = "${config.home.homeDirectory}/.config/claude";
        fileName = "claude_desktop_config.json";
      };
    };

    # Active server configurations
    servers = serverConfigs;
  };

  # Systemd services for Linux
  systemd.user.services = lib.mkIf isLinux {
    # Health check service
    mcp-health-check = {
      Unit = {
        Description = "MCP Server Health Check";
        Documentation = [ "https://github.com/modelcontextprotocol" ];
        After = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${healthCheckScript}";
        Environment = [
          "PATH=/etc/profiles/per-user/%u/bin:%h/.nix-profile/bin:/run/current-system/sw/bin"
        ];
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    # Documentation MCP Server HTTP interface
    # Runs docs-mcp-server in HTTP mode for remote access
    docs-mcp-http = lib.mkIf (activeServers ? docs-mcp-server) {
      Unit = {
        Description = "Docs MCP Server HTTP Interface";
        Documentation = [ "https://github.com/arabold/docs-mcp-server" ];
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        ExecStart = "${wrappers.docsMcpWrapper}/bin/docs-mcp-wrapper --protocol http --host 0.0.0.0 --port ${toString constants.ports.mcp.docs}";
        Restart = "on-failure";
        RestartSec = "${constants.timeouts.service.restart}";
        Environment = [
          "PATH=/etc/profiles/per-user/%u/bin:%h/.nix-profile/bin:/run/current-system/sw/bin"
        ];
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };

  # Systemd timers for periodic health checks
  systemd.user.timers = lib.mkIf isLinux {
    mcp-health-check = {
      Unit = {
        Description = "MCP Server Health Check Timer";
        Documentation = [ "https://github.com/modelcontextprotocol" ];
      };
      Timer = {
        OnBootSec = "5min"; # 5 minutes after boot
        OnUnitActiveSec = "6h"; # Every 6 hours
        Persistent = true; # Run missed timers on boot
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };

  # Home activation hook to display MCP status and verify secrets
  home.activation.mcpStatus = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "MCP Server Configuration (NixOS)"
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
    # Verify secrets exist for servers that require them
    ${lib.optionalString
      (activeServers ? "docs-mcp-server" || activeServers ? openai || activeServers ? rustdocs)
      ''
        secretPath="${osConfig.sops.secrets.OPENAI_API_KEY.path or "/run/secrets/OPENAI_API_KEY"}"
        if [ ! -r "$secretPath" ]; then
          echo "  ⚠ WARNING: OPENAI_API_KEY secret not found at $secretPath"
          echo "    Servers requiring this key (docs-mcp-server, openai, rustdocs) will fail to start."
          echo "    To fix: Run 'sudo nixos-rebuild switch' to deploy SOPS secrets."
          echo
        fi
      ''
    }
    echo "Configuration Files:"
    echo "  • Cursor: ~/.cursor/mcp.json"
    echo "  • Claude Code: ~/.config/claude/claude_desktop_config.json"
    echo
    echo "Health Check:"
    echo "  Run: ~/bin/mcp-health-check"
    echo "  Systemd: systemctl --user status mcp-health-check.timer"
    echo "  Logs: journalctl --user -u mcp-health-check.service"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
  '';
}
