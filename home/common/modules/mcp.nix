# MCP Home-Manager Module - Common Configuration Generator
#
# This module provides the shared home-manager implementation for MCP configuration
# across both NixOS and nix-darwin. It generates JSON configuration files and
# manages file deployment through home-manager activation hooks.
#
# Architecture:
# - Reads server configuration from services.mcp.servers
# - Generates JSON files in ~/.mcp-generated/<target>/
# - Copies generated configs to target application directories
#
# Configuration Format:
#   {
#     "mcpServers": {
#       "server-name": {
#         "command": "/path/to/command",
#         "args": ["arg1", "arg2"],
#         "env": { "VAR": "value" }
#       }
#     }
#   }
#
# Supports:
# - CLI servers (stdio protocol with command/args)
# - Remote servers (HTTP protocol with url/headers)
#
# See also:
# - modules/shared/mcp/servers.nix: Common server definitions (library)
# - modules/shared/mcp/wrappers.nix: Secret-aware wrappers (library)
# - home/nixos/mcp.nix: NixOS-specific configuration
# - home/darwin/mcp.nix: Darwin-specific configuration
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    optionalAttrs
    mapAttrs
    mapAttrsToList
    concatStringsSep
    filterAttrs
    length
    unique
    filter
    foldl'
    attrNames
    ;

  cfg = config.services.mcp;

  # Submodule type for MCP server configuration
  # Supports both CLI servers (command-based) and remote servers (URL-based)
  mcpServerType = types.submodule {
    options = {
      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc ''
          The command to run the MCP server (for CLI servers).

          This should be an absolute path to ensure reproducibility.
          Mutually exclusive with `url`.
        '';
        example = ''"''${pkgs.uv}/bin/uvx"'';
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = lib.mdDoc ''
          Additional arguments to pass to the MCP server (for CLI servers).

          These are passed to the command in order.
        '';
        example = [
          "--from"
          "mcp-server-fetch"
          "mcp-server-fetch"
        ];
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = lib.mdDoc ''
          Environment variables to set for the MCP server (for CLI servers).

          Variables are exported before the server command is executed.
          Secrets should be handled via SOPS and wrapper scripts.
        '';
        example = {
          UV_PYTHON = "/nix/store/.../bin/python3";
        };
      };

      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc ''
          The URL of the remote MCP server (for remote servers).

          Example: `http://localhost:3000/mcp`
          Mutually exclusive with `command`.
        '';
        example = "http://localhost:3000/mcp";
      };

      headers = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = lib.mdDoc ''
          HTTP headers to send to the remote MCP server (for remote servers).

          Example: `{ Authorization = "Bearer token"; }`
        '';
        example = {
          Authorization = "Bearer token";
        };
      };

      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = lib.mdDoc ''
          Port for the MCP server (optional metadata).

          This is used for documentation and port conflict detection,
          but is not included in the generated configuration files.

          MCP servers should use ports in the range 6200-6299.
          See `lib/constants.nix` for port allocation.
        '';
        example = 6280;
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = lib.mdDoc ''
          Additional arguments (optional, not used in config generation).

          Reserved for future use.
        '';
      };
    };
  };

  # Submodule type for MCP target applications
  mcpTargetType = types.submodule {
    options = {
      directory = mkOption {
        type = types.str; # Using str to support interpolation with config.home.homeDirectory
        description = lib.mdDoc ''
          The directory to store the MCP configuration.

          This directory will be created if it doesn't exist.
          Typically application config directories like:
          - `~/.cursor` for Cursor editor
          - `~/.config/claude` for Claude Code
        '';
        example = "/home/user/.cursor";
      };

      fileName = mkOption {
        type = types.str;
        default = "mcp.json";
        description = lib.mdDoc ''
          The file name to store the MCP configuration.

          Different applications expect different filenames:
          - Cursor: `mcp.json`
          - Claude Code: `claude_desktop_config.json`
        '';
        example = "mcp.json";
      };
    };
  };

  # Generate MCP configuration JSON for a server
  # Handles both CLI servers (command-based) and remote servers (URL-based)
  mkMcpConfig =
    _name: serverCfg:
    # Remote server configuration
    if serverCfg.url != null then
      {
        inherit (serverCfg) url;
      }
      // (optionalAttrs (serverCfg.headers != { }) { inherit (serverCfg) headers; })

    # CLI server configuration
    else if serverCfg.command != null then
      {
        inherit (serverCfg) command;
      }
      // (optionalAttrs (serverCfg.args != [ ]) { inherit (serverCfg) args; })
      // (optionalAttrs (serverCfg.env != { }) { inherit (serverCfg) env; })

    # Invalid configuration
    else
      throw "MCP server '${_name}' must specify either 'command' (for CLI server) or 'url' (for remote server)";

  # Generate the complete MCP configuration JSON structure
  mcpConfigJson = {
    mcpServers = mapAttrs mkMcpConfig cfg.servers;
  };

  # Validation helpers

  # Helper to detect port conflicts
  findPortConflicts =
    let
      portList = mapAttrsToList (_name: server: server.port) (
        filterAttrs (_name: server: server.port != null) cfg.servers
      );
      uniquePorts = unique portList;
    in
    length portList != length uniquePorts;

  # Helper to collect conflicting ports
  getConflictingPorts =
    let
      portToServers = foldl' (
        acc: name:
        let
          inherit (cfg.servers.${name}) port;
        in
        if port == null then
          acc
        else
          acc // { ${toString port} = (acc.${toString port} or [ ]) ++ [ name ]; }
      ) { } (attrNames (filterAttrs (_name: server: server.port != null) cfg.servers));
      conflicts = filterAttrs (_port: servers: length servers > 1) portToServers;
    in
    mapAttrsToList (port: servers: "Port ${port}: ${concatStringsSep ", " servers}") conflicts;

  # MCP port range from constants
  mcpPortMin = 6200;
  mcpPortMax = 6299;

  # Validate MCP port range
  mcpPortInRange = port: port >= mcpPortMin && port <= mcpPortMax;

  # Helper to find servers with out-of-range ports
  getOutOfRangePorts =
    let
      serversWithPorts = filterAttrs (_name: server: server.port != null) cfg.servers;
    in
    filter (name: !mcpPortInRange cfg.servers.${name}.port) (attrNames serversWithPorts);

