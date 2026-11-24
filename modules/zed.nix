# Zed Editor - Dendritic Pattern
# Fast, collaborative code editor
_: {
  flake.modules.homeManager.zed =
    { lib, pkgs, ... }:
    let
      # Format JS/TS/JSON with Biome (matches the pkgs.biome toolchain).
      # Biome's LSP only attaches when a project has a biome.json, so this
      # is a no-op in projects that don't use Biome.
      biomeFormat = {
        formatter = [
          {
            code_action = "source.organizeImports.biome";
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
      # Zed does not download nixd itself; it must be on PATH.
      home.packages = [ pkgs.nixd ];

      programs.zed-editor = {
        enable = true;
        package = null;

        # Manage settings.json declaratively as a store symlink. Do NOT set
        # this to true: mutableUserSettings freezes settings.json on first
        # write, so later Nix changes are silently ignored AND any pinned LSP
        # store paths break the moment they're garbage-collected. Let Zed
        # auto-manage the language-server binaries instead of pinning them.
        mutableUserSettings = false;

        extensions = [
          "astro"
          "biome"
          "dockerfile"
          "html"
          "nix"
          "toml"
          "wgsl"
        ];

        userSettings = {
          # signal-nix installs only the theme variant for its configured mode
          # (dark), but sets mode = "system". Pin it so macOS light appearance
          # doesn't select the uninstalled "Signal Light".
          theme.mode = lib.mkForce "dark";

          ui_font_size = 14;
          ui_font_family = "Iosevka Nerd Font Mono";
          buffer_font_size = 14;
          buffer_font_family = "Iosevka Nerd Font Mono";
          buffer_font_features = {
            calt = true;
            liga = true;
            dlig = true;
          };

          # Editing - mirrors helix.nix where Zed has an equivalent.
          autosave = "on_focus_change";
          format_on_save = "on";
          soft_wrap = "editor_width";
          relative_line_numbers = "enabled";
          vertical_scroll_margin = 8;
          wrap_guides = [
            80
            120
          ];
          sticky_scroll.enabled = true;
          inlay_hints.enabled = true;
          diagnostics.inline = {
            enabled = true;
            max_severity = "error";
          };

          tabs = {
            file_icons = true;
            git_status = true;
            show_diagnostics = "errors";
          };

          terminal.font_size = 14;

          telemetry = {
            metrics = false;
            diagnostics = false;
          };

          # Panels (theme colours are owned by the signal-nix Zed module).
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
              # Ruff's LSP, which Zed installs itself; there is no ruff on PATH.
              formatter.language_server.name = "ruff";
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
