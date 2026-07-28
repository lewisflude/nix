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

        mutableUserSettings = true;

        userSettings = {
          ui_font_size = 14;
          ui_font_family = "Iosevka Nerd Font Mono";
          buffer_font_size = 12;
          buffer_font_family = "Iosevka Nerd Font Mono";

          telemetry = {
            metrics = false;
            diagnostics = false;
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
          };

          lsp = {
            nixd = {
              initialization_options = {
                formatting = {
                  command = [ "nixfmt" ];
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
