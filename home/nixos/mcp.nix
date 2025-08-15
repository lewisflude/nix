{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    concatStringsSep
    mapAttrsToList
    escapeShellArg
    optionalString
    ;

  uvx = "${pkgs.uv}/bin/uvx";
  py = "${pkgs.python3}/bin/python3";

  # --- New: OpenAI wrapper (reads SOPS secret at runtime)
  openaiWrapper = pkgs.writeShellApplication {
    name = "openai-mcp-wrapper";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.nodejs_24
    ];
    text = ''
      set -euo pipefail
      OPENAI_API_KEY="$(cat ${config.sops.secrets.OPENAI_API_KEY.path})"
      export OPENAI_API_KEY
      exec ${pkgs.nodejs_24}/bin/npx -y @mzxrai/mcp-openai "$@"
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
      exec ${uvx} --from kagimcp kagimcp "$@"
    '';
  };

  githubWrapper = pkgs.writeShellApplication {
    name = "github-mcp-wrapper";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.nodejs_24
    ];
    text = ''
      set -euo pipefail
      GITHUB_TOKEN="$(cat ${config.sops.secrets.GITHUB_TOKEN.path})"
      export GITHUB_TOKEN
      exec ${pkgs.nodejs_24}/bin/npx -y @modelcontextprotocol/server-github@latest "$@"
    '';
  };

  # ----- helpers for activation script generation -----
  mkEnvExports = envAttrs: concatStringsSep " " (mapAttrsToList (k: v: "export ${k}=${escapeShellArg v};") envAttrs);

  mkAddCmd = name: serverCfg: let
    envExports = mkEnvExports (serverCfg.env or {});
    command = escapeShellArg serverCfg.command;
    argsStr = concatStringsSep " " (map escapeShellArg (serverCfg.args or []));
    argsPart = optionalString (argsStr != "") "-- ${argsStr}";
  in ''
    # ${name}
    ${envExports} claude mcp add ${escapeShellArg name} -s user ${command} ${argsPart}
  '';

  declaredNames = mapAttrsToList (n: _: escapeShellArg n) config.services.mcp.servers;
  addCommands = concatStringsSep "\n" (mapAttrsToList mkAddCmd config.services.mcp.servers);

  # Reusable registration script (invoked by activation + user services)
  # Reusable registration script (invoked by activation + user services)
  registerScript = pkgs.writeShellScript "mcp-register" ''
            set -euo pipefail
            echo "[mcp] Starting Claude MCP registration…"
            export PATH="${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gawk}/bin:${pkgs.jq}/bin:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:$PATH"

            if ! command -v claude >/dev/null 2>&1; then
              echo "[mcp] ERROR: 'claude' CLI not found in PATH"; exit 1
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

            # 2) Health check & prune failed ones (only among declared)
            if [ "$DRY_RUN" != "1" ]; then
              claude mcp list | awk '/ - ✗ Failed to connect$/ {name=$0; sub(/:.*/,"",name); print name}' \
                | sort -u | while read -r bad; do
                    for want in "''${DECLARED[@]}"; do
                      if [ "$bad" = "$want" ]; then
                        echo "[mcp] Removing failed declared server: $bad"
                        claude mcp remove "$bad" -s user >/dev/null 2>&1 || true
                      fi
                    done
                  done
            else
              echo "[mcp] DRY-RUN: would parse 'claude mcp list' and remove failing declared servers"
            fi

            # 3) Prune unmanaged (anything that exists but isn't declared)
            if [ "$DRY_RUN" != "1" ]; then
              existing="$(claude mcp list | awk -F: '/:/{print $1}' | sed 's/^ *//;s/ *$//')"
              for name in $existing; do
                keep=0
                for want in "''${DECLARED[@]}"; do
                  [ "$name" = "$want" ] && keep=1 && break
                done
                if [ $keep -eq 0 ]; then
                  echo "[mcp] Removing unmanaged server: $name"
                  claude mcp remove "$name" -s user >/dev/null 2>&1 || true
                fi
              done
            else
              echo "[mcp] DRY-RUN: would prune unmanaged servers (diff between declared and 'claude mcp list')"
            fi

            echo "[mcp] Final state:"
            claude mcp list || true
            echo "[mcp] Claude MCP registration complete."
  '';