in
{
  options.services.mcp = {
    enable = mkEnableOption (
      lib.mdDoc ''
        MCP (Model Context Protocol) server configuration.

        When enabled, this module generates MCP configuration files for target
        applications and optionally registers servers with the Claude CLI.

        Provides cross-platform support for NixOS and nix-darwin.
      ''
    );

    targets = mkOption {
      type = types.attrsOf mcpTargetType;
      default = { };
      description = lib.mdDoc ''
        MCP targets to configure.

        Each target represents an application that should receive the
        MCP configuration. The same server configuration is deployed
        to all targets.
      '';
      example = lib.literalExpression ''
        {
          "cursor" = {
            directory = "''${config.home.homeDirectory}/.cursor";
            fileName = "mcp.json";
          };
          "claude-code" = {
            directory = "''${config.home.homeDirectory}/.config/claude";
            fileName = "claude_desktop_config.json";
          };
        }
      '';
    };

    servers = mkOption {
      type = types.attrsOf mcpServerType;
      default = { };
      description = lib.mdDoc ''
        MCP servers to configure.

        Each server can be either a CLI server (with command/args/env)
        or a remote server (with url/headers).

        Common servers are available in `modules/shared/mcp/servers.nix`.
        Secret-aware wrappers are available in `modules/shared/mcp/wrappers.nix`.
      '';
      example = lib.literalExpression ''
        {
          # CLI server example
          fetch = {
            command = "''${pkgs.uv}/bin/uvx";
            args = [ "--from" "mcp-server-fetch" "mcp-server-fetch" ];
            port = 6260;
            env = {
              UV_PYTHON = "''${pkgs.python3}/bin/python3";
            };
          };

          # Remote server example
          remote-server = {
            url = "http://localhost:3000/mcp";
            headers = {
              Authorization = "Bearer token";
            };
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Validate configuration
    assertions = [
      # Validate no port conflicts exist
      {
        assertion = !findPortConflicts;
        message = ''
          MCP server port conflicts detected:
          ${concatStringsSep "\n  " getConflictingPorts}

          Each MCP server must use a unique port number.
          See lib/constants.nix for the MCP port allocation (6200-6299).
        '';
      }

      # Validate all ports are in the MCP range
      {
        assertion = getOutOfRangePorts == [ ];
        message = ''
          MCP servers with ports outside the reserved range (${toString mcpPortMin}-${toString mcpPortMax}):
          ${concatStringsSep ", " getOutOfRangePorts}

          MCP server ports must be in the range ${toString mcpPortMin}-${toString mcpPortMax}.
          See lib/constants.nix for port allocation.
        '';
      }

      # Validate at least one target is configured
      {
        assertion = cfg.targets != { };
        message = ''
          MCP is enabled but no targets are configured.

          You must configure at least one target application (e.g., cursor, claude-code).
          Example:
            services.mcp.targets.cursor = {
              directory = "''${config.home.homeDirectory}/.cursor";
              fileName = "mcp.json";
            };
        '';
      }
    ];

    # Generate MCP configuration files in ~/.mcp-generated/
    home.file = builtins.listToAttrs (
      mapAttrsToList (name: target: {
        name = ".mcp-generated/${name}/${target.fileName}";
        value.text = builtins.toJSON mcpConfigJson;
      }) cfg.targets
    );

    # Copy generated configs to target directories on activation
    home.activation.copyMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      let
        # Generate copy commands for each target
        copyCommands = concatStringsSep "\n" (
          mapAttrsToList (name: target: ''
            mkdir -p "${target.directory}"
            cp -f "$HOME/.mcp-generated/${name}/${target.fileName}" "${target.directory}/${target.fileName}"
            chmod 644 "${target.directory}/${target.fileName}"
          '') cfg.targets
        );
      in
      ''
        ${copyCommands}
      ''
    );
  };
}
