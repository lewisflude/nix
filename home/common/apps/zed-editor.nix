{ lib, ... }:
let
  languageConfig = import ./zed-editor-languages.nix { inherit lib; };
  lspConfig = import ./zed-editor-lsp.nix { inherit lib; };
in
{
  programs.zed-editor = {
    enable = true;

    userSettings = {

      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      features = {
        edit_prediction_provider = "copilot";
      };

      # Theme configuration moved to theming system (home/common/theming/applications/zed.nix)
      # Enable via: host.features.desktop.scientificTheme.enable = true;

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
        livelove = true;
        markdown-oxide = true;
        nix = true;
        sql = true;
        ssh-config = true;
        terraform = true;
        toml = true;
        yaml = true;
      };

      inherit (languageConfig) languages;
    };

    themes = {

    };
  };
}
