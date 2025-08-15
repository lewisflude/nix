{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.mcp;

  mcpServerType = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
        description = "The command to run the MCP server";
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional arguments to pass to the MCP server";
      };

      port = mkOption {
        type = types.port;
        description = "Port for the MCP server";
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables to set for the MCP server";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional arguments to pass to the MCP server";
      };
    };
  };

  mcpTargetType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "The name of the MCP target";
      };
      directory = mkOption {
        type = types.path;
        description = "The directory to store the MCP target";
      };
      fileName = mkOption {
        type = types.str;
        description = "The file name to store the MCP target";
      };
    };
  };

  mkMcpConfig = _name: serverCfg: {
    inherit (serverCfg) command;
    inherit (serverCfg) args;
    inherit (serverCfg) env;
  };

  mcpConfigJson = {
    mcpServers = mapAttrs mkMcpConfig cfg.servers;
  };
in {
  options.services.mcp = {
    enable = mkEnableOption "MCP (Model Context Protocol) servers";

    targets = mkOption {
      type = types.attrsOf mcpTargetType;
      default = {};
      description = "MCP targets to configure";
      example = {
        "cursor" = {
          directory = "/Users/${config.home.username}/.cursor";
          fileName = "mcp.json";
        };
        "claude" = {
          directory = "/Users/${config.home.username}/Library/Application Support/Claude";
          fileName = "claude_desktop_config.json";
        };
      };
    };

    servers = mkOption {
      type = types.attrsOf mcpServerType;
      default = {};
      description = "MCP servers to configure";
      example = {
        kagi = {
          command = "uvx";
          args = ["kagimcp"];
          port = 11431;
          env = {
            KAGI_API_KEY = "YOUR_API_KEY_HERE";
            KAGI_SUMMARIZER_ENGINE = "YOUR_ENGINE_CHOICE_HERE";
          };
        };
        fetch = {
          command = "uvx @modelcontextprotocol/server-fetch";
          args = ["--stdio"];
          port = 11432;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home.file = builtins.listToAttrs (
        map (target: {
          name = "${target.directory}/${target.fileName}";
          value.text = builtins.toJSON mcpConfigJson;
        }) (attrValues cfg.targets)
      );
  };
}
