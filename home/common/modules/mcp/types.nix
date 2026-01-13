# MCP Server Type Definitions
{
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  # Server type definition
  serverType = types.submodule {
    options = {
      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Command to run the MCP server";
        example = ''"''${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-memory"'';
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Arguments to pass to the command";
        example = [
          "bevy@0.16.1"
          "-F"
          "default"
        ];
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Environment variables to set";
        example = {
          UV_PYTHON = "/nix/store/.../bin/python3";
        };
      };

      secret = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Name of SOPS secret to inject (e.g., OPENAI_API_KEY)";
        example = "OPENAI_API_KEY";
      };

      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable this server";
      };
    };
  };
}
