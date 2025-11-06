{ lib, ... }:
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

      theme = {
        dark = "Catppuccin Mocha";
        light = lib.mkForce "Catppuccin Latte";
      };
      icon_theme = "Catppuccin Mocha";

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

        tailwindcss-language-server = {
          settings = {

            classFunctions = [
              "cva"
              "cx"
              "clsx"
              "cn"
              "classnames"
            ];

            experimental = {
              classRegex = [
                "[cls|className]\\s\\:\\=\\s\"([^\"]*)\""
                "class:\\s*\"([^\"]*)\""
                "className:\\s*\"([^\"]*)\""
              ];
            };
          };
        };

        vtsls = {
          settings = {

            typescript = {
              tsserver = {
                maxTsServerMemory = 16384;
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

            javascript = {
              tsserver = {
                maxTsServerMemory = 16384;
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

        vscode-html-language-server = {
          settings = {
            html = {
              format = {

                indentInnerHtml = true;

                contentUnformatted = "svg,script";

                extraLiners = "div,p,head,body,html";
              };
            };
          };
        };
      };

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
        catppuccin-icons = true;
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

      languages = {
        JavaScript = {
          tab_size = 2;
          code_actions_on_format = {
            "source.fixAll.biome" = true;
          };

          formatter = {
            language_server = {
              name = "biome";
            };
          };
        };
        TypeScript = {
          tab_size = 2;
          code_actions_on_format = {
            "source.fixAll.biome" = true;
          };

          formatter = {
            language_server = {
              name = "biome";
            };
          };

          inlay_hints = {
            enabled = true;
            show_parameter_hints = false;
            show_other_hints = true;
            show_type_hints = true;
          };
        };
        TSX = {
          tab_size = 2;
          code_actions_on_format = {
            "source.fixAll.biome" = true;
          };

          formatter = {
            language_server = {
              name = "biome";
            };
          };
        };
        CSS = {
          tab_size = 2;
          code_actions_on_format = {
            "source.fixAll.biome" = true;
          };

          formatter = {
            language_server = {
              name = "biome";
            };
          };
        };

        HTML = {
          tab_size = 2;

          formatter = {
            language_server = {
              name = "biome";
            };
          };
          format_on_save = "on";
        };
        JSON = {
          tab_size = 2;
          code_actions_on_format = {
            "source.fixAll.biome" = true;
          };

          formatter = {
            language_server = {
              name = "biome";
            };
          };
        };
        JSONC = {
          tab_size = 2;
          code_actions_on_format = {
            "source.fixAll.biome" = true;
          };

          formatter = {
            language_server = {
              name = "biome";
            };
          };
        };
        Markdown = {
          format_on_save = "on";

          remove_trailing_whitespace_on_save = false;
        };
        Nix = {
          tab_size = 2;

          language_servers = [ "nixd" ];
          format_on_save = "on";
        };
        Python = {
          tab_size = 4;

          format_on_save = "on";
          formatter = {
            language_server = {
              name = "ruff";
            };
          };

          language_servers = [
            "pyright"
            "ruff"
          ];
          code_actions_on_format = {
            "source.organizeImports" = true;
            "source.fixAll.ruff" = true;
          };
        };
      };
    };

    themes = {

    };
  };
}
