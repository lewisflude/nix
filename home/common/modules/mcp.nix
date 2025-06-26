{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.mcp;

  mcpServerType = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
        description = "The command to run the MCP server";
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional arguments to pass to the MCP server";
      };

      port = mkOption {
        type = types.port;
        description = "Port for the MCP server";
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Environment variables to set for the MCP server";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional arguments to pass to the MCP server";
      };
    };
  };

  mkMcpConfig = name: serverCfg: {
    command = serverCfg.command;
    args = serverCfg.args;
    env = serverCfg.env;
  };

  mcpConfigJson = {
    mcpServers = mapAttrs mkMcpConfig cfg.servers;
  };

in
{
  options.services.mcp = {
    enable = mkEnableOption "MCP (Model Context Protocol) servers";

    servers = mkOption {
      type = types.attrsOf mcpServerType;
      default = { };
      description = "MCP servers to configure";
      example = {
        kagi = {
          command = "uvx";
          args = [ "kagimcp" ];
          port = 11431;
          env = {
            KAGI_API_KEY = "YOUR_API_KEY_HERE";
            KAGI_SUMMARIZER_ENGINE = "YOUR_ENGINE_CHOICE_HERE";
          };
        };
        fetch = {
          command = "uvx @modelcontextprotocol/server-fetch";
          args = [ "--stdio" ];
          port = 11432;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home.file =
      {
        ".mcp/gateway.json".text = builtins.toJSON mcpConfigJson;
        ".cursor/mcp.json".text = builtins.toJSON mcpConfigJson;
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        "Library/Application Support/Claude/claude_desktop_config.json".text =
          builtins.toJSON mcpConfigJson;
      };

  };
}
