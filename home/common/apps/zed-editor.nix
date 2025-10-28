_: {
  programs.zed-editor = {
    enable = true;

    userSettings = {
      # Privacy & Telemetry
      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      # Features
      features = {
        copilot = true;
      };

      # Editor Appearance
      ui_font_size = 16;
      buffer_font_size = 16;

      # Editor Behavior
      vim_mode = false;
      autosave = "on_focus_change";
      format_on_save = "on";
      tab_size = 2;
      soft_wrap = "editor_width";

      # Inlay Hints (helpful for TypeScript, Rust, etc.)
      inlay_hints = {
        enabled = true;
      };

      # LSP Settings
      lsp = {
        rust-analyzer = {
          binary = {
            path = "rust-analyzer";
          };
        };
      };

      # Terminal
      terminal = {
        shell = {
          program = "zsh";
        };
        font_size = 14;
      };

      # Git Integration
      git = {
        git_gutter = "tracked_files";
        inline_blame = {
          enabled = true;
        };
      };

      # File Browser
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
    };

    extensions = [
      # Language Support - Based on your stack
      "nix" # Essential for your Nix configs
      "dockerfile" # You use Docker
      "docker-compose" # Likely use docker-compose
      "yaml" # You have yaml-language-server
      "toml" # Common in Rust/config files
      "sql" # You use PostgreSQL (pgcli)
      "json5" # Modern JSON variant

      # Development Tools
      "git-firefly" # Enhanced git (you use lazygit)
      "github-actions" # If you use GitHub CI/CD
      "env" # For .env files
      "markdown-oxide" # Better markdown support
      "just" # Justfile support (alternative to make)

      # Optional but useful
      "ssh-config" # SSH configuration files
      "html" # Web development
      "terraform" # If you use IaC with AWS
    ];

    # Enable custom themes
    # Each theme will be written to $XDG_CONFIG_HOME/zed/themes/theme-name.json
    themes = {
      # Add your custom themes here
      # Example:
      # my-theme = {
      #   name = "My Theme";
      #   appearance = "dark";
      #   style = {
      #     # Theme configuration
      #   };
      # };
    };
  };
}
