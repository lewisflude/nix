# Shared helpers for AI CLI modules (claude-code, codex, gemini-cli).
# Exposed as top-level `config.aiCli`. Consumers should merge their own
# additions onto the values returned here rather than redefining them.
{ lib, ... }:
let
  secretAvailable =
    osConfig: name: osConfig ? sops && osConfig.sops ? secrets && osConfig.sops.secrets ? ${name};

  secretPath =
    osConfig: name: if secretAvailable osConfig name then osConfig.sops.secrets.${name}.path else "";

  mcpServers =
    pkgs: osConfig:
    {
      context7 = {
        url = "https://mcp.context7.com/mcp";
      };
      git = {
        command = "${pkgs.uv}/bin/uvx";
        args = [ "mcp-server-git" ];
      };
      sqlite = {
        command = "${pkgs.writeShellScript "mcp-sqlite" ''
          exec ${pkgs.uv}/bin/uvx mcp-server-sqlite --db-path "$HOME/.local/share/mcp/data.db" "$@"
        ''}";
      };
      playwright = {
        command = "${pkgs.writeShellScript "mcp-playwright" ''
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
        command = "${pkgs.writeShellScript "mcp-hass" ''
          export HOMEASSISTANT_URL="$(cat /run/secrets/HOME_ASSISTANT_BASE_URL)"
          export HOMEASSISTANT_TOKEN="$(cat /run/secrets/HOME_ASSISTANT_TOKEN)"
          exec ${pkgs.uv}/bin/uvx ha-mcp "$@"
        ''}";
      };
    }
    // lib.optionalAttrs (secretAvailable osConfig "GITHUB_TOKEN") {
      github = {
        command = "${pkgs.writeShellScript "mcp-github" ''
          export PATH="${pkgs.nodejs}/bin:$PATH"
          GITHUB_TOKEN="$(cat ${lib.escapeShellArg (secretPath osConfig "GITHUB_TOKEN")})"
          exec ${pkgs.nodejs}/bin/npx -y mcp-remote https://api.githubcopilot.com/mcp/ \
            --header "Authorization: Bearer $GITHUB_TOKEN" "$@"
        ''}";
      };
    };

  mkTrustedWrapper =
    {
      cmd,
      trustedFlag,
      trustedDirs,
    }:
    let
      pattern = lib.concatMapStringsSep "|" (d: "${d}|${d}/*") trustedDirs;
    in
    ''
      if command -v ${cmd} >/dev/null 2>&1; then
        ${cmd}() {
          case "$PWD" in
            ${pattern})
              command ${cmd} ${trustedFlag} "$@"
              ;;
            *)
              command ${cmd} "$@"
              ;;
          esac
        }
      fi
    '';

  mkJsonMergeActivation =
    pkgs:
    {
      format,
      path,
      desired,
    }:
    let
      desiredJson = builtins.toJSON desired;
      needsRemarshal = format == "toml";
    in
    ''
      CONFIG_FILE=${lib.escapeShellArg path}
      CONFIG_DIR=$(${pkgs.coreutils}/bin/dirname "$CONFIG_FILE")
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$CONFIG_DIR"

      EXISTING_JSON=$(${pkgs.coreutils}/bin/mktemp)
      DESIRED_JSON=$(${pkgs.coreutils}/bin/mktemp)
      MERGED_JSON=$(${pkgs.coreutils}/bin/mktemp)
      ${lib.optionalString needsRemarshal "MERGED_OUT=$(${pkgs.coreutils}/bin/mktemp)"}

      if [ -s "$CONFIG_FILE" ]; then
        ${
          if needsRemarshal then
            ''
              if ! ${pkgs.remarshal}/bin/remarshal -f toml -t json "$CONFIG_FILE" "$EXISTING_JSON"; then
                echo "warning: failed to parse $CONFIG_FILE; preserving it and applying defaults to a fresh config" >&2
                ${pkgs.coreutils}/bin/cp "$CONFIG_FILE" "$CONFIG_FILE.hm-backup"
                ${pkgs.coreutils}/bin/printf '{}' > "$EXISTING_JSON"
              fi
            ''
          else
            ''
              if ! ${pkgs.jq}/bin/jq '.' "$CONFIG_FILE" > "$EXISTING_JSON" 2>/dev/null; then
                echo "warning: failed to parse $CONFIG_FILE; preserving it and applying defaults to a fresh config" >&2
                ${pkgs.coreutils}/bin/cp "$CONFIG_FILE" "$CONFIG_FILE.hm-backup"
                ${pkgs.coreutils}/bin/printf '{}' > "$EXISTING_JSON"
              fi
            ''
        }
      else
        ${pkgs.coreutils}/bin/printf '{}' > "$EXISTING_JSON"
      fi

      ${pkgs.coreutils}/bin/cat > "$DESIRED_JSON" <<'JSON'
      ${desiredJson}
      JSON

      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$EXISTING_JSON" "$DESIRED_JSON" > "$MERGED_JSON"
      ${
        if needsRemarshal then
          ''
            ${pkgs.remarshal}/bin/remarshal -f json -t toml "$MERGED_JSON" "$MERGED_OUT"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$MERGED_OUT" "$CONFIG_FILE"
          ''
        else
          ''
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$MERGED_JSON" "$CONFIG_FILE"
          ''
      }
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$EXISTING_JSON" "$DESIRED_JSON" ${
        lib.optionalString (!needsRemarshal) "\"$MERGED_JSON\""
      }
    '';
in
{
  options.aiCli = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    description = "Shared helpers for AI CLI modules (secrets, MCP servers, trusted-dir wrappers, activation snippets).";
    default = {
      inherit
        secretAvailable
        secretPath
        mcpServers
        mkTrustedWrapper
        mkJsonMergeActivation
        ;
    };
  };
}
