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

      home.file.".codex/prompts/organize-samples.md".text = ''
        ---
        description: Organise ~/Music/samples after new music-production torrents have landed. Surveys, proposes a taxonomy, and moves items with confirmation.
        argument-hint: [optional focus: drums|synths|loops|...]
        ---

        You are tidying the user's sample library at `~/Music/samples`. This folder is NFS-exported to Mercury (macOS) and consumed by Ableton Live, so the layout must stay stable and human-browsable.

        New content lands here automatically via qBittorrent's `music-production` category. Each completed torrent arrives as `~/Music/samples/<torrent-name>/`.

        ## Workflow

        1. **Survey.** List the top level of `~/Music/samples`. For each unorganised entry, note: name, size (`du -sh`), and a one-line guess at its type (drum kit, synth preset pack, loop pack, stems, multisample, etc.). Use `file` / extensions to inform the guess.
        2. **Propose a taxonomy.** Use or extend the user's existing folders. Prefer this baseline unless the user has diverged:
           - `drums/` - oneshots, kits, breaks
           - `loops/` - melodic/rhythmic loops
           - `synths/` - presets, patches, multisamples
           - `stems/` - song stems, acapellas
           - `fx/` - risers, impacts, foley, textures
           - `packs/` - commercial sample packs kept whole
        3. **Confirm before moving.** Present the proposed moves in a table (source -> destination) and wait for approval. Never move without confirmation.
        4. **Preserve structure.** If a torrent arrives as a well-structured sample pack (e.g. nested `Kicks/`, `Snares/`, `Presets/`), keep it whole under `packs/<pack-name>/`. Do not flatten commercial packs.
        5. **Move, never copy or delete.** Use `mv`. If a destination already exists, ask the user - do not overwrite.
        6. **Clean up empties.** After moves, `rmdir` empty source dirs (but never `rm -rf`).

        ## Guardrails

        - Treat anything ambiguous as a question for the user rather than a guess.
        - If `$ARGUMENTS` is set (e.g. `drums`), restrict the pass to items that look like that category.
        - Never touch files outside `~/Music/samples`.
        - Never delete. If something looks like junk (thumbnails, `.DS_Store`, torrent metadata), surface it and let the user decide.
        - Ableton references samples by absolute path - warn the user before moving anything that's already been dragged into a live project.
      '';

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
            fi
          done
        '';
    };
}
