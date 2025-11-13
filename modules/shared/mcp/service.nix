{ lib, ... }:

{
  options.services.mcp = {
    enable = lib.mkEnableOption "MCP server configuration";

    targets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          directory = lib.mkOption {
            type = lib.types.str;
            description = "Directory where MCP configuration should be written";
          };
          fileName = lib.mkOption {
            type = lib.types.str;
            description = "Name of the MCP configuration file";
          };
        };
      });
      default = {};
      description = "Target applications to configure MCP for";
    };

    servers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          command = lib.mkOption {
            type = lib.types.str;
            description = "Command to run the MCP server";
          };
          args = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Arguments to pass to the command";
          };
          port = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            description = "Port for the MCP server";
          };
          env = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = {};
            description = "Environment variables for the MCP server";
          };
        };
      });
      default = {};
      description = "MCP server configurations";
    };

    commonServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Common server configurations to merge";
      internal = true;
    };
  };
}
