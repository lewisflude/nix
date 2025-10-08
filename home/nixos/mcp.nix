{ pkgs
, config
, lib
, system
, ...
}:
let
  platformLib = import ../../lib/functions.nix { inherit lib system; };
  inherit
    (lib)
    concatStringsSep
    mapAttrsToList
    escapeShellArg
    ;

  uvx = "${pkgs.uv}/bin/uvx";

  # --- New: OpenAI wrapper (reads SOPS secret at runtime)
  openaiWrapper = pkgs.writeShellApplication {
    name = "openai-mcp-wrapper";
    runtimeInputs = [
      pkgs.coreutils
      (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs)
    ];
    text = ''
      set -euo pipefail
      OPENAI_API_KEY="$(cat ${config.sops.secrets.OPENAI_API_KEY.path})"
      export OPENAI_API_KEY
      # Prefer docs.rs-style builds to avoid heavy system deps during cargo doc
      export DOCS_RS="''${DOCS_RS:-1}"
      if [ -z "''${RUSTDOCFLAGS:-}" ]; then
        export RUSTDOCFLAGS="--cfg=docsrs"
      fi
      exec ${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx -y @mzxrai/mcp-openai "$@"
    '';
  };

  # Existing Kagi wrapper kept as-is…
  kagiWrapper = pkgs.writeShellApplication {
    name = "kagi-mcp-wrapper";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.uv
    ];
    text = ''
      set -euo pipefail
      KAGI_API_KEY="$(cat ${config.sops.secrets.KAGI_API_KEY.path})"
      export KAGI_API_KEY
      # Force uv to use Nix's Python on NixOS
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
      GITHUB_TOKEN="$(cat ${config.sops.secrets.GITHUB_TOKEN.path})"
      export GITHUB_TOKEN
      exec ${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx -y @modelcontextprotocol/server-github@latest "$@"
    '';
  };

  # Wrapper for rust-docs MCP server using the upstream flake via nix run.
  # Reads OPENAI_API_KEY from SOPS and passes through all CLI args, e.g.:
  #   rustdocs-mcp-wrapper "reqwest@0.12" -F some-feature
  rustdocsWrapper = pkgs.writeShellApplication {
    name = "rustdocs-mcp-wrapper";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.nix
    ];
    text = ''
      set -euo pipefail
      OPENAI_API_KEY="$(cat ${config.sops.secrets.OPENAI_API_KEY.path})"
      export OPENAI_API_KEY
      # Prebuild the server once and reuse a stable out-link to avoid cold starts
      CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/mcp"
      OUT_LINK="$CACHE_DIR/rustdocs-mcp-server"
      mkdir -p "$CACHE_DIR"

      if [ ! -e "$OUT_LINK" ] || [ ! -x "$OUT_LINK/bin/rustdocs_mcp_server" ]; then
        echo "[rustdocs-wrapper] Building rustdocs-mcp-server via nix…"
        ${pkgs.nix}/bin/nix build github:Govcraft/rust-docs-mcp-server#rustdocs-mcp-server --out-link "$OUT_LINK.tmp"
        mv -T "$OUT_LINK.tmp" "$OUT_LINK"
      fi

      # Provide system libs for crates that run pkg-config in build scripts (e.g., alsa/openssl/systemd)
      export PKG_CONFIG_PATH="${pkgs.alsa-lib.dev}/lib/pkgconfig:${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.systemd.dev}/lib/pkgconfig:${pkgs.pkg-config}/lib/pkgconfig:''${PKG_CONFIG_PATH:-}"
      export OPENSSL_DIR="${pkgs.openssl.out}"
      export OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib"
      export OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include"
      # Ensure TLS certs for HTTPS inside nix shell
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

      # If a dev shell is provided, use that (best for complex native deps)
      if [ -n "''${MCP_NIX_SHELL:-}" ]; then
        exec ${pkgs.nix}/bin/nix develop "''${MCP_NIX_SHELL}" -c "$OUT_LINK/bin/rustdocs_mcp_server" "$@"
      fi

      # Otherwise use a minimal shell plus any extra packages requested via MCP_EXTRA_NIX_PKGS
      EXTRA_PKGS="''${MCP_EXTRA_NIX_PKGS:-}"
      # Parse space-separated EXTRA_PKGS into an array safely
      extra_args=()
      if [ -n "$EXTRA_PKGS" ]; then
        # read splits on IFS (spaces) deliberately to form an array of package references
        # shellcheck disable=SC2162  # read without -r is not used here; we use -r
        read -r -a extra_args <<< "$EXTRA_PKGS"
      fi

      exec ${pkgs.nix}/bin/nix shell \
        ${pkgs.pkg-config} ${pkgs.alsa-lib} ${pkgs.openssl} ${pkgs.openssl.dev} ${pkgs.cacert} ${pkgs.systemd} ${pkgs.systemd.dev} \
        "''${extra_args[@]}" -c "$OUT_LINK/bin/rustdocs_mcp_server" "$@"
    '';
  };

  # ----- helpers for activation script generation -----

  mkAddJsonCmd = name: serverCfg:
    let
      json = builtins.toJSON ({
        type = "stdio";
        args = serverCfg.args or [ ];
        env = serverCfg.env or { };
      }
      // {
        inherit (serverCfg) command;
      });
      jsonArg = escapeShellArg json;
    in
    ''
      # ${name}
      claude mcp remove ${escapeShellArg name} --scope user >/dev/null 2>&1 || true
      claude mcp add-json ${escapeShellArg name} ${jsonArg} --scope user
    '';

  declaredNames = mapAttrsToList (n: _: escapeShellArg n) config.services.mcp.servers;
  addCommands = concatStringsSep "\n" (mapAttrsToList mkAddJsonCmd config.services.mcp.servers);

  # Reusable registration script (invoked by activation + user services)
  # Reusable registration script (invoked by activation + user services)
  registerScript = pkgs.writeShellScript "mcp-register" ''
            set -uo pipefail
            echo "[mcp] Starting Claude MCP registration…"
            export PATH="${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gawk}/bin:${pkgs.jq}/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:$PATH"
            # Give slow starters more time during health checks (especially for large Rust crates)
            export MCP_TIMEOUT="''${MCP_TIMEOUT:-60000}"

            if ! command -v claude >/dev/null 2>&1; then
              echo "[mcp] WARNING: 'claude' CLI not found in PATH, skipping registration"
              exit 0
            fi

            DRY_RUN="''${MCP_DRY_RUN:-0}"

            # Bash array of declared names (rendered by Nix)
            declare -a DECLARED=( ${concatStringsSep " " declaredNames} )
            echo "[mcp] Declared servers: ${concatStringsSep " " declaredNames}"

            # 1) Register declared servers
            if [ "$DRY_RUN" = "1" ]; then
              echo "[mcp] DRY-RUN: would run:"
              cat <<'ADD_CMDS'
    ${addCommands}
    ADD_CMDS
            else
              # Execute only real commands; skip blanks and comment lines (e.g. '# name')
              while IFS= read -r line; do
                # trim leading whitespace
                line="''${line#"''${line%%[![:space:]]*}"}"
                [ -z "$line" ] && continue
                case "$line" in \#*) continue ;; esac
                echo "[mcp] -> $line"
                if ! bash -lc "$line" >/dev/null 2>&1; then
                  echo "[mcp] WARN: add failed, will evaluate health after list"
                fi
              done <<'ADD_CMDS'
    ${addCommands}
    ADD_CMDS
            fi

            # 2) Health check disabled for add-json mirroring to avoid pruning slow starters
            echo "[mcp] Skipping health prune (using add-json mirroring)"

            # 3) Prune unmanaged disabled to avoid deleting user-managed CLI entries
            echo "[mcp] Skipping unmanaged prune"

            echo "[mcp] Final state (MCP_TIMEOUT=$MCP_TIMEOUT):"
            claude mcp list || echo "[mcp] WARNING: claude mcp list failed"
            echo "[mcp] Claude MCP registration complete."
  '';

  # Warm-up script to prebuild binaries and prefetch packages
  warmScript = pkgs.writeShellScript "mcp-warm" ''
    set -euo pipefail
    echo "[mcp-warm] Starting warm-up…"
    export PATH="${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH"
    # Ensure uv uses Nix's Python on NixOS (avoid generic prebuilt interpreter)
    export UV_PYTHON="${pkgs.python3}/bin/python3"

    # 1) Prebuild Rust docs server binary (no API calls)
    echo "[mcp-warm] Prebuilding rustdocs-mcp-server binary…"
    ${rustdocsWrapper}/bin/rustdocs-mcp-wrapper --help >/dev/null 2>&1 || true

    # 2) Prefetch uvx-based Python servers (downloads wheels once)
    echo "[mcp-warm] Prefetching uvx servers…"
    ${pkgs.uv}/bin/uvx --from cli-mcp-server cli-mcp-server --help >/dev/null 2>&1 || true
    ${pkgs.uv}/bin/uvx --from mcp-server-fetch mcp-server-fetch --help >/dev/null 2>&1 || true
    ${pkgs.uv}/bin/uvx --from mcp-server-git mcp-server-git --help >/dev/null 2>&1 || true
    ${pkgs.uv}/bin/uvx --from mcp-server-time mcp-server-time --help >/dev/null 2>&1 || true

    # 3) Prefetch common npx servers (installs package cache)
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
  ################################
  # Combined home configuration
  ################################
  home = {
    packages = with pkgs; [
      uv
      python3
      (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs)
      coreutils
      gawk
      kagiWrapper
      openaiWrapper

      # --- New: LSPs for MCP bridges (absolute binaries available)
      lua-language-server
      nodePackages.typescript-language-server
      nodePackages.typescript
    ];

    # Run warm-up on switch, then register servers
    activation.mcpWarm = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${warmScript}
    '';
    activation.setupClaudeMcp = lib.hm.dag.entryAfter [ "mcpWarm" ] ''
      ${registerScript}
    '';
  };

  ############################
  # MCP (consumer) declaration
  ############################
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

    # Servers
    servers =
      let
        inherit (pkgs.nodePackages) typescript-language-server;
        tsls = "${typescript-language-server}/bin/typescript-language-server";
      in
      {
        # --- Existing servers (kept) ---

        everything = {
          command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-everything@latest"
          ];
          port = 11446;
        };

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

        # Kagi via wrapper (unchanged)
        kagi = {
          command = "${kagiWrapper}/bin/kagi-mcp-wrapper";
          args = [ ];
          port = 11431;
        };

        # Python uvx servers (unchanged)
        fetch = {
          command = "${pkgs.mcp-server-fetch}/bin/mcp-server-fetch";
          args = [ ];
          port = 11432;
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

        # --- New: OpenAI (npm) via wrapper
        openai = {
          command = "${openaiWrapper}/bin/openai-mcp-wrapper";
          args = [ ];
          port = 11439;
        };

        # --- New: CLI MCP (secure command runner)
        cli = {
          command = "${pkgs.uv}/bin/uvx";
          args = [
            "--from"
            "cli-mcp-server"
            "cli-mcp-server"
          ];
          port = 11438;
          env = {
            # Restrict command surface and working dir; edit to taste
            ALLOWED_DIR = "${config.home.homeDirectory}/Code";
            ALLOWED_COMMANDS = "git,ls,cat,pwd,rg,nix,just";
            ALLOWED_FLAGS = "-l,-a,--help,--version";
            COMMAND_TIMEOUT = "10"; # seconds
            MAX_COMMAND_LENGTH = "2048"; # chars
            ALLOW_SHELL_OPERATORS = "0"; # block pipes, &&, ;, etc.
            UV_PYTHON = "${pkgs.python3}/bin/python3";
          };
        };

        # --- New: Rust Documentation MCP Servers (Bevy Game Development)
        rust-docs-bevy = {
          command = "${rustdocsWrapper}/bin/rustdocs-mcp-wrapper";
          args = [
            "bevy@0.16.1"
            "-F"
            "default"
          ];
          port = 11440;
        };

        rust-docs-bevy-lunex = {
          command = "${rustdocsWrapper}/bin/rustdocs-mcp-wrapper";
          args = [
            "bevy_lunex@0.4.2"
          ];
          port = 11441;
        };

        rust-docs-hexx = {
          command = "${rustdocsWrapper}/bin/rustdocs-mcp-wrapper";
          args = [
            "hexx@0.20.0"
            "-F"
            "serde,mesh"
          ];
          port = 11442;
        };

        rust-docs-ron = {
          command = "${rustdocsWrapper}/bin/rustdocs-mcp-wrapper";
          args = [
            "ron@0.8.1"
          ];
          port = 11443;
        };

        # --- New: LSP → MCP bridges
        lsp-ts = {
          command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
          args = [
            "-y"
            "tritlo/lsp-mcp"
            "ts"
            "${tsls}"
            "--stdio"
          ];
          port = 11447;
        };

        # (Optional) Luau/Roblox — add later once you have a concrete LSP path
        # lsp-luau = {
        #   command = "${platformLib.getVersionedPackage pkgs platformLib.versions.nodejs}/bin/npx";
        #   args    = [ "-y" "tritlo/lsp-mcp" "lua" "/absolute/path/to/roblox-lsp" "--stdio" ];
        #   port    = 11449;
        # };

        # --- Rust documentation server
        rust-docs = {
          # Example targeting reqwest; duplicate this stanza per crate you want.
          command = "${rustdocsWrapper}/bin/rustdocs-mcp-wrapper";
          args = [
            "reqwest@0.12"
            # "-F" "some,features"  # uncomment/add if the crate needs features
          ];
          port = 11450;
        };
      };
  };

  #################################################
  # systemd services
  #################################################

  systemd.user.services.mcp-claude-register = lib.mkIf pkgs.stdenv.isLinux {
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
      # Add timeout and restart policies for robustness
      TimeoutStartSec = "300";
      Restart = "on-failure";
      RestartSec = "30";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # One-shot warm-up service you can run manually or enable on login
  systemd.user.services.mcp-warm = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Warm MCP servers (build binaries, prefetch packages)";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${warmScript}";
      # Optional: allow longer time for first fetches/builds
      TimeoutStartSec = "900";
      Environment = [
        # Keep PATH minimal; wrappers use absolute paths
        "PATH=/etc/profiles/per-user/%u/bin:%h/.nix-profile/bin:$PATH"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
