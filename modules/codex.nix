# OpenAI Codex CLI configuration
{ config, lib, ... }:
let
  inherit (config) trustedDirs;
  trustedCasePattern = lib.concatMapStringsSep "|" (d: "${d}|${d}/*") trustedDirs;
in
{
  flake.modules.homeManager.codex =
    {
      lib,
      pkgs,
      config,
      osConfig ? { },
      ...
    }:
    let
      secretAvailable =
        name: osConfig ? sops && osConfig.sops ? secrets && osConfig.sops.secrets ? ${name};
      secretPath = name: if secretAvailable name then osConfig.sops.secrets.${name}.path else "";

      inherit (config.home) homeDirectory;

      mcpServers = {
        context7 = {
          url = "https://mcp.context7.com/mcp";
          supports_parallel_tool_calls = true;
        };
        git = {
          command = "${pkgs.uv}/bin/uvx";
          args = [ "mcp-server-git" ];
        };
        sqlite = {
          command = "${pkgs.writeShellScript "codex-mcp-sqlite" ''
            exec ${pkgs.uv}/bin/uvx mcp-server-sqlite --db-path "$HOME/.local/share/mcp/data.db" "$@"
          ''}";
        };
        playwright = {
          command = "${pkgs.writeShellScript "codex-mcp-playwright" ''
            export PATH="${pkgs.nodejs}/bin:$PATH"
            exec ${pkgs.nodejs}/bin/npx -y @playwright/mcp@0.0.68 "$@"
          ''}";
        };
        nixos = {
          command = "${pkgs.uv}/bin/uvx";
          args = [ "mcp-nixos" ];
        };
        figma = {
          url = "https://mcp.figma.com/mcp";
        };
      }
      // lib.optionalAttrs pkgs.stdenv.isLinux {
        hass = {
          command = "${pkgs.writeShellScript "codex-mcp-hass" ''
            export HOMEASSISTANT_URL="$(cat /run/secrets/HOME_ASSISTANT_BASE_URL)"
            export HOMEASSISTANT_TOKEN="$(cat /run/secrets/HOME_ASSISTANT_TOKEN)"
            exec ${pkgs.uv}/bin/uvx ha-mcp "$@"
          ''}";
        };
      }
      // lib.optionalAttrs (secretAvailable "GITHUB_TOKEN") {
        github = {
          command = "${pkgs.writeShellScript "codex-mcp-github" ''
            export PATH="${pkgs.nodejs}/bin:$PATH"
            GITHUB_TOKEN="$(cat ${lib.escapeShellArg (secretPath "GITHUB_TOKEN")})"
            exec ${pkgs.nodejs}/bin/npx -y mcp-remote https://api.githubcopilot.com/mcp/ \
              --header "Authorization: Bearer $GITHUB_TOKEN" "$@"
          ''}";
        };
      };

      resolvedTrustedDirs = map (d: lib.replaceStrings [ "$HOME" ] [ homeDirectory ] d) trustedDirs;

      codexConfig = {
        model = "gpt-5.5";
        model_reasoning_effort = "medium";
        approval_policy = "on-request";
        sandbox_mode = "workspace-write";
        web_search = "live";

        projects = lib.listToAttrs (
          map (d: {
            name = d;
            value.trust_level = "trusted";
          }) resolvedTrustedDirs
        );

        profiles.trusted = {
          approval_policy = "never";
          sandbox_mode = "workspace-write";
        };

        mcp_servers = mcpServers;
      };

      codexConfigJson = builtins.toJSON codexConfig;
    in
    {
      home.packages = [
        pkgs.codex
        pkgs.remarshal
      ];

      home.sessionVariables = {
        CODEX_DISABLE_AUTOUPDATER = "1";
      };

      programs.zsh.initContent = lib.mkIf config.programs.zsh.enable (
        lib.mkAfter ''
          if command -v codex >/dev/null 2>&1; then
            codex() {
              case "$PWD" in
                ${trustedCasePattern})
                  command codex --profile trusted "$@"
                  ;;
                *)
                  command codex "$@"
                  ;;
              esac
            }
            source <(command codex completion zsh)
          fi
        ''
      );

      home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        CONFIG_DIR="$HOME/.codex"
        CONFIG_FILE="$CONFIG_DIR/config.toml"

        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$CONFIG_DIR"

        EXISTING_JSON=$(${pkgs.coreutils}/bin/mktemp)
        DESIRED_JSON=$(${pkgs.coreutils}/bin/mktemp)
        MERGED_JSON=$(${pkgs.coreutils}/bin/mktemp)
        MERGED_TOML=$(${pkgs.coreutils}/bin/mktemp)

        if [ -s "$CONFIG_FILE" ]; then
          if ! ${pkgs.remarshal}/bin/remarshal -f toml -t json "$CONFIG_FILE" "$EXISTING_JSON"; then
            echo "warning: failed to parse $CONFIG_FILE; preserving it and applying Codex defaults to a fresh config" >&2
            ${pkgs.coreutils}/bin/cp "$CONFIG_FILE" "$CONFIG_FILE.hm-backup"
            ${pkgs.coreutils}/bin/printf '{}' > "$EXISTING_JSON"
          fi
        else
          ${pkgs.coreutils}/bin/printf '{}' > "$EXISTING_JSON"
        fi

        ${pkgs.coreutils}/bin/cat > "$DESIRED_JSON" <<'JSON'
        ${codexConfigJson}
        JSON

        ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$EXISTING_JSON" "$DESIRED_JSON" > "$MERGED_JSON"
        ${pkgs.remarshal}/bin/remarshal -f json -t toml "$MERGED_JSON" "$MERGED_TOML"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$MERGED_TOML" "$CONFIG_FILE"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$EXISTING_JSON" "$DESIRED_JSON" "$MERGED_JSON"
      '';
    };
}
