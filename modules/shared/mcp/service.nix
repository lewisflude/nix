# MCP Service Options Definition
#
# This module defines the schema for MCP server configuration options.
# It provides type-safe configuration for both CLI-based and HTTP-based MCP servers,
# along with target application specifications.
#
# Architecture:
# - servers: Attribute set of MCP server configurations
# - targets: Attribute set of target applications (Cursor, Claude, etc.)
# - commonServers: Internal merge mechanism for shared server definitions
#
# Type Safety:
# - Uses proper Nix types (types.port, types.path) for validation
# - Supports both stdio and HTTP protocol servers
# - Environment variable configuration for servers
#
# Example:
#   services.mcp = {
#     enable = true;
#     servers.myserver = {
#       command = "${pkgs.python3}/bin/python";
#       args = [ "-m" "mcp_server" ];
#       env = { API_KEY = "secret"; };
#       port = 6280;
#     };
#     targets.cursor = {
#       directory = "${config.home.homeDirectory}/.cursor";
#       fileName = "mcp.json";
#     };
#   };
{ lib, config, ... }:

let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    mkIf
    optional
    ;

  cfg = config.services.mcp;

  # Import validators for consistent validation
  validators = import ../../../lib/validators.nix { inherit lib; };
  constants = import ../../../lib/constants.nix;

  # Submodule type for MCP server configuration
  mcpServerType = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The command to execute for this MCP server.

          Should be an absolute path to ensure reproducibility.
          For Python servers, use `"''${pkgs.python3}/bin/python"`.
          For Node.js servers, use `"''${pkgs.nodejs}/bin/npx"`.
        '';
        example = ''"''${pkgs.python3}/bin/python"'';
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [];
        description = lib.mdDoc ''
          Arguments to pass to the MCP server command.

          These are passed directly to the command in order.
          Use absolute paths for any file arguments.
        '';
        example = [ "-m" "mcp_server" "--config" "/path/to/config.json" ];
      };

      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = lib.mdDoc ''
          Port number for the MCP server (metadata only).

          This is used for documentation and port conflict detection,
          but is not included in the generated configuration files.
          See `lib/constants.nix` for port allocation ranges.

          Port range: 6200-6299 reserved for MCP servers.
        '';
        example = 6280;
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = lib.mdDoc ''
          Environment variables to set for the MCP server.

          These are passed to the server process at startup.
          Secrets should be handled through SOPS or wrapper scripts,
          not directly in this configuration.
        '';
        example = {
          UV_PYTHON = "/nix/store/.../bin/python3";
          LOG_LEVEL = "info";
        };
      };
    };
  };

  # Submodule type for MCP target applications
  mcpTargetType = types.submodule {
    options = {
      directory = mkOption {
        type = types.str;  # Note: Using str instead of path to support config.home.homeDirectory interpolation
        description = lib.mdDoc ''
          Directory where the MCP configuration file should be written.

          This directory will be created if it doesn't exist.
          Typically points to application configuration directories like:
          - `~/.cursor` for Cursor editor
          - `~/.config/claude` for Claude Code
        '';
        example = "/home/user/.cursor";
      };

      fileName = mkOption {
        type = types.str;
        default = "mcp.json";
        description = lib.mdDoc ''
          Name of the MCP configuration file to generate.

          Different applications may expect different filenames:
          - Cursor: `mcp.json`
          - Claude Code: `claude_desktop_config.json`
        '';
        example = "mcp.json";
      };
    };
  };

  # Helper to detect port conflicts
  findPortConflicts =
    let
      serversWithPorts = lib.filterAttrs (_name: server: server.port != null) cfg.servers;
      portList = lib.mapAttrsToList (_name: server: server.port) serversWithPorts;
      uniquePorts = lib.unique portList;
    in
      lib.length portList != lib.length uniquePorts;

  # Helper to collect conflicting ports
  getConflictingPorts =
    let
      serversWithPorts = lib.filterAttrs (_name: server: server.port != null) cfg.servers;
      portToServers = lib.foldl'
        (acc: name:
          let
            port = cfg.servers.${name}.port;
          in
            if port == null then acc
            else acc // { ${toString port} = (acc.${toString port} or []) ++ [ name ]; }
        )
        {}
        (lib.attrNames cfg.servers);
      conflicts = lib.filterAttrs (_port: servers: lib.length servers > 1) portToServers;
    in
      lib.mapAttrsToList
        (port: servers: "Port ${port}: ${lib.concatStringsSep ", " servers}")
        conflicts;

  # Validate MCP port range (6200-6299)
  mcpPortInRange = port: port >= 6200 && port <= 6299;

  # Helper to find servers with out-of-range ports
  getOutOfRangePorts =
    let
      serversWithPorts = lib.filterAttrs (_name: server: server.port != null) cfg.servers;
    in
      lib.filter
        (name: !mcpPortInRange cfg.servers.${name}.port)
        (lib.attrNames serversWithPorts);

