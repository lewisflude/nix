# OpenAI Codex CLI configuration
{ config, ... }:
let
  inherit (config) trustedDirs aiCli;
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
      inherit (config.home) homeDirectory;

      mcpServers = aiCli.mcpServers pkgs osConfig // {
        context7 = (aiCli.mcpServers pkgs osConfig).context7 // {
          supports_parallel_tool_calls = true;
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

        features.hooks = true;

        mcp_servers = mcpServers;
      };
    in
    {
      home.packages = [
        pkgs.codex
        pkgs.remarshal
      ];

      home.sessionVariables = {
        CODEX_DISABLE_AUTOUPDATER = "1";
      };

      # Shared prompt body, also used by the Claude Code command
      # (modules/claude-code.nix). Only the frontmatter is per-consumer.
      home.file.".codex/skills/organize-samples/SKILL.md".text = ''
        ---
        name: organize-samples
        description: Use when the user asks to organize, organise, tidy, sort, classify, or move samples in ~/Music/samples, especially after music-production torrents land. Surveys the sample library, proposes a taxonomy, and moves items only after confirmation.
        metadata:
          short-description: Organize ~/Music/samples safely
        ---

      ''
      + builtins.readFile ../pkgs/prompts/organize-samples.md;

      programs.zsh.initContent = lib.mkIf config.programs.zsh.enable (
        lib.mkAfter (
          aiCli.mkTrustedWrapper {
            cmd = "codex";
            trustedFlag = "--profile trusted";
            inherit trustedDirs;
          }
          + ''
            if command -v codex >/dev/null 2>&1; then
              source <(command codex completion zsh)
            fi
          ''
        )
      );

      home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        aiCli.mkJsonMergeActivation pkgs {
          format = "toml";
          path = "${homeDirectory}/.codex/config.toml";
          desired = codexConfig;
        }
      );

      home.activation.codexConfigCleanup =
        let
          trustedDirArgs = lib.escapeShellArgs resolvedTrustedDirs;
        in
        lib.hm.dag.entryAfter [ "codexConfig" ] ''
          cleanup_codex_config() {
            local config_file=$1
            local jq_filter=$2
            local existing_json cleaned_json cleaned_toml

            existing_json=$(${pkgs.coreutils}/bin/mktemp)
            cleaned_json=$(${pkgs.coreutils}/bin/mktemp)
            cleaned_toml=$(${pkgs.coreutils}/bin/mktemp)

            if [ -s "$config_file" ]; then
              if ${pkgs.remarshal}/bin/remarshal -f toml -t json "$config_file" "$existing_json"; then
                ${pkgs.jq}/bin/jq "$jq_filter" "$existing_json" > "$cleaned_json"
                ${pkgs.remarshal}/bin/remarshal -f json -t toml "$cleaned_json" "$cleaned_toml"
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$cleaned_toml" "$config_file"
              else
                echo "warning: failed to parse $config_file during Codex cleanup; leaving it unchanged" >&2
              fi
            fi

            $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$existing_json" "$cleaned_json" "$cleaned_toml"
          }

          repair_codex_hooks_json() {
            local hooks_file=$1
            local stale_hooks=${lib.escapeShellArg "${homeDirectory}/Code/Tunnels/.codex/hooks"}
            local hooks_dir tmp

            hooks_dir="$(${pkgs.coreutils}/bin/dirname "$hooks_file")/hooks"
            [ -s "$hooks_file" ] || return 0
            [ -d "$hooks_dir" ] || return 0

            tmp=$(${pkgs.coreutils}/bin/mktemp)
            if ${pkgs.jq}/bin/jq --arg stale "$stale_hooks" --arg hooks_dir "$hooks_dir" '
              def replace_stale_hook_path:
                if type == "string" then split($stale) | join($hooks_dir) else . end;
              walk(if type == "object" and has("command") then .command |= replace_stale_hook_path else . end)
            ' "$hooks_file" > "$tmp"; then
              if ! ${pkgs.diffutils}/bin/cmp -s "$hooks_file" "$tmp"; then
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$tmp" "$hooks_file"
              else
                $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$tmp"
              fi
            else
              echo "warning: failed to parse $hooks_file during Codex hook repair; leaving it unchanged" >&2
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$tmp"
            fi
          }

          GLOBAL_CODEX_CLEANUP='
            del(.features.codex_hooks)
            | del(.mcp_servers."sequential-thinking")
            | del(.mcp_servers.time)
            | del(.mcp_servers.git.args)
            | del(.mcp_servers.nixos.args)
            | .features.hooks = true
          '
          PROJECT_CODEX_CLEANUP='
            if ((.features? | type == "object") and (.features | has("codex_hooks"))) then
              .features.hooks = .features.codex_hooks
              | del(.features.codex_hooks)
            else
              .
            end
          '

          cleanup_codex_config ${lib.escapeShellArg "${homeDirectory}/.codex/config.toml"} "$GLOBAL_CODEX_CLEANUP"

          for trusted_dir in ${trustedDirArgs}; do
            if [ -d "$trusted_dir" ]; then
              ${pkgs.findutils}/bin/find "$trusted_dir" -maxdepth 4 -path '*/.codex/config.toml' -type f 2>/dev/null | while IFS= read -r project_config; do
                cleanup_codex_config "$project_config" "$PROJECT_CODEX_CLEANUP"
              done
              ${pkgs.findutils}/bin/find "$trusted_dir" -maxdepth 4 -path '*/.codex/hooks.json' -type f 2>/dev/null | while IFS= read -r project_hooks; do
                repair_codex_hooks_json "$project_hooks"
              done
            fi
          done
        '';
    };
}
