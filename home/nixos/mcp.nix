{ pkgs, config, systemConfig, lib, system, hostSystem, ... }:

let
  isLinux = lib.strings.hasSuffix "linux" hostSystem;
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;

  # Import shared MCP utilities
  servers = import ../../modules/shared/mcp/servers.nix { inherit pkgs config systemConfig lib platformLib; };
  wrappers = import ../../modules/shared/mcp/wrappers.nix { inherit pkgs systemConfig lib platformLib; };

  inherit (lib) concatStringsSep mapAttrsToList escapeShellArg;

  # MCP registration helper
  mkAddJsonCmd = name: serverCfg:
    let
      json = builtins.toJSON (
        {
          type = "stdio";
          args = serverCfg.args or [ ];
          env = serverCfg.env or { };
        }
        // {
          inherit (serverCfg) command;
        }
      );
      jsonArg = escapeShellArg json;
    in
    ''
      claude mcp remove ${escapeShellArg name} --scope user >/dev/null 2>&1 || true
      claude mcp add-json ${escapeShellArg name} ${jsonArg} --scope user
    '';

  declaredNames = mapAttrsToList (n: _: escapeShellArg n) config.services.mcp.servers;
  addCommands = concatStringsSep "\n" (mapAttrsToList mkAddJsonCmd config.services.mcp.servers);

  registerScript = pkgs.writeShellScript "mcp-register" ''
    set -uo pipefail
    echo "[mcp] Starting Claude MCP registration…"
    export PATH="${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gawk}/bin:${pkgs.jq}/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:$PATH"
    export MCP_TIMEOUT="''${MCP_TIMEOUT:-60000}"
    if ! command -v claude >/dev/null 2>&1; then
      echo "[mcp] WARNING: 'claude' CLI not found in PATH, skipping registration"
      exit 0
    fi
    DRY_RUN="''${MCP_DRY_RUN:-0}"
    declare -a DECLARED=( ${concatStringsSep " " declaredNames} )
    echo "[mcp] Declared servers: ${concatStringsSep " " declaredNames}"
    if [ "$DRY_RUN" = "1" ]; then
      echo "[mcp] DRY-RUN: would run:"
      cat <<'ADD_CMDS'
${addCommands}
ADD_CMDS
    else
      while IFS= read -r line; do
        line="''${line%%$'\r'}"
        [ -z "$line" ] && continue
        case "$line" in
          *)
            echo "[mcp] -> $line"
            if ! bash -lc "$line" >/dev/null 2>&1; then
              echo "[mcp] WARN: add failed, will evaluate health after list"
            fi
            ;;
        esac
      done <<'ADD_CMDS'
${addCommands}
ADD_CMDS
    fi
    echo "[mcp] Skipping health prune (using add-json mirroring)"
    echo "[mcp] Skipping unmanaged prune"
    echo "[mcp] Final state (MCP_TIMEOUT=$MCP_TIMEOUT):"
    claude mcp list || echo "[mcp] WARNING: claude mcp list failed"
    echo "[mcp] Claude MCP registration complete."
  '';

  warmScript = pkgs.writeShellScript "mcp-warm" ''
    set -euo pipefail
    echo "[mcp-warm] Starting warm-up…"
    export PATH="${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH"
    export UV_PYTHON="${pkgs.python3}/bin/python3"
    echo "[mcp-warm] Prebuilding rustdocs-mcp-server binary…"
    ${wrappers.rustdocsWrapper}/bin/rustdocs-mcp-wrapper --help >/dev/null 2>&1 || true
    echo "[mcp-warm] Prefetching uvx servers…"
    ${pkgs.uv}/bin/uvx --from cli-mcp-server cli-mcp-server --help >/dev/null 2>&1 || true
    ${pkgs.uv}/bin/uvx --from mcp-server-fetch mcp-server-fetch --help >/dev/null 2>&1 || true
    ${pkgs.uv}/bin/uvx --from mcp-server-git mcp-server-git --help >/dev/null 2>&1 || true
    ${pkgs.uv}/bin/uvx --from mcp-server-time mcp-server-time --help >/dev/null 2>&1 || true
    ${pkgs.uv}/bin/uvx --from mcp-nixos mcp-nixos --help >/dev/null 2>&1 || true
    echo "[mcp-warm] Prefetching npx servers…"
    ${servers.nodejs}/bin/npx -y @modelcontextprotocol/server-everything@latest --help >/dev/null 2>&1 || true
    ${servers.nodejs}/bin/npx -y @modelcontextprotocol/server-filesystem@latest --help >/dev/null 2>&1 || true
    ${servers.nodejs}/bin/npx -y @modelcontextprotocol/server-memory@latest --help >/dev/null 2>&1 || true
    ${servers.nodejs}/bin/npx -y @modelcontextprotocol/server-sequential-thinking@latest --help >/dev/null 2>&1 || true
    ${servers.nodejs}/bin/npx -y @arabold/docs-mcp-server@latest --help >/dev/null 2>&1 || true
    ${servers.nodejs}/bin/npx -y tritlo/lsp-mcp --help >/dev/null 2>&1 || true
    echo "[mcp-warm] Warm-up complete."
  '';

