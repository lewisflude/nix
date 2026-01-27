{
  lib,
  pkgs,
  ...
}:
let
  standards = import ../features/development/language-standards.nix;

  # Helper to get a representative filename for a language (used by Biome to infer file type)
  # Biome uses the filename extension to determine the file type when formatting via stdin
  getLanguageFilename =
    name: value:
    let
      # Use the first file type as the extension, with a fallback to the name itself
      extension = if (value ? fileTypes && builtins.length value.fileTypes > 0)
                  then builtins.head value.fileTypes
                  else name;
      # Fallback map for language names that don't match their file extensions
      extensionMap = {
        javascript = "js";
        typescript = "ts";
        jsx = "jsx";
        tsx = "tsx";
      };
    in
    "file.${extensionMap.${name} or extension}";

  # Helper to build formatter configuration
  # Biome requires special handling with --stdin-file-path argument
  buildFormatter =
    name: value:
    let
      isBiome = value.formatter == "biome";
      baseArgs = lib.optionals isBiome [
        "format"
        "--stdin-file-path"
        (getLanguageFilename name value)
      ];
      extraArgs = value.formatterArgs or [ ];
    in
    {
      command = value.formatter;
      args = baseArgs ++ extraArgs;
    };

  # Helper to build language server list
  # For languages using Biome, add Biome LSP alongside the primary LSP
  buildLanguageServers =
    _name: value:
    if value.formatter == "biome" then
      [
        # Primary LSP for language features (type checking, completion, etc.)
        value.lsp
        # Biome LSP for linting and additional diagnostics
        "biome"
      ]
    else
      [ value.lsp ];

  # Map command names to Nix packages
  lspPackages = [
    pkgs.nixd
    pkgs.nodePackages.typescript-language-server
    pkgs.vscode-langservers-extracted
    # graphql-language-server - Not available in nixpkgs
    # GraphQL LSP support disabled until a suitable package is found or added
    pkgs.yaml-language-server
    pkgs.taplo
    pkgs.gopls
    pkgs.rust-analyzer
    pkgs.pyright
    pkgs.llvmPackages.clang-unwrapped # Includes clangd
  ];

  formatterPackages = [
    pkgs.nixfmt # RFC 166 style formatter (was nixfmt-rfc-style)
    pkgs.biome
    pkgs.yamlfmt
    pkgs.gotools # Includes goimports
    pkgs.clang-tools # Includes clang-format
    pkgs.black # Python formatter
    pkgs.rustfmt # Rust formatter
    pkgs.ripgrep # Essential for Helix file picker speed
    pkgs.fd # Essential for Helix global search
  ];
in
{
  programs.helix = {
    enable = true;
    extraPackages = lspPackages ++ formatterPackages;
    languages = {
      language = lib.mapAttrsToList (
        name: value:
        (
          {
            inherit name;
            scope = "source.${name}";
            injection-regex = name;
            file-types = value.fileTypes or [ name ];
            language-servers = buildLanguageServers name value;
            indent = {
              tab-width = value.indent;
              # Generate unit from indent value if not explicitly provided
              unit = value.unit or (lib.concatStrings (lib.replicate value.indent " "));
            };
            auto-format = value.formatter != null;
          }
          // lib.optionalAttrs (value ? comment) {
            comment-tokens = [ value.comment ];
          }
          // lib.optionalAttrs (value.formatter != null) {
            formatter = buildFormatter name value;
          }
        )
      ) standards.languages;

      # Configure Biome as a language server
      # Biome LSP provides linting and diagnostics for JS/TS/CSS/GraphQL
      language-server = {
        biome = {
          command = "biome";
          args = [ "lsp-proxy" ];
        };
      };
    };

    settings = {
      editor = {
        line-number = "relative";
        cursorline = true;
        bufferline = "multiple";
        true-color = true;
        undercurl = true;
        color-modes = true;
        scrolloff = 8;
        rulers = [
          80
          120
        ];
        completion-trigger-len = 1;
        idle-timeout = 50; # Increased slightly to prevent UI stutter
        middle-click-paste = true;
        end-of-line-diagnostics = "hint";
        soft-wrap.enable = true;
      };

      editor.cursor-shape = {
        insert = "bar";
        normal = "block";
        select = "underline";
      };

      editor.indent-guides = {
        render = true;
        character = "╎";
      };

      editor.inline-diagnostics = {
        cursor-line = "error";
        other-lines = "disable";
      };

      editor.lsp = {
        display-messages = true;
        display-inlay-hints = true;
        auto-signature-help = false;
      };

      editor.statusline = {
        left = [
          "mode"
          "spinner"
          "file-name"
          "file-modification-indicator"
        ];
        center = [ ];
        right = [
          "diagnostics"
          "selections"
          "position"
          "file-encoding"
          "file-type"
        ];
        mode = {
          normal = "NORMAL";
          insert = "INSERT";
          select = "SELECT";
        };
      };

      editor.whitespace = {
        render = {
          space = "none";
          tab = "all";
          newline = "none";
        };
        characters = {
          tab = "→";
          tabpad = " ";
        };
      };

      editor.file-picker = {
        hidden = false;
        parents = true;
        ignore = true;
        git-ignore = true;
      };

      keys.normal = {
        space = {
          space = "file_picker";
          w = ":w";
          q = ":q";
        };
        "A-," = "goto_previous_buffer";
        "A-." = "goto_next_buffer";
        "A-w" = ":buffer-close";
        "A-/" = "repeat_last_motion";
        "C-," = ":config-open";
        esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
      };

      keys.insert = {
        j = {
          k = "normal_mode";
        };
      };
    };
  };

  # Create runtime directory to fix health check warnings
  home.file.".config/helix/runtime/.keep" = {
    text = "";
  };
}