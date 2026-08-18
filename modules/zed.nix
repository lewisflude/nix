# Zed Editor - Dendritic Pattern
# Fast, collaborative code editor
_: {
  flake.modules.homeManager.zed =
    _:
    let
      # Format JS/TS/JSON with Biome (matches the pkgs.biome toolchain).
      # Biome's LSP only attaches when a project has a biome.json, so this
      # is a no-op in projects that don't use Biome.
      biomeFormat = {
        formatter = [
          {
            code_actions = {
              "source.organizeImports.biome" = true;
            };
          }
          {
            language_server = {
              name = "biome";
            };
          }
        ];
        format_on_save = "on";
      };
    in
    {
      programs.zed-editor = {
        enable = true;
        package = null;

        # Manage settings.json declaratively as a store symlink. Do NOT set
        # this to true: mutableUserSettings freezes settings.json on first
        # write, so later Nix changes are silently ignored AND any pinned LSP
        # store paths break the moment they're garbage-collected. Let Zed
        # auto-manage the language-server binaries instead of pinning them.
        mutableUserSettings = false;

        userSettings = {
          ui_font_size = 14;
          ui_font_family = "Iosevka Nerd Font Mono";
          buffer_font_size = 12;
          buffer_font_family = "Iosevka Nerd Font Mono";

          telemetry = {
            metrics = false;
            diagnostics = false;
          };

          # Panels (theme is owned by the signal-nix Zed module).
          project_panel.dock = "left";
          outline_panel.dock = "left";
          collaboration_panel.dock = "left";
          git_panel.dock = "left";

          agent = {
            dock = "right";
            default_profile = "ask";
            default_model = {
              provider = "anthropic";
              model = "claude-sonnet-4-5-latest";
            };
            tool_permissions = {
              default = "allow";
            };
            favorite_models = [ ];
            model_parameters = [ ];
          };

          languages = {
            Nix = {
              language_servers = [ "nixd" ];
              formatter = {
                external = {
                  command = "nixfmt";
                };
              };
            };
            CSS = {
              language_servers = [
                "tailwindcss-intellisense-css"
                "!vscode-css-language-server"
                "..."
              ];
            };
            JavaScript = biomeFormat;
            TypeScript = biomeFormat;
            TSX = biomeFormat;
            JSON = biomeFormat;
            JSONC = biomeFormat;
            Python = {
              format_on_save = "on";
              formatter = {
                external = {
                  command = "ruff";
                  arguments = [
                    "format"
                    "--stdin-filename"
                    "{buffer_path}"
                  ];
                };
              };
              language_servers = [
                "basedpyright"
                "ruff"
              ];
            };
            Rust = {
              format_on_save = "on";
              formatter = "language_server";
            };
          };

          lsp = {
            nixd = {
              initialization_options = {
                formatting = {
                  command = [ "nixfmt" ];
                };
              };
            };
            rust-analyzer = {
              initialization_options = {
                check = {
                  command = "clippy";
                };
              };
            };
            tailwindcss-language-server = {
              settings = {
                # Detect utility classes inside helper function calls, e.g. cn("...")
                classFunctions = [
                  "cva"
                  "cx"
                  "clsx"
                  "cn"
                  "tw"
                  "twMerge"
                  "twJoin"
                ];
                # Detect classes in these attributes across frameworks
                # (class:list = Astro/Svelte, classList = Solid)
                classAttributes = [
                  "class"
                  "className"
                  "ngClass"
                  "class:list"
                  "classList"
                ];
                experimental = {
                  # classFunctions matches calls; these cover tagged-template
                  # literals like tw`...` and tw.div`...` which calls don't.
                  classRegex = [
                    "tw`([^`]*)"
                    "tw\\.[a-z-]+`([^`]*)"
                  ];
                };
              };
            };
          };
        };
      };
    };

  flake.modules.darwin.zed = _: {
    homebrew.casks = [ "zed" ];
  };
}
