{
  pkgs,
  config,
  lib,
  ...
}:

let
  inherit (lib)
    concatStringsSep
    mapAttrsToList
    escapeShellArg
    optionalString
    ;

  uvx = "${pkgs.uv}/bin/uvx";
  py = "${pkgs.python3}/bin/python3";

  # Wrapper as a first-class binary in the store (shellcheck-clean)
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
      exec ${uvx} --from kagimcp==0.1.* kagimcp "$@"
    '';
  };

  # ----- helpers for activation script generation -----
  mkEnvExports =
    envAttrs:
    concatStringsSep " " (
      mapAttrsToList (k: v: "export ${escapeShellArg k}=${escapeShellArg v};") envAttrs
    );

  mkAddCmd =
    name: serverCfg:
    let
      envExports = mkEnvExports (serverCfg.env or { });
      command = escapeShellArg serverCfg.command;
      argsStr = concatStringsSep " " (map escapeShellArg (serverCfg.args or [ ]));
      argsPart = optionalString (argsStr != "") "-- ${argsStr}";
    in
    ''
      # ${name}
      ${envExports} claude mcp add ${escapeShellArg name} -s user ${command} ${argsPart}
    '';

  declaredNames = mapAttrsToList (n: _: escapeShellArg n) config.services.mcp.servers;
  addCommands = concatStringsSep "\n" (mapAttrsToList mkAddCmd config.services.mcp.servers);
in
{
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
  ];

  ############################
  # MCP (consumer) declaration
  ############################
  services.mcp.enable = true;

  # Cursor gets declarative JSON; Claude Code is driven via CLI
  services.mcp.targets = {
    cursor = {
      directory = "${config.home.homeDirectory}/.cursor";
      fileName = "mcp.json";
    };
    # Harmless if unused by Claude Code
    claude-code = {
      directory = "${config.home.homeDirectory}/.config/claude";
      fileName = "claude_desktop_config.json";
    };
  };

  # Servers: stable NPX, pinned uvx, explicit Python for script servers
  services.mcp.servers = {
    everything = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-everything"
      ];
      port = 11446;
    };

    github = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-github"
      ];
      port = 11434;
    };

    memory = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-memory"
      ];
      port = 11436;
    };

    sequential-thinking = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-sequential-thinking"
      ];
      port = 11437;
    };

    general-filesystem = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem"
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
        "@modelcontextprotocol/server-filesystem"
        "${config.home.homeDirectory}/Code/love2d-projects"
        "${config.home.homeDirectory}/.local/share/love"
      ];
      port = 11441;
    };

    nx = {
      command = "${pkgs.nodejs_24}/bin/npx";
      args = [
        "nx-mcp@latest"
        "${config.home.homeDirectory}/Code/dex-web"
      ];
      port = 11435;
    };

    # Kagi via wrapper
    kagi = {
      command = "${kagiWrapper}/bin/kagi-mcp-wrapper";
      args = [ ];
      port = 11431;
    };

    # uvx servers (pinned) + explicit Python for script servers
    fetch = {
      command = uvx;
      args = [
        "--from"
        "mcp-server-fetch==0.1.*"
        "mcp-server-fetch"
      ];
      port = 11432;
    };

    git = {
      command = uvx;
      args = [
        "--from"
        "mcp-server-git==0.1.*"
        "mcp-server-git"
        "--repository"
        "${config.home.homeDirectory}/Code/dex-web"
      ];
      port = 11433;
    };

    time = {
      command = uvx;
      args = [
        "--from"
        "mcp-server-time==0.1.*"
        "mcp-server-time"
      ];
      port = 11445;
    };

    love2d-api = {
      command = uvx;
      args = [
        "--python"
        "${py}"
        "--with"
        "mcp"
        "--with"
        "requests"
        "python"
        "${config.home.homeDirectory}/.config/nix/mcp-servers/love2d-api.py"
      ];
      port = 11440;
    };

    love2d-docs = {
      command = uvx;
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
        "${../../scripts/mcp_love2d_docs.py}"
      ];
      port = 11443;
    };

    lua-docs = {
      command = uvx;
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
        "${../../scripts/mcp_lua_docs.py}"
      ];
      port = 11444;
    };
  };

  #################################################
  # Idempotent, health-gated CLI registration step
  #################################################
  # Set MCP_DRY_RUN=1 to see actions without changing state.
  home.activation.setupClaudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
    ${pkgs.writeShellScript "mcp-register-declared" ''
            set -euo pipefail
            if [ "''${MCP_DRY_RUN:-0}" = "1" ]; then
              echo "[mcp] DRY-RUN: would run:"
              cat <<'ADD_CMDS'
      '${addCommands}'
      ADD_CMDS
            else
              while IFS= read -r line; do
                [ -z "$line" ] && continue
                echo "[mcp] -> $line"
                if ! bash -c "$line" >/dev/null 2>&1; then
                  echo "[mcp] WARN: add failed, will evaluate health after list"
                fi
              done <<'ADD_CMDS'
      '${addCommands}'
      ADD_CMDS
            fi
    ''}

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

    echo "[mcp] Final state:"
    claude mcp list || true
    echo "[mcp] Claude MCP registration complete."
  '';
}
