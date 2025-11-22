# MCP Configuration for NixOS (mcps.nix flake integration)
#
# This module uses roman/mcps.nix for version-pinned MCP servers.
# Servers provided by mcps.nix: git, github, filesystem, fetch, sequential-thinking, time, LSPs
# Custom servers: memory, nixos, kagi, openai, docs-mcp-server, rust-docs-bevy
{
  pkgs,
  config,
  systemConfig,
  lib,
  inputs,
  constants,
  ...
}:

let
  inherit (pkgs.stdenv) isLinux;

  # Import custom wrappers for servers not in mcps.nix
  wrappers = import ../../modules/shared/mcp/wrappers.nix {
    inherit pkgs systemConfig lib;
  };

  inherit (lib) concatStringsSep mapAttrsToList escapeShellArg;

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
      command = "${wrappers.kagiWrapper}/bin/kagi-mcp-wrapper";
      args = [ ];
      port = constants.ports.mcp.kagi;
    };

    # OpenAI MCP server with SOPS integration
    openai = {
      command = "${wrappers.openaiWrapper}/bin/openai-mcp-wrapper";
      args = [ ];
      port = constants.ports.mcp.openai;
    };

    # Docs MCP server with SOPS integration
    docs-mcp-server = {
      command = "${wrappers.docsMcpWrapper}/bin/docs-mcp-wrapper";
      args = [ ];
      port = constants.ports.mcp.docs;
    };

    # Rust documentation MCP server
    rust-docs-bevy = {
      command = "${wrappers.rustdocsWrapper}/bin/rustdocs-mcp-wrapper";
      args = [
        "bevy@0.16.1"
        "-F"
        "default"
      ];
      port = constants.ports.mcp.rustdocs;
    };
  };

  # Registration script for custom servers
  mkAddJsonCmd =
    name: serverCfg:
    let
      json = builtins.toJSON (
        {
          type = "stdio";
          args = serverCfg.args or [ ];
          env = serverCfg.env or { };
        }
        // {
          inherit (serverCfg) command;
        }
      );
      jsonArg = escapeShellArg json;
    in
    ''
      claude mcp remove ${escapeShellArg name} --scope user >/dev/null 2>&1 || true
      claude mcp add-json ${escapeShellArg name} ${jsonArg} --scope user
    '';

  declaredNames = mapAttrsToList (n: _: escapeShellArg n) customServers;
  addCommands = concatStringsSep "\n" (mapAttrsToList mkAddJsonCmd customServers);

  registerCustomScript = pkgs.writeShellScript "mcp-register-custom" ''
        set -uo pipefail
        echo "[mcp] Registering custom MCP servers (not in mcps.nix)…"
        export PATH="${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gawk}/bin:${pkgs.jq}/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:$PATH"
        export MCP_TIMEOUT="''${MCP_TIMEOUT:-${constants.timeouts.mcp.registration}}"

        if ! command -v claude >/dev/null 2>&1; then
          echo "[mcp] WARNING: 'claude' CLI not found in PATH, skipping custom server registration"
          exit 0
        fi

        echo "[mcp] Custom servers: ${concatStringsSep " " declaredNames}"

        while IFS= read -r line; do
          line="''${line%%$'\r'}"
          [ -z "$line" ] && continue
          echo "[mcp] -> $line"
          bash -lc "$line" >/dev/null 2>&1 || echo "[mcp] WARN: add failed for custom server"
        done <<'ADD_CMDS'
    ${addCommands}
    ADD_CMDS

        echo "[mcp] Custom server registration complete."
  '';

in
{
  # Import mcps.nix home-manager module
  imports = [ inputs.mcps.homeManagerModules.claude ];

  home = {
    packages = [
      pkgs.uv
      pkgs.nodejs
      pkgs.coreutils
      pkgs.gawk
      wrappers.kagiWrapper
      wrappers.openaiWrapper
      wrappers.docsMcpWrapper
      pkgs.lua-language-server
      pkgs.nodePackages.typescript-language-server
      pkgs.nodePackages.typescript
    ];

    # Register custom servers after mcps.nix servers
    activation.setupCustomMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${registerCustomScript}
    '';
  };

  # Configure mcps.nix servers
  # NOTE: Servers requiring pkgs.mcp-servers are disabled due to overlay issues
  # The mcps overlay is not properly providing pkgs.mcp-servers package
  # Servers that require it: filesystem, git, github, fetch, sequential-thinking, time, LSPs
  programs.claude-code = {
    enable = true;

    mcps = {
      # Disabled: require pkgs.mcp-servers which is not provided by overlay
      git.enable = false;
      filesystem.enable = false;
      github.enable = false;
      fetch.enable = false;
      sequential-thinking.enable = false;
      time.enable = false;
      lsp-typescript.enable = false;
      lsp-nix.enable = false;
      lsp-rust.enable = false;
      lsp-python.enable = false;
    };
  };

  # Legacy services.mcp configuration for Cursor compatibility
  services.mcp = {
    enable = true;

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

    # Add custom servers to legacy config
    servers = customServers;
  };

  # Systemd services for Linux
  systemd.user.services = lib.mkIf isLinux {
    mcp-claude-register-custom = {
      Unit = {
        Description = "Register custom MCP servers for Claude CLI";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${registerCustomScript}";
        Environment = [
          "PATH=/etc/profiles/per-user/%u/bin:%h/.nix-profile/bin:$PATH"
        ];
        TimeoutStartSec = "${constants.timeouts.service.start}";
        Restart = "on-failure";
        RestartSec = "${constants.timeouts.service.restart}";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    docs-mcp-http = {
      Unit = {
        Description = "Docs MCP Server HTTP Interface";
        After = [ "network-online.target" ];
      };
      Service = {
        ExecStart = "${wrappers.docsMcpWrapper}/bin/docs-mcp-wrapper --protocol http --host 0.0.0.0 --port ${toString constants.ports.mcp.docs}";
        Restart = "on-failure";
        Environment = [
          "PATH=/etc/profiles/per-user/%u/bin:%h/.nix-profile/bin:$PATH"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
