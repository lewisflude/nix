{ lib, ... }:
{
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
        edit_prediction_provider = "copilot"; # Options: "zed", "copilot", "supermaven", or "none"
      };

      # Theme
      theme = {
        dark = "Catppuccin Mocha";
        light = lib.mkForce "Catppuccin Latte";
      };
      icon_theme = "Catppuccin Mocha";

      # Editor Appearance
      ui_font_size = 16;
      buffer_font_size = 16;

      # Indent Guides (rainbow indentation for better code structure visibility)
      indent_guides = {
        enabled = true;
        coloring = "indent_aware";
      };

      # Editor Behavior
      vim_mode = false;
      autosave = "on_focus_change";
      format_on_save = "on";
      tab_size = 2;
      soft_wrap = "editor_width";

      # File Finder
      # Note: modal_width is not a valid setting in Zed
      file_finder = { };

      # Tabs (show only errors to reduce noise)
      tabs = {
        show_diagnostics = "errors";
        git_status = true; # Show git status in tabs
        file_icons = true; # Show file type icons in tabs
      };

      # Tab Bar
      tab_bar = {
        show_nav_history_buttons = false; # Hide navigation history buttons for cleaner UI
      };

      # Show whitespace only in selection (less noise)
      show_whitespaces = "selection";

      # Toolbar (minimal UI - hide elements we can access via command palette)
      toolbar = {
        breadcrumbs = false;
        quick_actions = false;
      };

      # Gutter settings
      gutter = {
        line_numbers = true;
        runnables = true;
        breakpoints = true;
        folds = true;
      };

      # Vertical scroll margin (keeps code from touching edges)
      vertical_scroll_margin = 6;

      # Inlay Hints (helpful for TypeScript, Rust, etc.)
      inlay_hints = {
        enabled = true;
      };

      # LSP Settings
      lsp = {
        nixd = {
          binary = {
            path_lookup = true;
          };
        };

        rust-analyzer = {
          initialization_options = {
            inlayHints = {
              maxLength = null;
              lifetimeElisionHints = {
                enable = "skip_trivial";
                useParameterNames = true;
              };
              closureReturnTypeHints = {
                enable = "always";
              };
            };
          };
        };

        # CSS Language Server (vscode-css-languageservice)
        css-language-server = {
          settings = {
            css = {
              validate = true;
            };
            scss = {
              validate = true;
            };
            less = {
              validate = true;
            };
          };
        };

        # Tailwind CSS Language Server
        tailwindcss-language-server = {
          settings = {
            # Class utility functions to be recognized
            classFunctions = [
              "cva"
              "cx"
              "clsx"
              "cn"
              "classnames"
            ];
            # Experimental class detection patterns
            experimental = {
              classRegex = [
                "[cls|className]\\s\\:\\=\\s\"([^\"]*)\""
                "class:\\s*\"([^\"]*)\""
                "className:\\s*\"([^\"]*)\""
              ];
            };
          };
        };

        # TypeScript/JavaScript Language Server (vtsls - default)
        vtsls = {
          settings = {
            # TypeScript settings
            typescript = {
              tsserver = {
                maxTsServerMemory = 16384; # 16 GiB for large projects
              };
              inlayHints = {
                parameterNames = {
                  enabled = "all";
                  suppressWhenArgumentMatchesName = false;
                };
                parameterTypes = {
                  enabled = true;
                };
                variableTypes = {
                  enabled = true;
                  suppressWhenTypeMatchesName = true;
                };
                propertyDeclarationTypes = {
                  enabled = true;
                };
                functionLikeReturnTypes = {
                  enabled = true;
                };
                enumMemberValues = {
                  enabled = true;
                };
              };
            };
            # JavaScript settings
            javascript = {
              tsserver = {
                maxTsServerMemory = 16384; # 16 GiB for large projects
              };
              inlayHints = {
                parameterNames = {
                  enabled = "all";
                  suppressWhenArgumentMatchesName = false;
                };
                parameterTypes = {
                  enabled = true;
                };
                variableTypes = {
                  enabled = true;
                  suppressWhenTypeMatchesName = true;
                };
                propertyDeclarationTypes = {
                  enabled = true;
                };
                functionLikeReturnTypes = {
                  enabled = true;
                };
                enumMemberValues = {
                  enabled = true;
                };
              };
            };
          };
        };

        # HTML Language Server
        vscode-html-language-server = {
          settings = {
            html = {
              format = {
                # Indent under <html> and <head>
                indentInnerHtml = true;
                # Disable formatting inside certain tags
                contentUnformatted = "svg,script";
                # Add extra newlines before certain tags
                extraLiners = "div,p,head,body,html";
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
        # Set Zed as git commit editor
        env = {
          EDITOR = "zed --wait";
        };
      };

      # Git Integration
      git = {
        git_gutter = "tracked_files";
        inline_blame = {
          enabled = true;
        };
      };

      # File Type Associations
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

      # AI/Assistant Configuration
      # Note: Direct assistant configuration is not supported in current Zed versions.
      # AI features are configured through language_models and features.edit_prediction_provider

      # Language Model Providers (Ollama for local AI)
      language_models = {
        ollama = {
          api_url = "http://localhost:11434";
        };
      };

      # External Agent Servers
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

      # Auto-install extensions
      auto_install_extensions = {
        biome = true; # Biome formatter and linter (supports JS/TS/JSON/CSS/HTML and more)
        catppuccin-icons = true;
        docker-compose = true;
        dockerfile = true;
        env = true;
        git-firefly = true;
        github-actions = true;
        html = true;
        json5 = true;
        just = true;
        livelove = true; # LÖVE 2D LSP for live coding and live variable tracking
        markdown-oxide = true;
        nix = true;
        sql = true;
        ssh-config = true;
        terraform = true;
        toml = true;
        yaml = true;
      };

      # Language-specific settings
      languages = {
        JavaScript = {
          tab_size = 2; # Consistent indentation
          code_actions_on_format = {
            "source.fixAll.biome" = true; # Biome for linting and fixing
          };
          # Use Biome for formatting (fast, modern formatter)
          formatter = {
            language_server = {
              name = "biome";
            };
          };
        };
        TypeScript = {
          tab_size = 2; # Consistent indentation
          code_actions_on_format = {
            "source.fixAll.biome" = true; # Biome for linting and fixing
          };
          # Use Biome for formatting
          formatter = {
            language_server = {
              name = "biome";
            };
          };
          # Detailed inlay hints configuration
          inlay_hints = {
            enabled = true;
            show_parameter_hints = false; # Less noise when parameter names are obvious
            show_other_hints = true;
            show_type_hints = true;
          };
        };
        TSX = {
          tab_size = 2; # Consistent indentation
          code_actions_on_format = {
            "source.fixAll.biome" = true; # Biome for linting and fixing
          };
          # Use Biome for formatting
          formatter = {
            language_server = {
              name = "biome";
            };
          };
        };
        CSS = {
          tab_size = 2; # Consistent indentation
          code_actions_on_format = {
            "source.fixAll.biome" = true; # Biome for CSS formatting/linting
          };
          # Use Biome for CSS formatting
          formatter = {
            language_server = {
              name = "biome";
            };
          };
        };
        # SCSS requires an extension to be installed
        # Install the SCSS extension first, or remove this configuration
        HTML = {
          tab_size = 2; # Consistent indentation
          # Use Biome for HTML formatting
          formatter = {
            language_server = {
              name = "biome";
            };
          };
          format_on_save = "on";
        };
        JSON = {
          tab_size = 2; # Consistent indentation
          code_actions_on_format = {
            "source.fixAll.biome" = true; # Biome for JSON formatting/linting
          };
          # Use Biome for JSON formatting
          formatter = {
            language_server = {
              name = "biome";
            };
          };
        };
        JSONC = {
          tab_size = 2; # Consistent indentation
          code_actions_on_format = {
            "source.fixAll.biome" = true; # Biome for JSONC formatting/linting
          };
          # Use Biome for JSONC formatting
          formatter = {
            language_server = {
              name = "biome";
            };
          };
        };
        Markdown = {
          format_on_save = "on";
          # Keep trailing whitespace for Markdown <br /> conversion
          remove_trailing_whitespace_on_save = false;
        };
        Nix = {
          tab_size = 2;
          # Explicitly use nixd instead of nil
          language_servers = [ "nixd" ];
          format_on_save = "on";
        };
        Python = {
          tab_size = 4; # Python standard indentation
          # Use Ruff for formatting and linting (fast and modern)
          format_on_save = "on";
          formatter = {
            language_server = {
              name = "ruff";
            };
          };
          # Use both pyright (type checking) and ruff (formatting/linting)
          language_servers = [
            "pyright"
            "ruff"
          ];
          code_actions_on_format = {
            "source.organizeImports" = true; # Organize imports on save
            "source.fixAll.ruff" = true; # Apply Ruff fixes
          };
        };
      };
    };

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