in {
  ################################
  # Tooling (single declaration)
  ################################
  home.packages = with pkgs; [
    uv
    python3
    nodejs_24
    coreutils
    gawk
    jq
    kagiWrapper
    openaiWrapper

    # --- New: LSPs for MCP bridges (absolute binaries available)
    lua-language-server
    nodePackages.typescript-language-server
    nodePackages.typescript
  ];

  ############################
  # MCP (consumer) declaration
  ############################
  services.mcp.enable = true;

  services.mcp.targets = {
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
  services.mcp.servers = let
    tsls = "${pkgs.nodePackages.typescript-language-server}/bin/typescript-language-server";
    luals = "${pkgs.lua-language-server}/bin/lua-language-server";
  in {
    # --- Existing servers (kept) ---

    everything = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-everything@latest"
      ];
      port = 11446;
    };

    github = {
      command = "${githubWrapper}/bin/github-mcp-wrapper";
      args = [];
      port = 11434;
    };

    memory = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-memory@latest"
      ];
      port = 11436;
    };

    sequential-thinking = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-sequential-thinking@latest"
      ];
      port = 11437;
    };

    general-filesystem = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem@latest"
        "${config.home.homeDirectory}/Code"
        "${config.home.homeDirectory}/.config"
        "${config.home.homeDirectory}/Documents"
      ];
      port = 11442;
    };

    love2d-filesystem = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem@latest"
        "${config.home.homeDirectory}/Code/love2d-projects"
        "${config.home.homeDirectory}/.local/share/love"
      ];
      port = 11441;
    };

    # Kagi via wrapper (unchanged)
    kagi = {
      command = "${kagiWrapper}/bin/kagi-mcp-wrapper";
      args = [];
      port = 11431;
    };

    # Python uvx servers (unchanged)
    fetch = {
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--from"
        "mcp-server-fetch"
        "mcp-server-fetch"
      ];
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
    };

    time = {
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--from"
        "mcp-server-time"
        "mcp-server-time"
      ];
      port = 11445;
    };

    love2d-api = {
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--python"
        "${py}"
        "--with"
        "mcp"
        "--with"
        "requests"
        "python"
        "${../../mcp-servers/love2d-api.py}"
      ];
      port = 11440;
    };

    love2d-docs = {
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--python"
        "${py}"
        "--with"
        "mcp"
        "--with"
        "httpx"
        "--with"
        "beautifulsoup4"
        "python"
        "${../../scripts/mcp/mcp_love2d_docs.py}"
      ];
      port = 11443;
    };

    lua-docs = {
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "--python"
        "${py}"
        "--with"
        "mcp"
        "--with"
        "httpx"
        "--with"
        "beautifulsoup4"
        "python"
        "${../../scripts/mcp/mcp_lua_docs.py}"
      ];
      port = 11444;
    };

    # --- New: OpenAI (npm) via wrapper
    openai = {
      command = "${openaiWrapper}/bin/openai-mcp-wrapper";
      args = [];
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
      };
    };

    # --- New: LSP → MCP bridges
    lsp-ts = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "tritlo/lsp-mcp"
        "ts"
        "${tsls}"
        "--stdio"
      ];
      port = 11447;
    };

    lsp-lua = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "tritlo/lsp-mcp"
        "lua"
        "${luals}"
        "--stdio"
      ];
      port = 11448;
    };

    # (Optional) Luau/Roblox — add later once you have a concrete LSP path
    # lsp-luau = {
    #   command = "${pkgs.nodejs_24}/bin/npx";
    #   args    = [ "-y" "tritlo/lsp-mcp" "lua" "/absolute/path/to/roblox-lsp" "--stdio" ];
    #   port    = 11449;
    # };
  };

  #################################################
  # Activation & systemd bits unchanged
  #################################################
  home.activation.setupClaudeMcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${registerScript}
  '';

  systemd.user.services.mcp-claude-register = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Register MCP servers for Claude CLI (idempotent)";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${registerScript}";
      Environment = [
        "PATH=/etc/profiles/per-user/%u/bin:%h/.nix-profile/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gawk}/bin:${pkgs.jq}/bin"
      ];
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
