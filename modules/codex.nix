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

        features.hooks = true;

        mcp_servers = mcpServers;
      };

      # Codex >= 0.147 uses "profile v2": each profile lives in its own
      # $CODEX_HOME/<name>.config.toml, layered over config.toml. A legacy
      # [profiles.<name>] table (or a top-level `profile = ...` selector) in
      # config.toml is a hard error the moment `--profile` is passed.
      codexTrustedProfile = {
        approval_policy = "never";
        sandbox_mode = "workspace-write";
      };
    in
    {
      # pkgs.codex comes from programs.codex below; yj is used by the activation
      # scripts that merge/repair Codex's own TOML.
      home.packages = [ pkgs.yj ];

      programs.codex = {
        enable = true;
        package = pkgs.codex;

        # Deliberately NOT using `settings` or `enableMcpIntegration`.
        #
        # Both make `mergedSettings != { }`, which makes the module install
        # ~/.codex/config.toml as a read-only /nix/store symlink. Codex rewrites
        # that file at runtime (model selection, [tui.*] state, per-tool approval
        # decisions, plugin enablement), so it must stay a real, writable file —
        # see home.activation.codexConfig below and the rationale on
        # aiCli.mkJsonMergeActivation.
        #
        # Files Codex does NOT write are safe to let Home Manager own, and are
        # declared here rather than via home.file.
        settings = { };
        enableMcpIntegration = false;

        # Codex only loads a skill when the skill *directory* is the symlink.
        # A symlinked SKILL.md inside a real directory — what `home.file` produces
        # — is silently ignored (openai/codex#10470). This option generates the
        # supported shape.
        skills.organize-samples = ''
          ---
          name: organize-samples
          description: Use when the user asks to organize, organise, tidy, sort, classify, or move samples in ~/Music/samples, especially after music-production torrents land. Surveys the sample library, proposes a taxonomy, and moves items only after confirmation.
          metadata:
            short-description: Organize ~/Music/samples safely
          ---

        ''
        + builtins.readFile ../pkgs/prompts/organize-samples.md;

        # Profile v2: written to ~/.codex/trusted.config.toml. Codex reads these
        # but does not write them, so a store symlink is safe here.
        profiles.trusted = codexTrustedProfile;
      };

      home.sessionVariables = {
        CODEX_DISABLE_AUTOUPDATER = "1";
      };

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

      # Move any legacy [profiles.<name>] table out of config.toml and into
      # <name>.config.toml before the cleanup below deletes it, so hand-tuned
      # profile keys survive the migration.
      home.activation.codexProfileMigration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        legacy_config=${lib.escapeShellArg "${homeDirectory}/.codex/config.toml"}
        [ -s "$legacy_config" ] || legacy_config=""

        if [ -n "$legacy_config" ]; then
          legacy_json=$(${pkgs.coreutils}/bin/mktemp)
          if ${pkgs.yj}/bin/yj -tj < "$legacy_config" > "$legacy_json"; then
            ${pkgs.jq}/bin/jq -r '.profiles // {} | keys[]' "$legacy_json" | while IFS= read -r profile_name; do
              profile_file=${lib.escapeShellArg "${homeDirectory}/.codex"}/"$profile_name".config.toml

              # Profiles declared in programs.codex.profiles are Home Manager
              # store symlinks. `mv`-ing over one replaces it with a real file,
              # and the next switch then aborts with "in the way". Codex keeps
              # re-adding [profiles.trusted] to config.toml, so this loop would
              # hit that case on most activations.
              case " ${lib.concatStringsSep " " (lib.attrNames config.programs.codex.profiles)} " in
                *" $profile_name "*)
                  echo "note: profile '$profile_name' is managed by Home Manager; dropping the legacy copy from config.toml without migrating it" >&2
                  continue
                  ;;
              esac

              profile_existing=$(${pkgs.coreutils}/bin/mktemp)
              profile_merged=$(${pkgs.coreutils}/bin/mktemp)
              profile_toml=$(${pkgs.coreutils}/bin/mktemp)

              if [ -s "$profile_file" ] && ${pkgs.yj}/bin/yj -tj < "$profile_file" > "$profile_existing"; then
                :
              else
                ${pkgs.coreutils}/bin/printf '{}' > "$profile_existing"
              fi

              # Legacy keys lose to whatever the profile file already declares.
              ${pkgs.jq}/bin/jq --arg name "$profile_name" \
                --slurpfile existing "$profile_existing" \
                '(.profiles[$name] // {}) * $existing[0]' "$legacy_json" > "$profile_merged"
              ${pkgs.yj}/bin/yj -jt < "$profile_merged" > "$profile_toml"
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$profile_toml" "$profile_file"

              $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$profile_existing" "$profile_merged" "$profile_toml"
            done
          else
            echo "warning: failed to parse $legacy_config during Codex profile migration; leaving it unchanged" >&2
          fi
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$legacy_json"
        fi
      '';

      home.activation.codexConfigCleanup =
        let
          trustedDirArgs = lib.escapeShellArgs resolvedTrustedDirs;
        in
        lib.hm.dag.entryAfter [ "codexConfig" "codexProfileMigration" ] ''
          cleanup_codex_config() {
            local config_file=$1
            local jq_filter=$2
            local existing_json cleaned_json cleaned_toml

            existing_json=$(${pkgs.coreutils}/bin/mktemp)
            cleaned_json=$(${pkgs.coreutils}/bin/mktemp)
            cleaned_toml=$(${pkgs.coreutils}/bin/mktemp)

            if [ -s "$config_file" ]; then
              if ${pkgs.yj}/bin/yj -tj < "$config_file" > "$existing_json"; then
                ${pkgs.jq}/bin/jq "$jq_filter" "$existing_json" > "$cleaned_json"
                ${pkgs.yj}/bin/yj -jt < "$cleaned_json" > "$cleaned_toml"
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
            | del(.profile)
            | del(.profiles)
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
