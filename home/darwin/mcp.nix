{ pkgs
, config
, lib
, system
, ...
}:
let
  platformLib = import ../../lib/functions.nix { inherit lib system; };

  # Dynamic paths
  claudeConfigDir = platformLib.dataDir config.home.username + "/Claude";
  codeDirectory = "${config.home.homeDirectory}/Code";
  dexWebProject = "${codeDirectory}/dex-web";
in
{
  home = {
    packages = with pkgs; [
      uv
      python3
    ];

    file = {
      "bin/kagi-mcp-wrapper" = {
        text = ''
          #!/usr/bin/env bash
          if [ -r "${config.sops.secrets.KAGI_API_KEY.path or ""}" ]; then
            export KAGI_API_KEY="$(cat "${config.sops.secrets.KAGI_API_KEY.path or ""}")"
          fi
          exec ${pkgs.uv}/bin/uvx kagimcp "$@"
        '';
        executable = true;
      };
    };

    # Activation script to register MCP servers with Claude Code
    activation.setupClaudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      let
        cfg = config.services.mcp;

        # Generate claude mcp add commands for each configured server
        mcpAddCommands = lib.concatStringsSep "\n        " (
          lib.mapAttrsToList
            (
              name: serverCfg:
                let
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
                in
                ''${envVars} claude mcp add ${lib.escapeShellArg name} -s user ${command} ${argsPart} || echo "Failed to add ${name} server"''
            )
            cfg.servers
        );
      in
      ''
        if command -v claude >/dev/null 2>&1; then
          echo "Registering MCP servers with Claude Code..."

          # Remove existing servers first (ignore errors)
          ${pkgs.findutils}/bin/find ~/.config/claude -name "*.json" -delete 2>/dev/null || true

          # Add each configured server
          $DRY_RUN_CMD ${pkgs.writeShellScript "setup-claude-mcp" ''
          echo "Removing existing MCP servers..."
          # Remove existing servers in all scopes (ignore errors)
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
        args = [ ];
        port = 11431;
      };
      fetch = {
        command = "${pkgs.uv}/bin/uvx";
        args = [ "mcp-server-fetch" ];
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
      nx = {
        command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
        args = [
          "nx-mcp@latest"
          dexWebProject
        ];
        port = 11437;
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
          "GITHUB_PERSONAL_ACCESS_TOKEN"
          "ghcr.io/github/github-mcp-server"
        ];
        port = 11434;
        env = {
          GITHUB_PERSONAL_ACCESS_TOKEN = config.sops.secrets.GITHUB_PERSONAL_ACCESS_TOKEN.path or "";
        };
      };
      filesystem = {
        command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "${config.home.homeDirectory}"
          "${config.home.homeDirectory}/.config"
        ];
        port = 11439;
      };
      mcp-obsidian = {
        command = "${pkgs.uv}/bin/uvx";
        args = [
          "mcp-obsidian"
        ];
        env = {
          OBSIDIAN_API_KEY = config.sops.secrets.OBSIDIAN_API_KEY.path or "";
          OBSIDIAN_HOST = "127.0.0.1";
          OBSIDIAN_PORT = "27124";
        };
      };
      love2d-api = {
        command = "${pkgs.uv}/bin/uvx";
        args = [
          "--python"
          "${pkgs.python3}/bin/python3"
          "--with"
          "mcp"
          "--with"
          "requests"
          "python"
          "${config.home.homeDirectory}/.config/nix/mcp-servers/love2d-api.py"
        ];
        port = 11440;
      };
      love2d-filesystem = {
        command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "${codeDirectory}/love2d-projects"
          "${config.home.homeDirectory}/.local/share/love"
        ];
        port = 11441;
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
        args = [ "mcp-server-time" ];
        port = 11443;
      };
      everything = {
        command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-everything"
        ];
        port = 11444;
      };
      # figma = {
      #   command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
      #   args = [
      #     "-y"
      #     "mcp-remote"
      #     "http://127.0.0.1:3845/mcp"
      #   ];
      #   port = 11445;
      # };
    };
  };
}
