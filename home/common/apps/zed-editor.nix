{
  config,
  lib,
  pkgs,
  ...
}:
let
  languageConfig = import ./zed-editor-languages.nix { inherit lib; };
  lspConfig = import ./zed-editor-lsp.nix { inherit lib; };

  # Check if Signal theme is enabled
  signalThemeEnabled = config.theming.signal.enable or false;

  # Get Signal theme family if available (ThemeFamilyContent format)
  signalThemeFamily = config.theming.signal.applications.zed.themes or null;

  # Extract themes array from theme family
  signalThemesArray = if signalThemeFamily != null then signalThemeFamily.themes or [ ] else [ ];

  # Convert themes array to attribute set (Home Manager expects attrSet keyed by theme name)
  # Home Manager's zed-editor module expects: themes = { "Theme Name" = themeObject; ... }
  signalThemes = lib.listToAttrs (
    lib.map (theme: lib.nameValuePair (theme.name or "Unknown") theme) signalThemesArray
  );

  # Check if themes are actually available (non-empty and contain required themes)
  themesAvailable =
    signalThemeEnabled
    && signalThemeFamily != null
    && signalThemesArray != [ ]
    && signalThemes ? "Signal Dark"
    && signalThemes ? "Signal Light";

  # Get the raw theme mode (before resolution) to determine Zed's theme mode setting
  rawThemeMode = if signalThemeEnabled then (config.theming.signal.mode or "dark") else null;

  # Determine Zed's theme mode:
  # - "auto" -> "system" (let Zed follow system preference)
  # - "light" or "dark" -> use that mode directly
  zedThemeMode = if rawThemeMode == "auto" then "system" else rawThemeMode;
in
{
  programs.zed-editor = {
    # TEMPORARILY DISABLED: Build failing due to disk space (errno=28)
    # Re-enable after freeing disk space
    enable = false;

    # Add nixd to extraPackages so it's in PATH for language server
    extraPackages = [ pkgs.nixd ];

    # Make settings immutable to prevent merging with stale cached settings
    # This ensures our configuration is authoritative
    mutableUserSettings = false;

    userSettings = lib.mkMerge [
      {
        telemetry = {
          diagnostics = false;
          metrics = false;
        };

        features = {
          edit_prediction_provider = "copilot";
        };

        ui_font_size = 16;
        buffer_font_size = 16;

        indent_guides = {
          enabled = true;
          coloring = "indent_aware";
        };

        vim_mode = false;
        autosave = "on_focus_change";
        format_on_save = "on";
        tab_size = 2;
        soft_wrap = "editor_width";

        file_finder = { };

        tabs = {
          show_diagnostics = "errors";
          git_status = true;
          file_icons = true;
        };

        tab_bar = {
          show_nav_history_buttons = false;
        };

        show_whitespaces = "selection";

        toolbar = {
          breadcrumbs = false;
          quick_actions = false;
        };

        gutter = {
          line_numbers = true;
          runnables = true;
          breakpoints = true;
          folds = true;
        };

        vertical_scroll_margin = 6;

        inlay_hints = {
          enabled = true;
        };

        inherit (lspConfig) lsp;

        terminal = {
          shell = {
            program = "zsh";
          };
          font_size = 14;

          env = {
            EDITOR = "zed --wait";
          };
        };

        git = {
          git_gutter = "tracked_files";
          inline_blame = {
            enabled = true;
          };
        };

        file_types = {
          Dockerfile = [
            "Dockerfile"
            "Dockerfile.*"
          ];
          JSON = [
            "json"
            "jsonc"
            "*.code-snippets"
          ];
        };

        file_scan_exclusions = [
          "**/.git"
          "**/.svn"
          "**/.hg"
          "**/CVS"
          "**/.DS_Store"
          "**/Thumbs.db"
          "**/.classpath"
          "**/.settings"
          "**/node_modules"
          "**/.next"
          "**/dist"
          "**/build"
          "**/.turbo"
        ];

        language_models = {
          ollama = {
            api_url = "http://localhost:11434";
          };
        };

        agent_servers = {
          "Cursor Agent" = {
            command = "npx";
            args = [
              "-y"
              "cursor-agent-acp"
            ];
            env = { };
          };
        };

        auto_install_extensions = {
          biome = true;
          docker-compose = true;
          dockerfile = true;
          env = true;
          git-firefly = true;
          github-actions = true;
          html = true;
          json5 = true;
          just = true;
          # livelove removed: fails to install (Invalid gzip header error)
          markdown-oxide = true;
          nix = true;
          sql = true;
          ssh-config = true;
          terraform = true;
          toml = true;
          # yaml removed: fails to install (Invalid gzip header error)
        };

        inherit (languageConfig) languages;
      }
      # Set theme ONLY when themes are actually available
      # Use theme object format to support automatic light/dark switching
      (lib.mkIf themesAvailable {
        theme = {
          mode = zedThemeMode;
          light = "Signal Light";
          dark = "Signal Dark";
        };
      })
    ];

    # Don't use Home Manager's themes option - it writes individual theme files
    # Instead, we write a single theme family file below
  };

  # Write theme family file in ThemeFamilyContent format (single file with both variants)
  # Zed expects: { author, name, themes: [ThemeContent...] }
  home.file.".config/zed/themes/Signal.json" = lib.mkIf themesAvailable {
    text = builtins.toJSON signalThemeFamily;
    force = true; # Overwrite existing file
  };
}
