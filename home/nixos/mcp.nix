{
  pkgs,
  config,
  systemConfig,
  lib,
  system,
  hostSystem,
  ...
}:
let
  isLinux = lib.strings.hasSuffix "linux" hostSystem;
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
  inherit (lib)
    concatStringsSep
    mapAttrsToList
    escapeShellArg
    ;
  uvx = "${pkgs.uv}/bin/uvx";
  openaiWrapper = pkgs.writeShellApplication {
    name = "openai-mcp-wrapper";
    runtimeInputs = [
      pkgs.coreutils
      (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs)
    ];
    text = ''
      set -euo pipefail
      OPENAI_API_KEY="$(cat ${systemConfig.sops.secrets.OPENAI_API_KEY.path})"
      export OPENAI_API_KEY
      export DOCS_RS="''${DOCS_RS:-1}"
      if [ -z "''${RUSTDOCFLAGS:-}" ]; then
        export RUSTDOCFLAGS="--cfg=docsrs"
      fi
      exec ${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx -y @mzxrai/mcp-openai "$@"
    '';
  };
  kagiWrapper = pkgs.writeShellApplication {
    name = "kagi-mcp-wrapper";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.uv
    ];
    text = ''
      set -euo pipefail
      KAGI_API_KEY="$(cat ${systemConfig.sops.secrets.KAGI_API_KEY.path})"
      export KAGI_API_KEY
      export UV_PYTHON="${pkgs.python3}/bin/python3"
      exec ${uvx} --from kagimcp kagimcp "$@"
    '';
  };
  githubWrapper = pkgs.writeShellApplication {
    name = "github-mcp-wrapper";
    runtimeInputs = [
      pkgs.coreutils
      (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs)
    ];
    text = ''
      set -euo pipefail
      GITHUB_TOKEN="$(cat ${systemConfig.sops.secrets.GITHUB_TOKEN.path})"
      export GITHUB_TOKEN
      exec ${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx -y @modelcontextprotocol/server-github@latest "$@"
    '';
  };
  rustdocsWrapper = pkgs.writeShellApplication {
    name = "rustdocs-mcp-wrapper";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.nix
    ];
    text = ''
      set -euo pipefail
      OPENAI_API_KEY="$(cat ${systemConfig.sops.secrets.OPENAI_API_KEY.path})"
      export OPENAI_API_KEY
      CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/mcp"
      OUT_LINK="$CACHE_DIR/rustdocs-mcp-server"
      mkdir -p "$CACHE_DIR"
      if [ ! -e "$OUT_LINK" ] || [ ! -x "$OUT_LINK/bin/rustdocs_mcp_server" ]; then
        echo "[rustdocs-wrapper] Building rustdocs-mcp-server via nix…"
        ${pkgs.nix}/bin/nix build github:Govcraft/rust-docs-mcp-server
        mv -T "$OUT_LINK.tmp" "$OUT_LINK"
      fi
      export PKG_CONFIG_PATH="${pkgs.alsa-lib.dev}/lib/pkgconfig:${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.systemd.dev}/lib/pkgconfig:${pkgs.pkg-config}/lib/pkgconfig:''${PKG_CONFIG_PATH:-}"
      export OPENSSL_DIR="${pkgs.openssl.out}"
      export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
      export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      if [ -n "''${MCP_NIX_SHELL:-}" ]; then
        exec ${pkgs.nix}/bin/nix develop "''${MCP_NIX_SHELL}" -c "$OUT_LINK/bin/rustdocs_mcp_server" "$@"
      fi
      EXTRA_PKGS="''${MCP_EXTRA_NIX_PKGS:-}"
      extra_args=()
      if [ -n "$EXTRA_PKGS" ]; then
        read -r -a extra_args <<< "$EXTRA_PKGS"
      fi
      exec ${pkgs.nix}/bin/nix shell \
        ${pkgs.pkg-config} ${pkgs.alsa-lib} ${pkgs.openssl} ${pkgs.openssl.dev} ${pkgs.cacert} ${pkgs.systemd} ${pkgs.systemd.dev} \
        "''${extra_args[@]}" -c "$OUT_LINK/bin/rustdocs_mcp_server" "$@"
    '';
  };
  mkAddJsonCmd =
    name: serverCfg:
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
                line="''${line%%#*}"
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
    ${rustdocsWrapper}/bin/rustdocs-mcp-wrapper --help >/dev/null 2>&1 || true
    echo "[mcp-warm] Prefetching uvx servers…"
    ${pkgs.uv}/bin/uvx --from cli-mcp-server cli-mcp-server --help >/dev/null 2>&1 || true
    ${pkgs.uv}/bin/uvx --from mcp-server-fetch mcp-server-fetch --help >/dev/null 2>&1 || true
    ${pkgs.uv}/bin/uvx --from mcp-server-git mcp-server-git --help >/dev/null 2>&1 || true
    ${pkgs.uv}/bin/uvx --from mcp-server-time mcp-server-time --help >/dev/null 2>&1 || true
    echo "[mcp-warm] Prefetching npx servers…"
    ${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx -y @modelcontextprotocol/server-everything@latest --help >/dev/null 2>&1 || true
    ${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx -y @modelcontextprotocol/server-filesystem@latest --help >/dev/null 2>&1 || true
    ${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx -y @modelcontextprotocol/server-memory@latest --help >/dev/null 2>&1 || true
    ${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx -y @modelcontextprotocol/server-sequential-thinking@latest --help >/dev/null 2>&1 || true
    ${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx -y tritlo/lsp-mcp --help >/dev/null 2>&1 || true
    echo "[mcp-warm] Warm-up complete."
  '';
in
{
  home = {
    packages = with pkgs; [
      uv
      python3
      (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs)
      coreutils
      gawk
      kagiWrapper
      openaiWrapper
      lua-language-server
      # Use explicitly versioned nodejs packages to avoid cache misses
      (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs).pkgs.typescript-language-server
      (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs).pkgs.typescript
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
    servers = {
      github = {
        command = "${githubWrapper}/bin/github-mcp-wrapper";
        args = [ ];
        port = 11434;
      };
      memory = {
        command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-memory@latest"
        ];
        port = 11436;
      };
      sequential-thinking = {
        command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking@latest"
        ];
        port = 11437;
      };
      general-filesystem = {
        command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem@latest"
          "${config.home.homeDirectory}/Code"
          "${config.home.homeDirectory}/.config"
          "${config.home.homeDirectory}/Documents"
        ];
        port = 11442;
      };
      kagi = {
        command = "${kagiWrapper}/bin/kagi-mcp-wrapper";
        args = [ ];
        port = 11431;
      };
      fetch = {
        command = "${pkgs.uv}/bin/uvx";
        args = [
          "--from"
          "mcp-server-fetch"
          "mcp-server-fetch"
        ];
        port = 11432;
        env = {
          UV_PYTHON = "${pkgs.python3}/bin/python3";
        };
      };
      git = {
        command = "${pkgs.uv}/bin/uvx";
        args = [
          "--from"
          "mcp-server-git"
          "mcp-server-git"
          "--repository"
          "${config.home.homeDirectory}/Code/dex-web"
        ];
        port = 11433;
        env = {
          UV_PYTHON = "${pkgs.python3}/bin/python3";
        };
      };
      time = {
        command = "${pkgs.uv}/bin/uvx";
        args = [
          "--from"
          "mcp-server-time"
          "mcp-server-time"
        ];
        port = 11445;
        env = {
          UV_PYTHON = "${pkgs.python3}/bin/python3";
        };
      };
      openai = {
        command = "${openaiWrapper}/bin/openai-mcp-wrapper";
        args = [ ];
        port = 11439;
      };
      rust-docs-bevy = {
        command = "${rustdocsWrapper}/bin/rustdocs-mcp-wrapper";
        args = [
          "bevy@0.16.1"
          "-F"
          "default"
        ];
        port = 11440;
      };
    };
  };
  systemd.user.services.mcp-claude-register = lib.mkIf isLinux {
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
  systemd.user.services.mcp-warm = lib.mkIf isLinux {
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
}
