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
# - modules/shared/mcp/service.nix: Service option definitions
# - home/nixos/mcp.nix: NixOS-specific implementation
# - home/darwin/mcp.nix: Darwin-specific implementation
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
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [];
        description = lib.mdDoc ''
          Additional arguments to pass to the MCP server (for CLI servers).

          These are passed to the command in order.
        '';
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = lib.mdDoc ''
          Environment variables to set for the MCP server (for CLI servers).

          Variables are exported before the server command is executed.
        '';
      };

      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc ''
          The URL of the remote MCP server (for remote servers).

          Example: `http://localhost:3000/mcp`
          Mutually exclusive with `command`.
        '';
      };

      headers = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = lib.mdDoc ''
          HTTP headers to send to the remote MCP server (for remote servers).

          Example: `{ Authorization = "Bearer token"; }`
        '';
      };

      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = lib.mdDoc ''
          Port for the MCP server (optional metadata).

          This is used for documentation and port conflict detection,
          but is not included in the generated configuration files.
        '';
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [];
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
        type = types.path;
        description = lib.mdDoc ''
          The directory to store the MCP configuration.

          This directory will be created if it doesn't exist.
        '';
      };

      fileName = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          The file name to store the MCP configuration.

          Different applications expect different filenames:
          - Cursor: `mcp.json`
          - Claude Code: `claude_desktop_config.json`
        '';
      };
    };
  };

  # Generate MCP configuration JSON for a server
  # Handles both CLI servers (command-based) and remote servers (URL-based)
  mkMcpConfig = _name: serverCfg:
    # Remote server configuration
    if serverCfg.url != null then
      { inherit (serverCfg) url; }
      // (optionalAttrs (serverCfg.headers != {}) { inherit (serverCfg) headers; })

    # CLI server configuration
    else if serverCfg.command != null then
      { inherit (serverCfg) command; }
      // (optionalAttrs (serverCfg.args != []) { inherit (serverCfg) args; })
      // (optionalAttrs (serverCfg.env != {}) { inherit (serverCfg) env; })

    # Invalid configuration
    else
      throw "MCP server '${_name}' must specify either 'command' (for CLI server) or 'url' (for remote server)";

  # Generate the complete MCP configuration JSON structure
  mcpConfigJson = {
    mcpServers = mapAttrs mkMcpConfig cfg.servers;
  };

in
{
  options.services.mcp = {
    enable = mkEnableOption (lib.mdDoc "MCP (Model Context Protocol) servers");

    targets = mkOption {
      type = types.attrsOf mcpTargetType;
      default = {};
      description = lib.mdDoc ''
        MCP targets to configure.

        Each target represents an application that should receive the
        MCP configuration. The same server configuration is deployed
        to all targets.
      '';
      example = lib.literalExpression ''
        {
          "cursor" = {
            directory = "/Users/''${config.home.username}/.cursor";
            fileName = "mcp.json";
          };
          "claude" = {
            directory = "/Users/''${config.home.username}/Library/Application Support/Claude";
            fileName = "claude_desktop_config.json";
          };
        }
      '';
    };

    servers = mkOption {
      type = types.attrsOf mcpServerType;
      default = {};
      description = lib.mdDoc ''
        MCP servers to configure.

        Each server can be either a CLI server (with command/args/env)
        or a remote server (with url/headers).
      '';
      example = lib.literalExpression ''
        {
          # CLI server example
          kagi = {
            command = "uvx";
            args = [ "kagimcp" ];
            env = {
              KAGI_API_KEY = "YOUR_API_KEY_HERE";
              KAGI_SUMMARIZER_ENGINE = "YOUR_ENGINE_CHOICE_HERE";
            };
          };

          # Remote server example
          python-server = {
            command = "python";
            args = [ "mcp-server.py" ];
            env = {
              API_KEY = "value";
            };
          };

          # HTTP server example
          remote-server = {
            url = "http://localhost:3000/mcp";
            headers = {
              API_KEY = "value";
            };
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
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
