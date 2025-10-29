{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.mcp;
  mcpServerType = types.submodule {
    options = {
      # CLI server options
      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The command to run the MCP server (for CLI servers)";
      };
      args = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional arguments to pass to the MCP server (for CLI servers)";
      };
      env = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables to set for the MCP server (for CLI servers)";
      };

      # Remote server options
      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The URL of the remote MCP server (for remote servers)";
      };
      headers = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "HTTP headers to send to the remote MCP server (for remote servers)";
      };

      # Optional metadata
      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = "Port for the MCP server (optional metadata, not used in config generation)";
      };
      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional arguments to pass to the MCP server (optional, not used in config generation)";
      };
    };
  };
  mcpTargetType = types.submodule {
    options = {
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
  mkMcpConfig = _name: serverCfg:
  # Remote server configuration (url-based)
    if serverCfg.url != null
    then
      {
        inherit (serverCfg) url;
      }
      // (optionalAttrs (serverCfg.headers != {}) {inherit (serverCfg) headers;})
    # CLI server configuration (command-based)
    else if serverCfg.command != null
    then
      {
        inherit (serverCfg) command;
      }
      // (optionalAttrs (serverCfg.args != []) {inherit (serverCfg) args;})
      // (optionalAttrs (serverCfg.env != {}) {inherit (serverCfg) env;})
    else throw "MCP server '${_name}' must specify either 'command' (for CLI server) or 'url' (for remote server)";
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
        # CLI server with npx
        kagi = {
          command = "uvx";
          args = ["kagimcp"];
          env = {
            KAGI_API_KEY = "YOUR_API_KEY_HERE";
            KAGI_SUMMARIZER_ENGINE = "YOUR_ENGINE_CHOICE_HERE";
          };
        };
        # CLI server with Python
        python-server = {
          command = "python";
          args = ["mcp-server.py"];
          env = {
            API_KEY = "value";
          };
        };
        # Remote server
        remote-server = {
          url = "http://localhost:3000/mcp";
          headers = {
            API_KEY = "value";
          };
        };
      };
    };
  };
  config = mkIf cfg.enable {
    # Write to a temporary location first (as symlink)
    home.file = builtins.listToAttrs (
      mapAttrsToList
      (name: target: {
        name = ".mcp-generated/${name}/${target.fileName}";
        value.text = builtins.toJSON mcpConfigJson;
      })
      cfg.targets
    );

    # Copy to final location (not symlinked) because cursor-agent can't read symlinks
    home.activation.copyMcpConfig = lib.hm.dag.entryAfter ["writeBoundary"] (
      let
        copyCommands = concatStringsSep "\n" (
          mapAttrsToList
          (name: target: ''
            mkdir -p "${target.directory}"
            cp -f "$HOME/.mcp-generated/${name}/${target.fileName}" "${target.directory}/${target.fileName}"
            chmod 644 "${target.directory}/${target.fileName}"
          '')
          cfg.targets
        );
      in ''
        ${copyCommands}
      ''
    );
  };
}