in
{
  options.services.mcp = {
    enable = mkEnableOption (lib.mdDoc ''
      MCP (Model Context Protocol) server configuration.

      When enabled, this module generates MCP configuration files for target
      applications and optionally registers servers with the Claude CLI.

      Provides cross-platform support for NixOS and nix-darwin.
    '');

    targets = mkOption {
      type = types.attrsOf mcpTargetType;
      default = {};
      description = lib.mdDoc ''
        Target applications to configure with MCP servers.

        Each target specifies a directory and filename where the MCP
        configuration should be written. The same server configuration
        is used across all targets.
      '';
      example = lib.literalExpression ''
        {
          cursor = {
            directory = "''${config.home.homeDirectory}/.cursor";
            fileName = "mcp.json";
          };
          claude-code = {
            directory = "''${config.home.homeDirectory}/.config/claude";
            fileName = "claude_desktop_config.json";
          };
        }
      '';
    };

    servers = mkOption {
      type = types.attrsOf mcpServerType;
      default = {};
      description = lib.mdDoc ''
        MCP server configurations.

        Each server is defined by a command, arguments, optional environment
        variables, and an optional port number. Servers are automatically
        formatted into the appropriate JSON structure for target applications.

        Common servers are provided in `modules/shared/mcp/servers.nix`.
        Secret-aware wrappers are provided in `modules/shared/mcp/wrappers.nix`.
      '';
      example = lib.literalExpression ''
        {
          fetch = {
            command = "''${pkgs.uv}/bin/uvx";
            args = [ "--from" "mcp-server-fetch" "mcp-server-fetch" ];
            port = 6260;
            env = {
              UV_PYTHON = "''${pkgs.python3}/bin/python3";
            };
          };

          memory = {
            command = "''${pkgs.nodejs}/bin/npx";
            args = [ "-y" "@modelcontextprotocol/server-memory@latest" ];
            port = 6221;
          };
        }
      '';
    };

    commonServers = mkOption {
      type = types.attrsOf mcpServerType;
      default = {};
      description = lib.mdDoc ''
        Common server configurations to merge into the servers option.

        This is an internal option used by the module system to inject
        shared server definitions from `modules/shared/mcp/servers.nix`.
        Users should not set this directly.
      '';
      internal = true;
    };
  };

  # Configuration validation
  config = mkIf cfg.enable {
    assertions = [
      # Validate no port conflicts exist
      {
        assertion = !findPortConflicts;
        message = ''
          MCP server port conflicts detected:
          ${lib.concatStringsSep "\n  " (getConflictingPorts)}

          Each MCP server must use a unique port number.
          See lib/constants.nix for the MCP port allocation (6200-6299).
        '';
      }

      # Validate all ports are in the MCP range
      {
        assertion = getOutOfRangePorts == [];
        message = ''
          MCP servers with ports outside the reserved range (6200-6299):
          ${lib.concatStringsSep ", " getOutOfRangePorts}

          MCP server ports must be in the range 6200-6299.
          See lib/constants.nix for port allocation.
        '';
      }

      # Validate at least one target is configured
      {
        assertion = cfg.targets != {};
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
  };
}
