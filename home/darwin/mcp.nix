{
  pkgs,
  config,
  lib,
  system,
  ...
}: let
  platformLib = import ../../lib/functions.nix {inherit lib system;};
  claudeConfigDir = platformLib.dataDir config.home.username + "/Claude";
  codeDirectory = "${config.home.homeDirectory}/Code";
  dexWebProject = "${codeDirectory}/dex-web";
in {
  home = {
    packages = with pkgs; [
      uv
      python3
    ];
    file = {
      "bin/kagi-mcp-wrapper" = {
        text = ''
          if [ -r "${config.sops.secrets.KAGI_API_KEY.path or ""}" ]; then
            export KAGI_API_KEY="$(cat "${config.sops.secrets.KAGI_API_KEY.path or ""}")"
          fi
          exec ${pkgs.uv}/bin/uvx kagimcp "$@"
        '';
        executable = true;
      };
    };
    activation.setupClaudeMcp = lib.hm.dag.entryAfter ["writeBoundary"] (
      let
        cfg = config.services.mcp;
        mcpAddCommands = lib.concatStringsSep "\n        " (
          lib.mapAttrsToList
          (
            name: serverCfg: let
              command = lib.escapeShellArg serverCfg.command;
              argsStr = lib.concatStringsSep " " (map lib.escapeShellArg serverCfg.args);
              argsPart = lib.optionalString (argsStr != "") "-- ${argsStr}";
              envVars = lib.concatStringsSep " " (
                lib.mapAttrsToList
                (
                  key: value: "export ${lib.escapeShellArg key}=${lib.escapeShellArg value};"
                )
                serverCfg.env
              );
            in ''${envVars} claude mcp add ${lib.escapeShellArg name} -s user ${command} ${argsPart} || echo "Failed to add ${name} server"''
          )
          cfg.servers
        );
      in ''
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
    servers = {
      kagi = {
        command = "${config.home.homeDirectory}/bin/kagi-mcp-wrapper";
        args = [];
        port = 11431;
      };
      fetch = {
        command = "${pkgs.uv}/bin/uvx";
        args = ["mcp-server-fetch"];
        port = 11432;
      };
      git = {
        command = "${pkgs.uv}/bin/uvx";
        args = [
          "mcp-server-git"
          "--repository"
          dexWebProject
        ];
        port = 11433;
      };
      memory = {
        command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-memory"
        ];
        port = 11436;
      };
      sequential-thinking = {
        command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
        port = 11438;
      };
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
        port = 11434;
        env = {
          GITHUB_TOKEN = config.sops.secrets.GITHUB_TOKEN.path or "";
        };
      };
      general-filesystem = {
        command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "${codeDirectory}"
          "${config.home.homeDirectory}/.config"
          "${config.home.homeDirectory}/Documents"
        ];
        port = 11442;
      };
      time = {
        command = "${pkgs.uv}/bin/uvx";
        args = ["mcp-server-time"];
        port = 11443;
      };
    };
  };
}
