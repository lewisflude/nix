{ pkgs, config, systemConfig, lib, system, ... }:

let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
  claudeConfigDir = platformLib.dataDir config.home.username + "/Claude";

  # Import shared MCP utilities
  servers = import ../../modules/shared/mcp/servers.nix { inherit pkgs config systemConfig lib platformLib; };
  wrappers = import ../../modules/shared/mcp/wrappers.nix { inherit pkgs systemConfig lib platformLib; };

  # Darwin-specific wrapper for kagi (using home.file instead of writeShellApplication)
  kagiWrapperScript = ''
    if [ -r "${systemConfig.sops.secrets.KAGI_API_KEY.path or ""}" ]; then
      export KAGI_API_KEY="$(${pkgs.coreutils}/bin/cat "${systemConfig.sops.secrets.KAGI_API_KEY.path or ""}")"
    fi
    exec ${pkgs.uv}/bin/uvx kagimcp "$@"
  '';

  docsWrapperScript = ''
    if [ -r "${systemConfig.sops.secrets.OPENAI_API_KEY.path or ""}" ]; then
      export OPENAI_API_KEY="$(${pkgs.coreutils}/bin/cat "${systemConfig.sops.secrets.OPENAI_API_KEY.path or ""}")"
    fi
    exec ${servers.nodejs}/bin/npx -y @arabold/docs-mcp-server@latest "$@"
  '';

in {
  home = {
    packages = [ pkgs.uv ];

    file = {
      "bin/kagi-mcp-wrapper" = {
        text = kagiWrapperScript;
        executable = true;
      };
      "bin/docs-mcp-wrapper" = {
        text = docsWrapperScript;
        executable = true;
      };
    };

    activation.setupClaudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      let
        cfg = config.services.mcp;
        mcpAddCommands = lib.concatStringsSep "\n        " (
          lib.mapAttrsToList (
            name: serverCfg:
            let
              command = lib.escapeShellArg serverCfg.command;
              argsStr = lib.concatStringsSep " " (map lib.escapeShellArg serverCfg.args);
              argsPart = lib.optionalString (argsStr != "") "-- ${argsStr}";
              envVars = lib.concatStringsSep " " (
                lib.mapAttrsToList (
                  key: value: "export ${lib.escapeShellArg key}=${lib.escapeShellArg value};"
                ) serverCfg.env
              );
            in
            ''${envVars} claude mcp add ${lib.escapeShellArg name} -s user ${command} ${argsPart} || echo "Failed to add ${name} server"''
          ) cfg.servers
        );
      in
      ''
        if command -v claude >/dev/null 2>&1; then
          echo "Registering MCP servers with Claude Code..."
          ${pkgs.findutils}/bin/find ~/.config/claude -name "*.json" -delete 2>/dev/null || true
          $DRY_RUN_CMD ${pkgs.writeShellScript "setup-claude-mcp" ''
            echo "Removing existing MCP servers..."
            for server in ${
              lib.concatStringsSep " " (lib.mapAttrsToList (name: _: lib.escapeShellArg name) cfg.servers)
            }; do
              claude mcp remove "$server" -s user 2>/dev/null || true
              claude mcp remove "$server" -s project 2>/dev/null || true
              claude mcp remove "$server" 2>/dev/null || true
            done
            echo "Running MCP server registration commands..."
            ${mcpAddCommands}
            echo "Claude MCP server registration complete"
          ''}
        else
          echo "Claude CLI not found, skipping MCP server registration"
        fi
      ''
    );
  };

  services.mcp = {
    enable = true;

    targets = {
      cursor = {
        directory = "${config.home.homeDirectory}/.cursor";
        fileName = "mcp.json";
      };
      claude = {
        directory = claudeConfigDir;
        fileName = "claude_desktop_config.json";
      };
    };

    servers = servers.commonServers // {
      # Override time port for darwin
      time = servers.commonServers.fetch // {
        args = [ "mcp-server-time" ];
        port = servers.ports.time-darwin;
      };

      # Override sequential-thinking port for darwin
      sequential-thinking = {
        command = "${servers.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
        port = servers.ports.sequential-thinking-darwin;
      };

      # Darwin-specific servers
      kagi = {
        command = "${config.home.homeDirectory}/bin/kagi-mcp-wrapper";
        args = [ ];
        port = servers.ports.kagi;
      };

      docs-mcp-server = {
        command = "${config.home.homeDirectory}/bin/docs-mcp-wrapper";
        args = [ ];
        port = servers.ports.docs;
      };

      # Darwin uses docker for github
      github = {
        command = "${pkgs.docker}/bin/docker";
        args = [
          "run"
          "-i"
          "--rm"
          "-e"
          "GITHUB_TOKEN"
          "ghcr.io/github/github-mcp-server"
        ];
        port = servers.ports.github;
        env = {
          GITHUB_TOKEN = systemConfig.sops.secrets.GITHUB_TOKEN.path or "";
        };
      };
    };
  };
}
