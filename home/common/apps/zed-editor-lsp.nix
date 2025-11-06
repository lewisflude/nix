_: {
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
}