in {
  home = {
    packages = [
      pkgs.uv
      servers.nodejs
      pkgs.coreutils
      pkgs.gawk
      wrappers.kagiWrapper
      wrappers.openaiWrapper
      wrappers.docsMcpWrapper
      pkgs.lua-language-server
      pkgs.nodePackages.typescript-language-server
      pkgs.nodePackages.typescript
    ];

    activation.mcpWarm = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${warmScript}
    '';

    activation.setupClaudeMcp = lib.hm.dag.entryAfter [ "mcpWarm" ] ''
      ${registerScript}
    '';
  };

  services.mcp = {
    enable = true;

    targets = {
      cursor = {
        directory = "${config.home.homeDirectory}/.cursor";
        fileName = "mcp.json";
      };
      claude-code = {
        directory = "${config.home.homeDirectory}/.config/claude";
        fileName = "claude_desktop_config.json";
      };
    };

    servers = servers.commonServers // {
      # Override sequential-thinking port for nixos
      sequential-thinking = {
        command = "${servers.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking@latest"
        ];
        port = servers.ports.sequential-thinking-nixos;
      };

      # Override time port for nixos
      time = {
        command = "${pkgs.uv}/bin/uvx";
        args = [
          "--from"
          "mcp-server-time"
          "mcp-server-time"
        ];
        port = servers.ports.time-nixos;
        env = {
          UV_PYTHON = "${pkgs.python3}/bin/python3";
        };
      };

      # NixOS-specific servers with wrappers
      kagi = {
        command = "${wrappers.kagiWrapper}/bin/kagi-mcp-wrapper";
        args = [ ];
        port = servers.ports.kagi;
      };

      github = {
        command = "${wrappers.githubWrapper}/bin/github-mcp-wrapper";
        args = [ ];
        port = servers.ports.github;
      };

      openai = {
        command = "${wrappers.openaiWrapper}/bin/openai-mcp-wrapper";
        args = [ ];
        port = servers.ports.openai;
      };

      docs-mcp-server = {
        command = "${wrappers.docsMcpWrapper}/bin/docs-mcp-wrapper";
        args = [ ];
        port = servers.ports.docs;
      };

      rust-docs-bevy = {
        command = "${wrappers.rustdocsWrapper}/bin/rustdocs-mcp-wrapper";
        args = [
          "bevy@0.16.1"
          "-F"
          "default"
        ];
        port = servers.ports.rust-docs;
      };
    };
  };

  systemd.user.services = lib.mkIf isLinux {
    mcp-claude-register = {
      Unit = {
        Description = "Register MCP servers for Claude CLI (idempotent)";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${registerScript}";
        Environment = [
          "PATH=/etc/profiles/per-user/%u/bin:%h/.nix-profile/bin:$PATH"
        ];
        TimeoutStartSec = "300";
        Restart = "on-failure";
        RestartSec = "30";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    mcp-warm = {
      Unit = {
        Description = "Warm MCP servers (build binaries, prefetch packages)";
        After = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${warmScript}";
        TimeoutStartSec = "900";
        Environment = [
          "PATH=/etc/profiles/per-user/%u/bin:%h/.nix-profile/bin:$PATH"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    docs-mcp-http = {
      Unit = {
        Description = "Docs MCP Server HTTP Interface";
        After = [ "network-online.target" ];
      };
      Service = {
        ExecStart = "${wrappers.docsMcpWrapper}/bin/docs-mcp-wrapper --protocol http --host 0.0.0.0 --port 6280";
        Restart = "on-failure";
        Environment = [
          "PATH=/etc/profiles/per-user/%u/bin:%h/.nix-profile/bin:$PATH"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
