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
          # Binary configuration
          # By default, Zed will try to find rust-analyzer in $PATH
          # If not found, it will install its own stable version
          binary = {
            path = "rust-analyzer";
            # Set to true to disable Zed from looking for system rust-analyzer
            # ignore_system_version = false;
          };

          # Enable LSP tasks (rust-analyzer extension for file-related tasks)
          enable_lsp_tasks = true;

          # rust-analyzer initialization options
          initialization_options = {
            # Inlay hints configuration
            inlayHints = {
              maxLength = null; # null means no limit
              lifetimeElisionHints = {
                enable = "skip_trivial";
                useParameterNames = true;
              };
              closureReturnTypeHints = {
                enable = "always";
              };
            };

            # Target directory configuration
            # Set to true to use target/rust-analyzer, or use a string for custom path
            rust = {
              analyzerTargetDir = true;
            };

            # Cargo configuration
            cargo = {
              # Pass --all-targets to cargo invocation
              allTargets = true;
              # Use --workspace instead of -p <package>
              # Set to false to check only current package
              # workspace = true; # Default is true
            };

            # Check configuration
            check = {
              # Whether --workspace should be passed to cargo check
              # If false, -p <package> will be passed instead
              workspace = true;
            };

            # Diagnostics configuration
            diagnostics = {
              # Enable experimental diagnostics from rust-analyzer
              # These provide more cargo-less diagnostics but may include false-positives
              experimental = {
                enable = false; # Set to true if you want more comprehensive diagnostics
              };
            };

            # Check on save (default: true)
            # Set to false to disable automatic cargo check on save
            # Useful for large projects where checking is expensive
            checkOnSave = true;

            # Completion configuration with snippets
            completion = {
              snippets = {
                custom = {
                  Arc_new = {
                    postfix = "arc";
                    body = [''Arc::new(''${receiver})''];
                    requires = "std::sync::Arc";
                    scope = "expr";
                  };
                  Some = {
                    postfix = "some";
                    body = [''Some(''${receiver})''];
                    scope = "expr";
                  };
                  Ok = {
                    postfix = "ok";
                    body = [''Ok(''${receiver})''];
                    scope = "expr";
                  };
                  Rc_new = {
                    postfix = "rc";
                    body = [''Rc::new(''${receiver})''];
                    requires = "std::rc::Rc";
                    scope = "expr";
                  };
                  Box_pin = {
                    postfix = "boxpin";
                    body = [''Box::pin(''${receiver})''];
                    requires = "std::boxed::Box";
                    scope = "expr";
                  };
                  vec = {
                    postfix = "vec";
                    body = [''vec![''${receiver}]''];
                    description = "vec![]";
                    scope = "expr";
                  };
                };
              };
            };
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

      # External Agent Servers
      agent_servers = {
        "Cursor Agent" = {
          command = "npx";
          args = ["-y" "cursor-agent-acp"];
          env = {};
        };
      };
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
